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
  constructor(
    @InjectRepository(UnitOfMeasurementEntity)
    private readonly uomRepo: Repository<UnitOfMeasurementEntity>,
    @InjectRepository(LookupCategoryEntity)
    private readonly categoryRepo: Repository<LookupCategoryEntity>,
    @InjectRepository(LookupValueEntity)
    private readonly valueRepo: Repository<LookupValueEntity>,
    private readonly dataSource: DataSource,
  ) {}

  async getAllUoms(isActiveOnly = true): Promise<UnitOfMeasurementEntity[]> {
    const qb = this.uomRepo.createQueryBuilder('uom');
    if (isActiveOnly) {
      qb.where('uom.isActive = :isActive', { isActive: true });
    }
    return qb.orderBy('uom.dimension', 'ASC').addOrderBy('uom.name', 'ASC').getMany();
  }

  async createUom(dto: CreateUomDto): Promise<UnitOfMeasurementEntity> {
    const existing = await this.uomRepo.findOne({ where: { code: dto.code } });
    if (existing) {
      throw new ConflictException(`UOM with code ${dto.code} already exists`);
    }

    return this.dataSource.transaction(async (manager) => {
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
  }

  async getAllCategories(): Promise<LookupCategoryEntity[]> {
    return this.categoryRepo.find({
      relations: ['values'],
      order: { name: 'ASC' },
    });
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
    return this.categoryRepo.save(category);
  }

  async getValuesByCategory(
    categoryCode: string,
    isActiveOnly = true,
  ): Promise<LookupValueEntity[]> {
    const qb = this.valueRepo
      .createQueryBuilder('val')
      .where('val.categoryCode = :categoryCode', { categoryCode: categoryCode.toUpperCase() });

    if (isActiveOnly) {
      qb.andWhere('val.isActive = :isActive', { isActive: true });
    }

    return qb.orderBy('val.sortOrder', 'ASC').addOrderBy('val.label', 'ASC').getMany();
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

    return this.dataSource.transaction(async (manager) => {
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
  }
}
