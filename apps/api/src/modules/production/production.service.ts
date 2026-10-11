import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ConflictException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import {
  ProductionBatch,
  ProductType,
  QualityReleaseStatus,
  BatchStatus,
} from './entities/production-batch.entity';
import { ProductionBatchIntake } from './entities/production-batch-intake.entity';
import { BmcIntakeLog, Decision } from '../bmc/entities/bmc-intake-log.entity';
import { StockItemEntity } from '../feed/entities/stock-item.entity';
import { CreateProductionBatchDto } from './dto/create-production-batch.dto';
import { UpdateBatchStatusDto } from './dto/update-batch-status.dto';
import { ProductionQueryDto } from './dto/production-query.dto';
import { AuthenticatedUser } from '../../common/decorators/current-user.decorator';

@Injectable()
export class ProductionService {
  constructor(
    @InjectRepository(ProductionBatch)
    private readonly batchRepo: Repository<ProductionBatch>,
    @InjectRepository(ProductionBatchIntake)
    private readonly batchIntakeRepo: Repository<ProductionBatchIntake>,
    @InjectRepository(BmcIntakeLog)
    private readonly bmcIntakeRepo: Repository<BmcIntakeLog>,
    @InjectRepository(StockItemEntity)
    private readonly stockItemRepo: Repository<StockItemEntity>,
    private readonly dataSource: DataSource,
  ) {}

  private readonly YIELD_MAX_CAPS: Record<ProductType, number> = {
    [ProductType.PANEER]: 25.0, // Max 25% yield
    [ProductType.KHOYA]: 28.0,  // Max 28% yield
    [ProductType.GHEE]: 9.0,    // Max 9% yield
    [ProductType.DAHI]: 100.0,  // Max 100% yield
    [ProductType.BUTTER]: 11.0, // Max 11% yield
    [ProductType.MILK]: 102.0,  // Max 102% yield (packaging tolerance)
    [ProductType.BIOGAS_FERTILISER]: 500.0,
  };

