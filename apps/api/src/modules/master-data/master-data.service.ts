import {
  Injectable,
  NotFoundException,
  ConflictException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import { UnitOfMeasurementEntity } from './entities/unit-of-measurement.entity';
import { LookupCategoryEntity } from './entities/lookup-category.entity';
import { LookupValueEntity } from './entities/lookup-value.entity';
import { CreateUomDto } from './dto/create-uom.dto';
import { CreateLookupCategoryDto, CreateLookupValueDto } from './dto/create-lookup.dto';

@Injectable()
export class MasterDataService {
  private cachedUoms: UnitOfMeasurementEntity[] | null = null;
  private uomsExpiresAt: number = 0;
  private cachedCategories: LookupCategoryEntity[] | null = null;
  private categoriesExpiresAt: number = 0;
  private readonly cachedValues = new Map<string, { expiresAt: number; data: LookupValueEntity[] }>();
  private readonly CACHE_TTL_MS = 10 * 60 * 1000; // 10 minutes TTL for master data

  constructor(
    @InjectRepository(UnitOfMeasurementEntity)
    private readonly uomRepo: Repository<UnitOfMeasurementEntity>,
    @InjectRepository(LookupCategoryEntity)
    private readonly categoryRepo: Repository<LookupCategoryEntity>,
    @InjectRepository(LookupValueEntity)
    private readonly valueRepo: Repository<LookupValueEntity>,
    private readonly dataSource: DataSource,
  ) {}

  invalidateUomCache(): void {
    this.cachedUoms = null;
    this.uomsExpiresAt = 0;
  }

  invalidateLookupCache(categoryCode?: string): void {
    this.cachedCategories = null;
    this.categoriesExpiresAt = 0;
    if (categoryCode) {
      this.cachedValues.delete(categoryCode.toUpperCase());
    } else {
      this.cachedValues.clear();
    }
  }

  async getAllUoms(isActiveOnly = true): Promise<UnitOfMeasurementEntity[]> {
    const now = Date.now();
    if (isActiveOnly && this.cachedUoms && now < this.uomsExpiresAt) {
      return this.cachedUoms;
    }

    const qb = this.uomRepo.createQueryBuilder('uom');
    if (isActiveOnly) {
      qb.where('uom.isActive = :isActive', { isActive: true });
    }
    const results = await qb.orderBy('uom.dimension', 'ASC').addOrderBy('uom.name', 'ASC').getMany();

    if (isActiveOnly) {
      this.cachedUoms = results;
      this.uomsExpiresAt = now + this.CACHE_TTL_MS;
    }
    return results;
  }

  async createUom(dto: CreateUomDto): Promise<UnitOfMeasurementEntity> {
    const existing = await this.uomRepo.findOne({ where: { code: dto.code } });
    if (existing) {
      throw new ConflictException(`UOM with code ${dto.code} already exists`);
    }

    const result = await this.dataSource.transaction(async (manager) => {
      const uom = manager.create(UnitOfMeasurementEntity, {
        id: uuidv4(),
        code: dto.code.toUpperCase(),
        name: dto.name,
        dimension: dto.dimension,
        conversionFactor: dto.conversionFactor || 1.0,
        baseUnitCode: dto.baseUnitCode ? dto.baseUnitCode.toUpperCase() : null,
        isActive: true,
      });
      return manager.save(UnitOfMeasurementEntity, uom);
    });

    this.invalidateUomCache();
    return result;
  }

  async getAllCategories(): Promise<LookupCategoryEntity[]> {
    const now = Date.now();
    if (this.cachedCategories && now < this.categoriesExpiresAt) {
      return this.cachedCategories;
    }

    const results = await this.categoryRepo.find({
      relations: ['values'],
      order: { name: 'ASC' },
    });

    this.cachedCategories = results;
    this.categoriesExpiresAt = now + this.CACHE_TTL_MS;
    return results;
  }

  async createCategory(dto: CreateLookupCategoryDto): Promise<LookupCategoryEntity> {
    const existing = await this.categoryRepo.findOne({ where: { code: dto.code } });
    if (existing) {
      throw new ConflictException(`Category with code ${dto.code} already exists`);
    }

    const category = this.categoryRepo.create({
      id: uuidv4(),
      code: dto.code.toUpperCase(),
      name: dto.name,
      description: dto.description || null,
    });
    const saved = await this.categoryRepo.save(category);

    this.invalidateLookupCache();
    return saved;
  }

  async getValuesByCategory(
    categoryCode: string,
    isActiveOnly = true,
  ): Promise<LookupValueEntity[]> {
    const codeKey = categoryCode.toUpperCase();
    const now = Date.now();
    const cached = this.cachedValues.get(codeKey);
    if (isActiveOnly && cached && now < cached.expiresAt) {
      return cached.data;
    }

    const qb = this.valueRepo
      .createQueryBuilder('val')
      .where('val.categoryCode = :categoryCode', { categoryCode: codeKey });

    if (isActiveOnly) {
      qb.andWhere('val.isActive = :isActive', { isActive: true });
    }

    const results = await qb.orderBy('val.sortOrder', 'ASC').addOrderBy('val.label', 'ASC').getMany();

    if (isActiveOnly) {
      this.cachedValues.set(codeKey, { expiresAt: now + this.CACHE_TTL_MS, data: results });
    }
    return results;
  }

  async createLookupValue(dto: CreateLookupValueDto): Promise<LookupValueEntity> {
    const category = await this.categoryRepo.findOne({
      where: { code: dto.categoryCode.toUpperCase() },
    });
    if (!category) {
      throw new NotFoundException(`Lookup category ${dto.categoryCode} does not exist`);
    }

    const existing = await this.valueRepo.findOne({
      where: {
        categoryCode: dto.categoryCode.toUpperCase(),
        code: dto.code.toUpperCase(),
      },
    });
    if (existing) {
      throw new ConflictException(
        `Value code ${dto.code} already exists in category ${dto.categoryCode}`,
      );
    }

    const result = await this.dataSource.transaction(async (manager) => {
      const val = manager.create(LookupValueEntity, {
        id: uuidv4(),
        categoryCode: dto.categoryCode.toUpperCase(),
        code: dto.code.toUpperCase(),
        label: dto.label,
        sortOrder: dto.sortOrder || 0,
        isActive: true,
        metadata: dto.metadata || null,
      });
      return manager.save(LookupValueEntity, val);
    });

    this.invalidateLookupCache(dto.categoryCode);
    return result;
  }
}
