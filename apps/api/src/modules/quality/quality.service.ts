import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { DataSource } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import { CreateQualityRecordDto } from './dto/create-quality-record.dto';
import { QualityQueryDto } from './dto/quality-query.dto';
import { QualityRecordEntity } from './entities/quality-record.entity';
import { QualityTargetType, QualityDecision } from '@dairy-farm/api-contracts';
import { AuditService } from '../audit/audit.service';
import { AuthenticatedUser } from '../../common/decorators/current-user.decorator';

@Injectable()
export class QualityService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly auditService: AuditService,
  ) {}

  async createRecord(dto: CreateQualityRecordDto, user: AuthenticatedUser) {
    // 1. Validate physical reading boundaries
    if (dto.fatPercentage !== undefined && (dto.fatPercentage < 0 || dto.fatPercentage > 100)) {
      throw new BadRequestException(`Fat percentage must be between 0.0 and 100.0%. Received: ${dto.fatPercentage}`);
    }
    if (dto.snfPercentage !== undefined && (dto.snfPercentage < 0 || dto.snfPercentage > 100)) {
      throw new BadRequestException(`SNF percentage must be between 0.0 and 100.0%. Received: ${dto.snfPercentage}`);
    }
    if (dto.clr !== undefined && (dto.clr < 10 || dto.clr > 45)) {
      throw new BadRequestException(`CLR reading must be between 10.0 and 45.0. Received: ${dto.clr}`);
    }
    if (dto.ph !== undefined && (dto.ph < 0 || dto.ph > 14)) {
      throw new BadRequestException(`pH value must be between 0.00 and 14.00. Received: ${dto.ph}`);
    }
    if (dto.temperatureC !== undefined && (dto.temperatureC < -10 || dto.temperatureC > 100)) {
      throw new BadRequestException(`Temperature must be between -10.0 and 100.0 °C. Received: ${dto.temperatureC}`);
    }

    // 2. Validate Target entity existence
    if (dto.targetType === QualityTargetType.PRODUCTION_BATCH) {
      const [rows] = await this.dataSource.query(
        `SELECT id, batch_number FROM production_batches WHERE id = ?`,
        [dto.targetId],
      );
      if (!rows || rows.length === 0) {
        throw new NotFoundException(`Production batch with ID ${dto.targetId} not found.`);
      }
    } else if (dto.targetType === QualityTargetType.INTAKE) {
      const [rows] = await this.dataSource.query(
        `SELECT id FROM bmc_intake_logs WHERE id = ?`,
        [dto.targetId],
      );
      if (!rows || rows.length === 0) {
        throw new NotFoundException(`Milk intake log with ID ${dto.targetId} not found.`);
      }
    }

    const id = uuidv4();
    const record = this.dataSource.getRepository(QualityRecordEntity).create({
      id,
      record_date: dto.recordDate,
      target_type: dto.targetType,
      target_id: dto.targetId,
      fat_percentage: dto.fatPercentage ?? null,
      snf_percentage: dto.snfPercentage ?? null,
      clr: dto.clr ?? null,
      ph: dto.ph ?? null,
      temperature_c: dto.temperatureC ?? null,
      decision: dto.decision,
      tested_by: dto.testedBy ?? user.email,
      notes: dto.notes ?? null,
    });

    const saved = await this.dataSource.getRepository(QualityRecordEntity).save(record);

    // Audit log
    await this.auditService.logAction({
      userId: user.userId,
      action: 'CREATE_QUALITY_RECORD',
      entityType: 'QUALITY',
      entityId: id,
      newValues: {
        targetType: dto.targetType,
        targetId: dto.targetId,
        decision: dto.decision,
        fat: dto.fatPercentage,
        snf: dto.snfPercentage,
        clr: dto.clr,
        ph: dto.ph,
      },
    });

    return saved;
  }

  async findAll(query: QualityQueryDto) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const skip = (page - 1) * limit;

    const qb = this.dataSource
      .getRepository(QualityRecordEntity)
      .createQueryBuilder('qr')
      .orderBy('qr.record_date', 'DESC')
      .addOrderBy('qr.created_at', 'DESC');

    if (query.targetType) {
      qb.andWhere('qr.target_type = :targetType', { targetType: query.targetType });
    }

    if (query.targetId) {
      qb.andWhere('qr.target_id = :targetId', { targetId: query.targetId });
    }

    if (query.decision) {
      qb.andWhere('qr.decision = :decision', { decision: query.decision });
    }

    if (query.startDate) {
      qb.andWhere('qr.record_date >= :startDate', { startDate: query.startDate });
    }

    if (query.endDate) {
      qb.andWhere('qr.record_date <= :endDate', { endDate: query.endDate });
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
    const record = await this.dataSource
      .getRepository(QualityRecordEntity)
      .findOne({ where: { id } });

    if (!record) {
      throw new NotFoundException(`Quality record with ID ${id} not found.`);
    }

    return record;
  }

  async findByTarget(targetType: QualityTargetType, targetId: string) {
    return this.dataSource
      .getRepository(QualityRecordEntity)
      .find({
        where: { target_type: targetType, target_id: targetId },
        order: { record_date: 'DESC', created_at: 'DESC' },
      });
  }
}