  async createBatch(
    dto: CreateProductionBatchDto,
    currentUser?: AuthenticatedUser,
  ): Promise<ProductionBatch> {
    // 1. Yield Validation based on Approved Formulas (docs/FORMULAS.md Section 4.3)
    const yieldPercentage = Number(
      ((dto.finishedQuantity / dto.bmcMilkConsumedL) * 100).toFixed(2),
    );
    const maxCap = this.YIELD_MAX_CAPS[dto.productType] || 100.0;
    if (yieldPercentage > maxCap) {
      throw new BadRequestException(
        `Invalid yield for ${dto.productType}: Output of ${dto.finishedQuantity} from ${dto.bmcMilkConsumedL} L milk results in ${yieldPercentage}% yield, which exceeds maximum realistic threshold of ${maxCap}%.`,
      );
    }

    // 2. Validate Live BMC Balance
    const bmcBalance = await this.getLiveBmcBalance();
    if (dto.bmcMilkConsumedL > bmcBalance) {
      throw new BadRequestException(
        `Insufficient BMC milk balance. Available: ${bmcBalance.toFixed(2)} L, requested: ${dto.bmcMilkConsumedL.toFixed(2)} L.`,
      );
    }

    // 3. Validate LPG Stock if LPG was used
    let lpgItem: StockItemEntity | null = null;
    if (dto.lpgUsedKg && dto.lpgUsedKg > 0) {
      if (dto.lpgStockItemId) {
        lpgItem = await this.stockItemRepo.findOne({
          where: { id: dto.lpgStockItemId },
        });
      } else {
        lpgItem = await this.stockItemRepo.findOne({
          where: { category: 'LPG' as any },
        });
      }

      if (lpgItem && Number(lpgItem.current_stock) < dto.lpgUsedKg) {
        throw new BadRequestException(
          `Insufficient LPG stock. Available: ${Number(lpgItem.current_stock).toFixed(2)} kg, requested: ${dto.lpgUsedKg.toFixed(2)} kg.`,
        );
      }
    }

    // 4. Generate Unique Batch Number
    const typeCode = dto.productType.substring(0, 3);
    const cleanDate = dto.recordDate.replace(/-/g, '');
    const randomSuffix = Math.floor(100 + Math.random() * 900);
    const batchNumber = `BATCH-${typeCode}-${cleanDate}-${randomSuffix}`;

    // 5. Execute in atomic transaction
    return await this.dataSource.transaction(async (manager) => {
      // Create and save batch
      const batch = manager.create(ProductionBatch, {
        ...dto,
        batchNumber,
        yieldPercentage,
        lpgStockItemId: lpgItem ? lpgItem.id : dto.lpgStockItemId,
        operatorId: currentUser?.userId,
        operatorName: dto.operatorName || currentUser?.fullName || 'Authorized Operator',
      });

      const savedBatch = await manager.save(ProductionBatch, batch);

      // Handle linked intakes
      if (dto.linkedIntakes && dto.linkedIntakes.length > 0) {
        for (const link of dto.linkedIntakes) {
          const intake = await manager.findOne(BmcIntakeLog, {
            where: { id: link.intakeId },
          });
          if (!intake) {
            throw new BadRequestException(`Linked intake lot '${link.intakeId}' not found.`);
          }
          if (intake.decision !== Decision.ACCEPTED) {
            throw new BadRequestException(`Cannot link rejected intake lot '${intake.batchNumber}' to production.`);
          }

          const batchIntake = manager.create(ProductionBatchIntake, {
            productionBatchId: savedBatch.id,
            intakeId: link.intakeId,
            litresUsed: link.litresUsed,
          });
          await manager.save(ProductionBatchIntake, batchIntake);
        }
      } else {
        // Auto-link to latest accepted intakes matching consumed volume
        const acceptedIntakes = await manager.find(BmcIntakeLog, {
          where: { decision: Decision.ACCEPTED },
          order: { recordDate: 'DESC', createdAt: 'DESC' },
          take: 3,
        });

        let remainingToLink = dto.bmcMilkConsumedL;
        for (const intake of acceptedIntakes) {
          if (remainingToLink <= 0) break;
          const litresToAssign = Math.min(remainingToLink, Number(intake.quantityLitres));
          const batchIntake = manager.create(ProductionBatchIntake, {
            productionBatchId: savedBatch.id,
            intakeId: intake.id,
            litresUsed: litresToAssign,
          });
          await manager.save(ProductionBatchIntake, batchIntake);
          remainingToLink -= litresToAssign;
        }
      }

      // Deduct LPG stock if used
      if (lpgItem && dto.lpgUsedKg && dto.lpgUsedKg > 0) {
        await manager.decrement(
          StockItemEntity,
          { id: lpgItem.id },
          'current_stock',
          dto.lpgUsedKg,
        );
      }

      return savedBatch;
    });
  }

