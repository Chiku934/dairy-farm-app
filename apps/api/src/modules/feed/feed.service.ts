import {
  Injectable,
  NotFoundException,
  ConflictException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import { FeedEntryEntity } from './entities/feed-entry.entity';
import { StockItemEntity } from './entities/stock-item.entity';
import {
  RationDefinitionEntity,
  TargetAnimalStage,
} from './entities/ration-definition.entity';
import { RationItemEntity } from './entities/ration-item.entity';
import { CreateFeedEntryDto } from './dto/create-feed-entry.dto';
import { CreateRationDto } from './dto/create-ration.dto';
import { UpdateRationDto } from './dto/update-ration.dto';
import { FeedQueryDto } from './dto/feed-query.dto';
import { paginateQuery } from '../../common/pagination/paginate.util';
import { PaginatedResult } from '../../common/pagination/pagination.dto';
import { AuditService } from '../audit/audit.service';
import { AnimalEntity } from '../herd/entities/animal.entity';
import { MilkingLogEntity } from '../milking/entities/milking-log.entity';

export interface ConcentrateTargetResult {
  animalId: string;
  earTag: string;
  breed: string;
  status: string;
  feedBaseKg: number;
  feedRatePerLitre: number;
  feedMaxCapKg: number;
  daysEvaluated: number;
  avgDailyYieldLitres: number;
  targetConcentrateKg: number;
  calculationMethod: string;
}

@Injectable()
export class FeedService {
  constructor(
    @InjectRepository(FeedEntryEntity)
    private readonly feedEntryRepo: Repository<FeedEntryEntity>,
    @InjectRepository(StockItemEntity)
    private readonly stockItemRepo: Repository<StockItemEntity>,
    @InjectRepository(RationDefinitionEntity)
    private readonly rationRepo: Repository<RationDefinitionEntity>,
    @InjectRepository(RationItemEntity)
    private readonly rationItemRepo: Repository<RationItemEntity>,
    @InjectRepository(AnimalEntity)
    private readonly animalRepo: Repository<AnimalEntity>,
    @InjectRepository(MilkingLogEntity)
    private readonly milkingRepo: Repository<MilkingLogEntity>,
    private readonly dataSource: DataSource,
    private readonly auditService: AuditService,
  ) {}

  async recordFeedConsumption(
    dto: CreateFeedEntryDto,
    currentUserId?: string,
  ): Promise<FeedEntryEntity> {
    if (!dto.animalId && !dto.groupName) {
      throw new BadRequestException('Either animalId or groupName must be specified.');
    }

    let animalTag = '';
    if (dto.animalId) {
      const animal = await this.animalRepo.findOne({ where: { id: dto.animalId } });
      if (!animal) {
        throw new NotFoundException(`Animal with ID "${dto.animalId}" does not exist.`);
      }
      animalTag = animal.earTag;
    }

    const stockItem = await this.stockItemRepo.findOne({
      where: { id: dto.stockItemId },
    });
    if (!stockItem) {
      throw new NotFoundException(`Feed inventory item "${dto.stockItemId}" does not exist.`);
    }

    const unitCost = Number(stockItem.weighted_avg_price || 0);
    const totalCost = parseFloat((unitCost * dto.quantityKg).toFixed(2));

    // Deduct stock in transaction
    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    let savedEntry: FeedEntryEntity;
    try {
      stockItem.current_stock = parseFloat(
        Math.max(0, Number(stockItem.current_stock) - dto.quantityKg).toFixed(2),
      );
      await queryRunner.manager.save(StockItemEntity, stockItem);

      const entry = this.feedEntryRepo.create({
        id: uuidv4(),
        animal_id: dto.animalId || null,
        group_name: dto.groupName || null,
        ration_id: dto.rationId || null,
        record_date: dto.recordDate,
        stock_item_id: dto.stockItemId,
        quantity_kg: dto.quantityKg,
        unit_cost: unitCost,
        total_cost: totalCost,
        shift: dto.shift,
        feed_type: dto.feedType,
        notes: dto.notes || null,
        created_by: currentUserId || null,
      });

      savedEntry = await queryRunner.manager.save(FeedEntryEntity, entry);
      await queryRunner.commitTransaction();
    } catch (err) {
      await queryRunner.rollbackTransaction();
      throw err;
    } finally {
      await queryRunner.release();
    }

    await this.auditService.logAction({
      userId: currentUserId || 'system',
      action: 'FEED_CONSUMPTION_LOGGED',
      entityType: 'feed_entries',
      entityId: savedEntry.id,
      newValues: {
        animalId: savedEntry.animal_id,
        groupName: savedEntry.group_name,
        stockItemId: savedEntry.stock_item_id,
        quantityKg: savedEntry.quantity_kg,
        totalCost: savedEntry.total_cost,
      },
    });

    return (await this.feedEntryRepo
      .createQueryBuilder('f')
      .leftJoinAndSelect('f.animal', 'animal')
      .leftJoinAndSelect('f.stock_item', 'stockItem')
      .leftJoinAndSelect('f.ration', 'ration')
      .where('f.id = :id', { id: savedEntry.id })
      .getOne())!;
  }

  async findAllFeedEntries(query: FeedQueryDto): Promise<PaginatedResult<FeedEntryEntity>> {
    const qb = this.feedEntryRepo
      .createQueryBuilder('f')
      .leftJoinAndSelect('f.animal', 'animal')
      .leftJoinAndSelect('f.stock_item', 'stockItem')
      .leftJoinAndSelect('f.ration', 'ration');

    if (query.date) {
      qb.andWhere('f.record_date = :date', { date: query.date });
    }
    if (query.startDate) {
      qb.andWhere('f.record_date >= :startDate', { startDate: query.startDate });
    }
    if (query.endDate) {
      qb.andWhere('f.record_date <= :endDate', { endDate: query.endDate });
    }
    if (query.animalId) {
      qb.andWhere('f.animal_id = :animalId', { animalId: query.animalId });
    }
    if (query.groupName) {
      qb.andWhere('f.group_name = :groupName', { groupName: query.groupName });
    }
    if (query.feedType) {
      qb.andWhere('f.feed_type = :feedType', { feedType: query.feedType });
    }
    if (query.stockItemId) {
      qb.andWhere('f.stock_item_id = :stockItemId', { stockItemId: query.stockItemId });
    }
    if (query.rationId) {
      qb.andWhere('f.ration_id = :rationId', { rationId: query.rationId });
    }
    if (query.search) {
      const term = `%${query.search}%`;
      qb.andWhere(
        '(animal.ear_tag LIKE :term OR f.group_name LIKE :term OR stockItem.name LIKE :term OR f.notes LIKE :term)',
        { term },
      );
    }

    const sortColumn = query.sortBy || 'record_date';
    const sortDirection = query.sortOrder || 'DESC';
    qb.orderBy(`f.${sortColumn}`, sortDirection);

    return paginateQuery(qb, query);
  }

  async calculateConcentrateTarget(animalId: string): Promise<ConcentrateTargetResult> {
    const animal = await this.animalRepo.findOne({ where: { id: animalId } });
    if (!animal) {
      throw new NotFoundException(`Animal with ID "${animalId}" does not exist.`);
    }

    // 1. Fetch formula constants from farm_settings
    const settings = await this.dataSource.query('SELECT feed_base_kg, feed_rate_per_litre, feed_max_cap_kg FROM farm_settings WHERE id = 1 LIMIT 1');
    const baseKg = settings.length > 0 ? parseFloat(settings[0].feed_base_kg) : 1.0;
    const ratePerLitre = settings.length > 0 ? parseFloat(settings[0].feed_rate_per_litre) : 0.4;
    const maxCapKg = settings.length > 0 ? parseFloat(settings[0].feed_max_cap_kg) : 8.0;

    // 2. Fetch daily yields from last 7 days of milking
    const yieldRows = await this.dataSource.query(
      `SELECT record_date, SUM(yield_litres) as daily_yield
       FROM milking_logs
       WHERE animal_id = ?
         AND record_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
       GROUP BY record_date`,
      [animalId],
    );

    const daysCount = yieldRows.length;
    let avgDailyYield = 0;
    let targetKg = baseKg;
    let calculationMethod = 'FRESH_COW_BASE_ALLOWANCE';

    if (daysCount >= 3) {
      const totalYield = yieldRows.reduce(
        (sum: number, row: any) => sum + parseFloat(row.daily_yield || '0'),
        0,
      );
      avgDailyYield = parseFloat((totalYield / daysCount).toFixed(2));
      const calculated = baseKg + avgDailyYield * ratePerLitre;
      targetKg = parseFloat(Math.min(calculated, maxCapKg).toFixed(2));
      calculationMethod = '7_DAY_MILK_PRODUCTION_FORMULA';
    } else if (daysCount > 0) {
      // If 1 or 2 days recorded, take simple average of recorded days with note
      const totalYield = yieldRows.reduce(
        (sum: number, row: any) => sum + parseFloat(row.daily_yield || '0'),
        0,
      );
      avgDailyYield = parseFloat((totalYield / daysCount).toFixed(2));
      const calculated = baseKg + avgDailyYield * ratePerLitre;
      targetKg = parseFloat(Math.min(calculated, maxCapKg).toFixed(2));
      calculationMethod = 'PROVISIONAL_PARTIAL_HISTORY';
    }

    return {
      animalId: animal.id,
      earTag: animal.earTag,
      breed: animal.breed,
      status: animal.status,
      feedBaseKg: baseKg,
      feedRatePerLitre: ratePerLitre,
      feedMaxCapKg: maxCapKg,
      daysEvaluated: daysCount,
      avgDailyYieldLitres: avgDailyYield,
      targetConcentrateKg: targetKg,
      calculationMethod,
    };
  }

  async findAllRations(): Promise<RationDefinitionEntity[]> {
    const rations = await this.rationRepo
      .createQueryBuilder('r')
      .leftJoinAndSelect('r.items', 'item')
      .leftJoinAndSelect('item.stock_item', 'stockItem')
      .orderBy('r.name', 'ASC')
      .getMany();

    return rations.map((ration) => this.computeRationMetrics(ration));
  }

  async findRationById(id: string): Promise<RationDefinitionEntity> {
    const ration = await this.rationRepo
      .createQueryBuilder('r')
      .leftJoinAndSelect('r.items', 'item')
      .leftJoinAndSelect('item.stock_item', 'stockItem')
      .where('r.id = :id', { id })
      .getOne();

    if (!ration) {
      throw new NotFoundException(`Ration definition "${id}" was not found.`);
    }

    return this.computeRationMetrics(ration);
  }

  async createRation(dto: CreateRationDto, currentUserId?: string): Promise<RationDefinitionEntity> {
    const existing = await this.rationRepo.findOne({ where: { code: dto.code } });
    if (existing) {
      throw new ConflictException(`Ration with code "${dto.code}" already exists.`);
    }

    const ration = this.rationRepo.create({
      id: uuidv4(),
      name: dto.name,
      code: dto.code,
      target_stage: dto.targetStage || TargetAnimalStage.LACTATING,
      description: dto.description || null,
      is_active: true,
      created_by: currentUserId || null,
    });

    const savedRation = await this.rationRepo.save(ration);

    if (dto.items && dto.items.length > 0) {
      const itemsToSave = dto.items.map((item) =>
        this.rationItemRepo.create({
          id: uuidv4(),
          ration_id: savedRation.id,
          stock_item_id: item.stockItemId,
          quantity_kg: item.quantityKg,
          notes: item.notes || null,
        }),
      );
      await this.rationItemRepo.save(itemsToSave);
    }

    await this.auditService.logAction({
      userId: currentUserId || 'system',
      action: 'RATION_DEFINITION_CREATED',
      entityType: 'ration_definitions',
      entityId: savedRation.id,
      newValues: { name: savedRation.name, code: savedRation.code },
    });

    return this.findRationById(savedRation.id);
  }

  async updateRation(
    id: string,
    dto: UpdateRationDto,
    currentUserId?: string,
  ): Promise<RationDefinitionEntity> {
    const existing = await this.findRationById(id);

    if (dto.code && dto.code !== existing.code) {
      const conflict = await this.rationRepo.findOne({ where: { code: dto.code } });
      if (conflict && conflict.id !== id) {
        throw new ConflictException(`Ration code "${dto.code}" is already in use.`);
      }
    }

    Object.assign(existing, {
      ...(dto.name ? { name: dto.name } : {}),
      ...(dto.code ? { code: dto.code } : {}),
      ...(dto.targetStage ? { target_stage: dto.targetStage } : {}),
      ...(dto.description !== undefined ? { description: dto.description } : {}),
    });

    await this.rationRepo.save(existing);

    if (dto.items) {
      await this.rationItemRepo.delete({ ration_id: id });
      const newItems = dto.items.map((item) =>
        this.rationItemRepo.create({
          id: uuidv4(),
          ration_id: id,
          stock_item_id: item.stockItemId,
          quantity_kg: item.quantityKg,
          notes: item.notes || null,
        }),
      );
      await this.rationItemRepo.save(newItems);
    }

    await this.auditService.logAction({
      userId: currentUserId || 'system',
      action: 'RATION_DEFINITION_UPDATED',
      entityType: 'ration_definitions',
      entityId: id,
      newValues: { name: existing.name },
    });

    return this.findRationById(id);
  }

  private computeRationMetrics(ration: RationDefinitionEntity): RationDefinitionEntity {
    let totalQty = 0;
    let totalCost = 0;

    if (ration.items) {
      for (const item of ration.items) {
        const qty = Number(item.quantity_kg || 0);
        const price = Number(item.stock_item?.weighted_avg_price || 0);
        const itemCost = parseFloat((qty * price).toFixed(2));
        item.itemCost = itemCost;
        totalQty += qty;
        totalCost += itemCost;
      }
    }

    ration.totalQuantityKg = parseFloat(totalQty.toFixed(2));
    ration.totalCost = parseFloat(totalCost.toFixed(2));
    ration.unitCostPerKg =
      totalQty > 0 ? parseFloat((totalCost / totalQty).toFixed(2)) : 0.0;

    return ration;
  }
}
