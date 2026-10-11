import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { DataSource } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import { CreateMaterialIssueDto } from './dto/create-material-issue.dto';
import { MaterialQueryDto } from './dto/material-query.dto';
import { MaterialIssueEntity } from './entities/material-issue.entity';
import { StockItemEntity } from '../feed/entities/stock-item.entity';
import { ProductionBatchEntity } from '../production/entities/production-batch.entity';
import { AuditService } from '../audit/audit.service';
import { AuthenticatedUser } from '../../common/decorators/current-user.decorator';

@Injectable()
export class MaterialsService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly auditService: AuditService,
  ) {}

  async createIssue(dto: CreateMaterialIssueDto, user: AuthenticatedUser) {
    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      // 1. Lock Stock Item
      const stockItem = await queryRunner.manager
        .createQueryBuilder(StockItemEntity, 'item')
        .setLock('pessimistic_write')
        .where('item.id = :id', { id: dto.stockItemId })
        .getOne();

      if (!stockItem) {
        throw new NotFoundException(`Stock item with ID ${dto.stockItemId} not found.`);
      }

      const requestedQty = Math.round(Number(dto.quantity) * 100) / 100;
      if (Number(stockItem.current_stock) < requestedQty) {
        throw new BadRequestException(
          `Insufficient stock for "${stockItem.name}". Available: ${stockItem.current_stock} ${stockItem.unit}, Requested: ${requestedQty} ${stockItem.unit}.`,
        );
      }

      // 2. Validate batch if provided
      let batchNumber: string | null = null;
      if (dto.productionBatchId) {
        const batch = await queryRunner.manager.findOne(ProductionBatchEntity, {
          where: { id: dto.productionBatchId },
        });
        if (!batch) {
          throw new NotFoundException(`Production batch with ID ${dto.productionBatchId} not found.`);
        }
        batchNumber = batch.batchNumber;
      }

      // 3. Atomically decrement inventory
      const newStock = Math.round((Number(stockItem.current_stock) - requestedQty) * 100) / 100;
      await queryRunner.manager.update(StockItemEntity, stockItem.id, {
        current_stock: newStock,
      });

      const issueId = uuidv4();
      const unitCost = Number(stockItem.weighted_avg_price);
      const totalCost = Math.round(requestedQty * unitCost * 100) / 100;

      // 4. Insert Stock Ledger Entry
      const ledgerId = uuidv4();
      await queryRunner.manager.query(
        `INSERT INTO stock_ledger_entries (id, stock_item_id, record_date, transaction_type, reference_id, quantity_change, balance_after, unit_cost, notes, created_at)
         VALUES (?, ?, ?, 'ISSUE', ?, ?, ?, ?, ?, NOW())`,
        [
          ledgerId,
          stockItem.id,
          dto.recordDate,
          issueId,
          -requestedQty,
          newStock,
          unitCost,
          `Issued to ${dto.department} ${batchNumber ? `(Batch ${batchNumber})` : ''} - ${dto.issuedTo || 'general'}`,
        ],
      );

      // 5. Insert Material Issue
      const issue = queryRunner.manager.create(MaterialIssueEntity, {
        id: issueId,
        record_date: dto.recordDate,
        department: dto.department,
        stock_item_id: dto.stockItemId,
        quantity: requestedQty,
        unit_cost: unitCost,
        total_cost: totalCost,
        production_batch_id: dto.productionBatchId ?? null,
        issued_to: dto.issuedTo ?? null,
        notes: dto.notes ?? null,
        created_by: user.userId,
      });

      await queryRunner.manager.save(MaterialIssueEntity, issue);

      // 6. Audit Log
      await this.auditService.logAction({
        userId: user.userId,
        action: 'CREATE_MATERIAL_ISSUE',
        entityType: 'INVENTORY',
        entityId: issueId,
        newValues: {
          department: dto.department,
          stockItemId: dto.stockItemId,
          quantity: requestedQty,
          totalCost,
          batchId: dto.productionBatchId,
          issuedTo: dto.issuedTo,
        },
      });

      await queryRunner.commitTransaction();

      return this.findOne(issueId);
    } catch (err) {
      await queryRunner.rollbackTransaction();
      throw err;
    } finally {
      await queryRunner.release();
    }
  }

  async findAll(query: MaterialQueryDto) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const skip = (page - 1) * limit;

    const qb = this.dataSource
      .getRepository(MaterialIssueEntity)
      .createQueryBuilder('mi')
      .leftJoinAndSelect('mi.stock_item', 'stock_item')
      .leftJoinAndSelect('mi.production_batch', 'batch')
      .orderBy('mi.record_date', 'DESC')
      .addOrderBy('mi.created_at', 'DESC');

    if (query.department) {
      qb.andWhere('mi.department = :department', { department: query.department });
    }

    if (query.stockItemId) {
      qb.andWhere('mi.stock_item_id = :stockItemId', { stockItemId: query.stockItemId });
    }

    if (query.batchId) {
      qb.andWhere('mi.production_batch_id = :batchId', { batchId: query.batchId });
    }

    if (query.startDate) {
      qb.andWhere('mi.record_date >= :startDate', { startDate: query.startDate });
    }

    if (query.endDate) {
      qb.andWhere('mi.record_date <= :endDate', { endDate: query.endDate });
    }

    const [items, total] = await qb.skip(skip).take(limit).getManyAndCount();

    return {
      items,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async findOne(id: string) {
    const issue = await this.dataSource
      .getRepository(MaterialIssueEntity)
      .createQueryBuilder('mi')
      .leftJoinAndSelect('mi.stock_item', 'stock_item')
      .leftJoinAndSelect('mi.production_batch', 'batch')
      .where('mi.id = :id', { id })
      .getOne();

    if (!issue) {
      throw new NotFoundException(`Material issue with ID ${id} not found.`);
    }

    return issue;
  }
}
