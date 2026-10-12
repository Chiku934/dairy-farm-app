import {
  Injectable,
  NotFoundException,
  ConflictException,
  BadRequestException,
} from '@nestjs/common';
import { DataSource } from 'typeorm';
import { randomUUID } from 'crypto';
import { BiogasRunEntity } from './entities/biogas-run.entity';
import { CreateBiogasRunDto } from './dto/create-biogas-run.dto';
import { BiogasQueryDto } from './dto/biogas-query.dto';
import { StockItemEntity } from '../feed/entities/stock-item.entity';
import { StockLedgerEntryEntity } from '../inventory/entities/stock-ledger-entry.entity';
import { AuditLogEntity } from '../audit/entities/audit-log.entity';
import { BiogasUsageType, StockTransactionType } from '@dairy-farm/api-contracts';

@Injectable()
export class BiogasService {
  constructor(private readonly dataSource: DataSource) {}

  async createRun(dto: CreateBiogasRunDto, userId?: string): Promise<BiogasRunEntity> {
    const totalBagWeight =
      (dto.bagsPacked1kg || 0) * 1 +
      (dto.bagsPacked5kg || 0) * 5 +
      (dto.bagsPacked25kg || 0) * 25 +
      (dto.bagsPacked50kg || 0) * 50;

    if (totalBagWeight > dto.dryFertiliserOutputKg) {
      throw new BadRequestException(
        `Total packaged bag weight (${totalBagWeight} kg) cannot exceed dry fertiliser output (${dto.dryFertiliserOutputKg} kg)`,
      );
    }

    const runNumber = dto.runNumber?.trim() || `BIO-${Date.now().toString().slice(-6)}`;

    return await this.dataSource.transaction(async (manager) => {
      // Check duplicate runNumber
      const existing = await manager.findOne(BiogasRunEntity, {
        where: { run_number: runNumber },
      });
      if (existing) {
        throw new ConflictException(`Biogas run number ${runNumber} already exists`);
      }

      const runId = randomUUID();
      const run = manager.create(BiogasRunEntity, {
        id: runId,
        run_number: runNumber,
        record_date: dto.recordDate,
        slurry_input_kg: dto.slurryInputKg,
        dry_fertiliser_output_kg: dto.dryFertiliserOutputKg,
        moisture_pct: dto.moisturePct ?? null,
        stock_item_id: dto.stockItemId ?? null,
        bags_packed_1kg: dto.bagsPacked1kg ?? 0,
        bags_packed_5kg: dto.bagsPacked5kg ?? 0,
        bags_packed_25kg: dto.bagsPacked25kg ?? 0,
        bags_packed_50kg: dto.bagsPacked50kg ?? 0,
        usage_type: dto.usageType ?? BiogasUsageType.STORE_STOCK,
        usage_quantity_kg: dto.usageQuantityKg ?? 0,
        sale_amount: dto.saleAmount ?? 0,
        buyer_or_farm_plot: dto.buyerOrFarmPlot?.trim() || null,
        notes: dto.notes?.trim() || null,
        created_by: userId || null,
      });

      const savedRun = await manager.save(BiogasRunEntity, run);

      // If stockItemId is provided and destination is STORE_STOCK, credit inventory
      if (dto.stockItemId && (dto.usageType ?? BiogasUsageType.STORE_STOCK) === BiogasUsageType.STORE_STOCK) {
        const stockItem = await manager
          .createQueryBuilder(StockItemEntity, 'item')
          .setLock('pessimistic_write')
          .where('item.id = :id', { id: dto.stockItemId })
          .getOne();

        if (stockItem) {
          const currentBal = Number(stockItem.current_stock);
          const newBal = currentBal + dto.dryFertiliserOutputKg;

          stockItem.current_stock = newBal;
          await manager.save(StockItemEntity, stockItem);

          const ledgerEntry = manager.create(StockLedgerEntryEntity, {
            id: randomUUID(),
            stockItemId: stockItem.id,
            recordDate: dto.recordDate,
            transactionType: StockTransactionType.RECEIPT,
            referenceId: runNumber,
            quantityChange: dto.dryFertiliserOutputKg,
            balanceAfter: newBal,
            unitCost: Number(stockItem.weighted_avg_price) || 0,
            notes: `Biogas production yield from run ${runNumber}`,
          });
          await manager.save(StockLedgerEntryEntity, ledgerEntry);
        }
      }

      // Audit Log
      const auditLog = manager.create(AuditLogEntity, {
        id: randomUUID(),
        entityType: 'biogas_runs',
        entityId: runId,
        action: 'BIOGAS_RUN_CREATED',
        newValues: {
          runNumber,
          slurryInputKg: dto.slurryInputKg,
          dryFertiliserOutputKg: dto.dryFertiliserOutputKg,
          usageType: dto.usageType,
        },
        userId: userId || 'system',
      });
      await manager.save(AuditLogEntity, auditLog);

      return savedRun;
    });
  }

  async findAll(query: BiogasQueryDto) {
    const page = query.page || 1;
    const limit = query.limit || 20;
    const skip = (page - 1) * limit;

    const qb = this.dataSource
      .getRepository(BiogasRunEntity)
      .createQueryBuilder('run')
      .leftJoinAndSelect('run.stock_item', 'stock_item')
      .orderBy('run.record_date', 'DESC')
      .addOrderBy('run.created_at', 'DESC');

    if (query.startDate) {
      qb.andWhere('run.record_date >= :startDate', { startDate: query.startDate });
    }
    if (query.endDate) {
      qb.andWhere('run.record_date <= :endDate', { endDate: query.endDate });
    }
    if (query.usageType) {
      qb.andWhere('run.usage_type = :usageType', { usageType: query.usageType });
    }

    const [items, total] = await qb.skip(skip).take(limit).getManyAndCount();

    // Summary aggregates
    const summaryRaw = await this.dataSource
      .getRepository(BiogasRunEntity)
      .createQueryBuilder('run')
      .select('SUM(run.slurry_input_kg)', 'totalSlurry')
      .addSelect('SUM(run.dry_fertiliser_output_kg)', 'totalOutput')
      .addSelect('SUM(run.sale_amount)', 'totalSales')
      .getRawOne();

    const totalSlurry = parseFloat(summaryRaw?.totalSlurry || '0');
    const totalOutput = parseFloat(summaryRaw?.totalOutput || '0');
    const totalSales = parseFloat(summaryRaw?.totalSales || '0');
    const avgYieldPct = totalSlurry > 0 ? (totalOutput / totalSlurry) * 100 : 0;

    return {
      items,
      total,
      page,
      totalPages: Math.ceil(total / limit) || 1,
      summary: {
        totalSlurryKg: totalSlurry,
        totalOutputKg: totalOutput,
        avgYieldPct: Math.round(avgYieldPct * 10) / 10,
        totalDirectSales: totalSales,
      },
    };
  }

  async findOne(id: string): Promise<BiogasRunEntity> {
    const run = await this.dataSource
      .getRepository(BiogasRunEntity)
      .createQueryBuilder('run')
      .leftJoinAndSelect('run.stock_item', 'stock_item')
      .where('run.id = :id', { id })
      .getOne();

    if (!run) {
      throw new NotFoundException(`Biogas run with ID ${id} not found`);
    }
    return run;
  }
}
