import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { DataSource } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import { CreatePackagingRunDto } from './dto/create-packaging-run.dto';
import { PackagingQueryDto } from './dto/packaging-query.dto';
import { PackagingRunEntity } from './entities/packaging-run.entity';
import { ProductionBatchEntity } from '../production/entities/production-batch.entity';
import { StockItemEntity } from '../feed/entities/stock-item.entity';
import { AuditService } from '../audit/audit.service';
import { AuthenticatedUser } from '../../common/decorators/current-user.decorator';
import { BatchStatus } from '@dairy-farm/api-contracts';

@Injectable()
export class PackagingService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly auditService: AuditService,
  ) {}

  async createRun(dto: CreatePackagingRunDto, user: AuthenticatedUser) {
    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      // 1. Verify Production Batch exists and is not CANCELLED
      const batch = await queryRunner.manager.findOne(ProductionBatchEntity, {
        where: { id: dto.productionBatchId },
      });

      if (!batch) {
        throw new NotFoundException(`Production batch with ID ${dto.productionBatchId} not found.`);
      }

      if (batch.status === BatchStatus.CANCELLED) {
        throw new BadRequestException(`Cannot package cancelled production batch ${batch.batchNumber}.`);
      }

      // 2. Validate batch available unpackaged volume/weight
      const existingRuns = await queryRunner.manager.find(PackagingRunEntity, {
        where: { production_batch_id: dto.productionBatchId },
      });

      const alreadyPackaged = existingRuns.reduce(
        (sum, r) => sum + Number(r.total_packaged_quantity),
        0,
      );

      const runPackagedQuantity = Math.round(Number(dto.packSize) * Number(dto.numberOfPacks) * 100) / 100;
      const totalAfterThisRun = Math.round((alreadyPackaged + runPackagedQuantity) * 100) / 100;
      const maxBatchOutput = Number(batch.finishedQuantity);

      if (totalAfterThisRun > maxBatchOutput) {
        const remainingUnpackaged = Math.max(0, Math.round((maxBatchOutput - alreadyPackaged) * 100) / 100);
        throw new BadRequestException(
          `Requested packaging quantity (${runPackagedQuantity} ${dto.packUnit}) exceeds remaining unpackaged batch output (${remainingUnpackaged} ${batch.unitOfMeasure}). Total batch output: ${maxBatchOutput}.`,
        );
      }

      // 3. Verify Packaging Stock Item with row lock
      const stockItem = await queryRunner.manager
        .createQueryBuilder(StockItemEntity, 'item')
        .setLock('pessimistic_write')
        .where('item.id = :id', { id: dto.packagingItemId })
        .getOne();

      if (!stockItem) {
        throw new NotFoundException(`Packaging stock item with ID ${dto.packagingItemId} not found.`);
      }

      const scrapUnits = dto.scrapUnits ?? 0;
      const materialConsumed = dto.materialConsumed ?? (Number(dto.numberOfPacks) + scrapUnits);

      if (Number(stockItem.current_stock) < materialConsumed) {
        throw new BadRequestException(
          `Insufficient packaging material stock for "${stockItem.name}". Available: ${stockItem.current_stock} ${stockItem.unit}, Required: ${materialConsumed} ${stockItem.unit}.`,
        );
      }

      // 4. Atomically deduct packaging stock
      const newStock = Math.round((Number(stockItem.current_stock) - materialConsumed) * 100) / 100;
      await queryRunner.manager.update(StockItemEntity, stockItem.id, {
        current_stock: newStock,
      });

      const runId = uuidv4();

      // 5. Insert Stock Ledger Entry for packaging consumption
      const ledgerId = uuidv4();
      await queryRunner.manager.query(
        `INSERT INTO stock_ledger_entries (id, stock_item_id, record_date, transaction_type, reference_id, quantity_change, balance_after, unit_cost, notes, created_at)
         VALUES (?, ?, ?, 'PACKAGING_CONSUMPTION', ?, ?, ?, ?, ?, NOW())`,
        [
          ledgerId,
          stockItem.id,
          dto.recordDate,
          runId,
          -materialConsumed,
          newStock,
          stockItem.weighted_avg_price,
          `Packaged ${dto.numberOfPacks} packs (${dto.packSize} ${dto.packUnit}) for Batch ${batch.batchNumber}`,
        ],
      );

      // 6. Insert Packaging Run
      const run = queryRunner.manager.create(PackagingRunEntity, {
        id: runId,
        record_date: dto.recordDate,
        production_batch_id: dto.productionBatchId,
        pack_size: dto.packSize,
        pack_unit: dto.packUnit,
        number_of_packs: dto.numberOfPacks,
        total_packaged_quantity: runPackagedQuantity,
        packaging_item_id: dto.packagingItemId,
        material_consumed: materialConsumed,
        scrap_units: scrapUnits,
        notes: dto.notes ?? null,
        created_by: user.userId,
      });

      await queryRunner.manager.save(PackagingRunEntity, run);

      // 7. Audit log
      await this.auditService.logAction({
        userId: user.userId,
        action: 'CREATE_PACKAGING_RUN',
        entityType: 'PACKAGING',
        entityId: runId,
        newValues: {
          batchId: dto.productionBatchId,
          batchNumber: batch.batchNumber,
          numberOfPacks: dto.numberOfPacks,
          packSize: dto.packSize,
          totalPackaged: runPackagedQuantity,
          materialConsumed,
        },
      });

      await queryRunner.commitTransaction();

      return this.findOne(runId);
    } catch (err) {
      await queryRunner.rollbackTransaction();
      throw err;
    } finally {
      await queryRunner.release();
    }
  }

  async findAll(query: PackagingQueryDto) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const skip = (page - 1) * limit;

    const qb = this.dataSource
      .getRepository(PackagingRunEntity)
      .createQueryBuilder('run')
      .leftJoinAndSelect('run.production_batch', 'batch')
      .leftJoinAndSelect('run.packaging_item', 'pkg_item')
      .orderBy('run.record_date', 'DESC')
      .addOrderBy('run.created_at', 'DESC');

    if (query.batchId) {
      qb.andWhere('run.production_batch_id = :batchId', { batchId: query.batchId });
    }

    if (query.startDate) {
      qb.andWhere('run.record_date >= :startDate', { startDate: query.startDate });
    }

    if (query.endDate) {
      qb.andWhere('run.record_date <= :endDate', { endDate: query.endDate });
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
    const run = await this.dataSource
      .getRepository(PackagingRunEntity)
      .createQueryBuilder('run')
      .leftJoinAndSelect('run.production_batch', 'batch')
      .leftJoinAndSelect('run.packaging_item', 'pkg_item')
      .where('run.id = :id', { id })
      .getOne();

    if (!run) {
      throw new NotFoundException(`Packaging run with ID ${id} not found.`);
    }

    return run;
  }

  async findByBatch(batchId: string) {
    return this.dataSource
      .getRepository(PackagingRunEntity)
      .find({
        where: { production_batch_id: batchId },
        relations: ['packaging_item'],
        order: { record_date: 'DESC' },
      });
  }
}
