import {
  Injectable,
  NotFoundException,
  ConflictException,
  BadRequestException,
} from '@nestjs/common';
import { DataSource } from 'typeorm';
import { randomUUID } from 'crypto';
import { WastageRecordEntity } from './entities/wastage-record.entity';
import { CreateWastageDto } from './dto/create-wastage.dto';
import { WastageQueryDto } from './dto/wastage-query.dto';
import { StockItemEntity } from '../feed/entities/stock-item.entity';
import { StockLedgerEntryEntity } from '../inventory/entities/stock-ledger-entry.entity';
import { AuditLogEntity } from '../audit/entities/audit-log.entity';
import { StockType, StockTransactionType } from '@dairy-farm/api-contracts';

@Injectable()
export class WastageService {
  constructor(private readonly dataSource: DataSource) {}

  async recordWastage(dto: CreateWastageDto, userId?: string): Promise<WastageRecordEntity> {
    const wastageNumber = dto.wastageNumber?.trim() || `WST-${Date.now().toString().slice(-6)}`;

    return await this.dataSource.transaction(async (manager) => {
      // Check duplicate wastageNumber
      const existing = await manager.findOne(WastageRecordEntity, {
        where: { wastage_number: wastageNumber },
      });
      if (existing) {
        throw new ConflictException(`Wastage record number ${wastageNumber} already exists`);
      }

      let estimatedCost = dto.estimatedLossCost ?? 0.0;

      // Handle SUPPLY wastage affecting shared stock ledger
      if (dto.stockType === StockType.SUPPLY && dto.stockItemId) {
        const stockItem = await manager
          .createQueryBuilder(StockItemEntity, 'item')
          .setLock('pessimistic_write')
          .where('item.id = :id', { id: dto.stockItemId })
          .getOne();

        if (!stockItem) {
          throw new NotFoundException(`Stock item with ID ${dto.stockItemId} not found`);
        }

        const currentStock = Number(stockItem.current_stock);
        if (currentStock < dto.quantityLost) {
          throw new BadRequestException(
            `INSUFFICIENT_STOCK: Available stock (${currentStock} ${stockItem.unit}) is less than wastage quantity (${dto.quantityLost})`,
          );
        }

        const unitCost = Number(stockItem.weighted_avg_price) || 0.0;
        if (dto.estimatedLossCost === undefined || dto.estimatedLossCost === null) {
          estimatedCost = Math.round(dto.quantityLost * unitCost * 100) / 100;
        }

        const newStock = currentStock - dto.quantityLost;
        stockItem.current_stock = newStock;
        await manager.save(StockItemEntity, stockItem);

        const ledgerEntry = manager.create(StockLedgerEntryEntity, {
          id: randomUUID(),
          stockItemId: stockItem.id,
          recordDate: dto.recordDate,
          transactionType: StockTransactionType.WASTAGE,
          referenceId: wastageNumber,
          quantityChange: -dto.quantityLost,
          balanceAfter: newStock,
          unitCost: unitCost,
          notes: `Wastage write-off (${dto.reason}): ${dto.notes || 'No remarks'}`,
        });
        await manager.save(StockLedgerEntryEntity, ledgerEntry);
      } else if (dto.stockType === StockType.BMC) {
        if (dto.estimatedLossCost === undefined || dto.estimatedLossCost === null) {
          // Standard base milk loss valuation @ ₹32.00 / L
          estimatedCost = Math.round(dto.quantityLost * 32.0 * 100) / 100;
        }
      }

      const wastageId = randomUUID();
      const wastage = manager.create(WastageRecordEntity, {
        id: wastageId,
        wastage_number: wastageNumber,
        record_date: dto.recordDate,
        stock_type: dto.stockType,
        stock_item_id: dto.stockItemId || null,
        production_batch_id: dto.productionBatchId || null,
        reference_id: dto.referenceId.trim(),
        quantity_lost: dto.quantityLost,
        unit: dto.unit.trim().toUpperCase(),
        reason: dto.reason,
        estimated_loss_cost: estimatedCost,
        notes: dto.notes?.trim() || null,
        created_by: userId || null,
      });

      const savedWastage = await manager.save(WastageRecordEntity, wastage);

      // Audit Log
      const auditLog = manager.create(AuditLogEntity, {
        id: randomUUID(),
        entityType: 'wastage_records',
        entityId: wastageId,
        action: 'WASTAGE_RECORDED',
        newValues: {
          wastageNumber,
          stockType: dto.stockType,
          quantityLost: dto.quantityLost,
          reason: dto.reason,
          estimatedCost,
        },
        userId: userId || 'system',
      });
      await manager.save(AuditLogEntity, auditLog);

      return savedWastage;
    });
  }

  async findAll(query: WastageQueryDto) {
    const page = query.page || 1;
    const limit = query.limit || 20;
    const skip = (page - 1) * limit;

    const qb = this.dataSource
      .getRepository(WastageRecordEntity)
      .createQueryBuilder('w')
      .leftJoinAndSelect('w.stock_item', 'stock_item')
      .leftJoinAndSelect('w.production_batch', 'production_batch')
      .orderBy('w.record_date', 'DESC')
      .addOrderBy('w.created_at', 'DESC');

    if (query.startDate) {
      qb.andWhere('w.record_date >= :startDate', { startDate: query.startDate });
    }
    if (query.endDate) {
      qb.andWhere('w.record_date <= :endDate', { endDate: query.endDate });
    }
    if (query.stockType) {
      qb.andWhere('w.stock_type = :stockType', { stockType: query.stockType });
    }
    if (query.reason) {
      qb.andWhere('w.reason = :reason', { reason: query.reason });
    }

    const [items, total] = await qb.skip(skip).take(limit).getManyAndCount();

    // Summary totals
    const summaryRaw = await this.dataSource
      .getRepository(WastageRecordEntity)
      .createQueryBuilder('w')
      .select('SUM(w.estimated_loss_cost)', 'totalCost')
      .addSelect('SUM(w.quantity_lost)', 'totalQty')
      .getRawOne();

    const totalCost = parseFloat(summaryRaw?.totalCost || '0');
    const totalQty = parseFloat(summaryRaw?.totalQty || '0');

    return {
      items,
      total,
      page,
      totalPages: Math.ceil(total / limit) || 1,
      summary: {
        totalLostCost: Math.round(totalCost * 100) / 100,
        totalLostQuantity: Math.round(totalQty * 100) / 100,
      },
    };
  }

  async findOne(id: string): Promise<WastageRecordEntity> {
    const record = await this.dataSource
      .getRepository(WastageRecordEntity)
      .createQueryBuilder('w')
      .leftJoinAndSelect('w.stock_item', 'stock_item')
      .leftJoinAndSelect('w.production_batch', 'production_batch')
      .where('w.id = :id', { id })
      .getOne();

    if (!record) {
      throw new NotFoundException(`Wastage record with ID ${id} not found`);
    }
    return record;
  }
}