  async findAllBatches(query: ProductionQueryDto) {
    const qb = this.batchRepo.createQueryBuilder('batch')
      .leftJoinAndSelect('batch.intakeLinks', 'intakeLinks')
      .leftJoinAndSelect('intakeLinks.intake', 'intake');

    if (query.date) {
      qb.andWhere('batch.record_date = :date', { date: query.date });
    }
    if (query.startDate) {
      qb.andWhere('batch.record_date >= :startDate', { startDate: query.startDate });
    }
    if (query.endDate) {
      qb.andWhere('batch.record_date <= :endDate', { endDate: query.endDate });
    }
    if (query.productType) {
      qb.andWhere('batch.product_type = :productType', { productType: query.productType });
    }
    if (query.qualityRelease) {
      qb.andWhere('batch.quality_release = :qualityRelease', { qualityRelease: query.qualityRelease });
    }
    if (query.status) {
      qb.andWhere('batch.status = :status', { status: query.status });
    }
    if (query.shift) {
      qb.andWhere('batch.shift = :shift', { shift: query.shift });
    }
    if (query.search) {
      qb.andWhere(
        '(batch.batch_number LIKE :search OR batch.operator_name LIKE :search OR batch.notes LIKE :search)',
        { search: `%${query.search}%` },
      );
    }

    qb.orderBy('batch.record_date', 'DESC')
      .addOrderBy('batch.created_at', 'DESC');

    const page = query.page || 1;
    const limit = query.limit || 20;
    const skip = (page - 1) * limit;

    const [items, total] = await qb.skip(skip).take(limit).getManyAndCount();

    return {
      items,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit) || 1,
    };
  }

  async findOneBatch(id: string): Promise<ProductionBatch> {
    const batch = await this.batchRepo.findOne({
      where: { id },
      relations: ['intakeLinks', 'intakeLinks.intake', 'lpgStockItem'],
    });

    if (!batch) {
      throw new NotFoundException(`Production batch with ID '${id}' not found.`);
    }

    return batch;
  }

  async updateReleaseStatus(
    id: string,
    dto: UpdateBatchStatusDto,
  ): Promise<ProductionBatch> {
    const batch = await this.findOneBatch(id);

    if (dto.qualityRelease) {
      batch.qualityRelease = dto.qualityRelease;
    }
    if (dto.status) {
      batch.status = dto.status;
    }
    if (dto.notes) {
      batch.notes = batch.notes ? `${batch.notes} | ${dto.notes}` : dto.notes;
    }

    return await this.batchRepo.save(batch);
  }

  async getTraceability(id: string) {
    const batch = await this.findOneBatch(id);

    const contributingIntakes = (batch.intakeLinks || []).map((link) => {
      const intake = link.intake;
      return {
        intakeId: intake.id,
        intakeBatchNumber: intake.batchNumber,
        recordDate: intake.recordDate,
        shift: intake.shift,
        source: intake.source,
        supplierRoute: intake.supplierRoute,
        totalIntakeLitres: Number(intake.quantityLitres),
        litresUsedInBatch: Number(link.litresUsed),
        decision: intake.decision,
        qualityMetrics: {
          fatPercentage: intake.fatPercentage,
          snfPercentage: intake.snfPercentage,
          temperatureC: intake.temperatureC,
          clr: intake.clr,
          ph: intake.ph,
        },
        intakeOperator: intake.operatorName,
      };
    });

    return {
      batchId: batch.id,
      batchNumber: batch.batchNumber,
      recordDate: batch.recordDate,
      shift: batch.shift,
      productType: batch.productType,
      status: batch.status,
      qualityRelease: batch.qualityRelease,
      expiryDate: batch.expiryDate,
      bmcMilkConsumedL: Number(batch.bmcMilkConsumedL),
      finishedQuantity: Number(batch.finishedQuantity),
      unitOfMeasure: batch.unitOfMeasure,
      yieldPercentage: Number(batch.yieldPercentage || 0),
      lpgUsedKg: Number(batch.lpgUsedKg),
      byproductQuantityKg: Number(batch.byproductQuantityKg),
      processOperator: batch.operatorName,
      notes: batch.notes,
      createdAt: batch.createdAt,
      lineage: {
        totalIntakeLotsContributing: contributingIntakes.length,
        intakeLots: contributingIntakes,
      },
    };
  }

  private async getLiveBmcBalance(): Promise<number> {
    const intakeRaw = await this.dataSource.query(
      `SELECT COALESCE(SUM(quantity_litres), 0) AS accepted_litres
       FROM bmc_intake_logs
       WHERE decision = 'ACCEPTED'`,
    );
    const prodRaw = await this.dataSource.query(
      `SELECT COALESCE(SUM(bmc_milk_consumed_l), 0) AS consumed_litres
       FROM production_batches
       WHERE status != 'CANCELLED'`,
    );
    const wasteRaw = await this.dataSource.query(
      `SELECT COALESCE(SUM(quantity_lost), 0) AS lost_litres
       FROM wastage_records
       WHERE stock_type = 'BMC'`,
    );

    const accepted = Number(intakeRaw[0]?.accepted_litres || 0);
    const consumed = Number(prodRaw[0]?.consumed_litres || 0);
    const lost = Number(wasteRaw[0]?.lost_litres || 0);

    return Math.max(0, accepted - consumed - lost);
  }
}
