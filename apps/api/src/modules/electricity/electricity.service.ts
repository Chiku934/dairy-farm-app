import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ConflictException,
} from '@nestjs/common';
import { DataSource } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import { CreateElectricityReadingDto } from './dto/create-electricity-reading.dto';
import { ElectricityQueryDto } from './dto/electricity-query.dto';
import { ElectricityReadingEntity } from './entities/electricity-reading.entity';
import { AuditService } from '../audit/audit.service';
import { AuthenticatedUser } from '../../common/decorators/current-user.decorator';

@Injectable()
export class ElectricityService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly auditService: AuditService,
  ) {}

  async createReading(dto: CreateElectricityReadingDto, user: AuthenticatedUser) {
    // 1. Prevent duplicate readings on the same date and department
    const existing = await this.dataSource
      .getRepository(ElectricityReadingEntity)
      .findOne({
        where: { record_date: dto.recordDate, department: dto.department },
      });

    if (existing) {
      throw new ConflictException(
        `Electricity reading already logged for department ${dto.department} on ${dto.recordDate}. Duplicate meter records are rejected.`,
      );
    }

    // 2. Compute kWh units and enforce meter monotonicity
    let unitsKwh: number;
    if (dto.openingReadingKwh !== undefined && dto.closingReadingKwh !== undefined) {
      if (dto.closingReadingKwh < dto.openingReadingKwh) {
        throw new BadRequestException(
          `Closing reading (${dto.closingReadingKwh}) cannot be lower than opening reading (${dto.openingReadingKwh}). Impossible meter rollback.`,
        );
      }
      unitsKwh = Math.round((dto.closingReadingKwh - dto.openingReadingKwh) * 100) / 100;
    } else if (dto.unitsKwh !== undefined) {
      unitsKwh = Math.round(dto.unitsKwh * 100) / 100;
    } else {
      throw new BadRequestException(
        `Either direct unitsKwh or both openingReadingKwh and closingReadingKwh must be provided.`,
      );
    }

    // 3. Resolve Tariff rate
    let tariffRate: number;
    if (dto.tariffRate !== undefined && dto.tariffRate !== null) {
      tariffRate = Number(dto.tariffRate);
    } else {
      const [settings] = await this.dataSource.query(
        `SELECT electricity_tariff FROM farm_settings LIMIT 1`,
      );
      tariffRate = settings && settings.electricity_tariff ? parseFloat(settings.electricity_tariff) : 1.40;
    }

    const totalCost = Math.round(unitsKwh * tariffRate * 100) / 100;
    const id = uuidv4();

    // 4. Save reading
    const reading = this.dataSource.getRepository(ElectricityReadingEntity).create({
      id,
      record_date: dto.recordDate,
      department: dto.department,
      opening_reading_kwh: dto.openingReadingKwh ?? null,
      closing_reading_kwh: dto.closingReadingKwh ?? null,
      units_kwh: unitsKwh,
      tariff_rate: tariffRate,
      total_cost: totalCost,
      notes: dto.notes ?? null,
      created_by: user.userId,
    });

    const saved = await this.dataSource.getRepository(ElectricityReadingEntity).save(reading);

    // 5. Audit Log
    await this.auditService.logAction({
      userId: user.userId,
      action: 'CREATE_ELECTRICITY_READING',
      entityType: 'UTILITIES',
      entityId: id,
      newValues: {
        department: dto.department,
        unitsKwh,
        tariffRate,
        totalCost,
        opening: dto.openingReadingKwh,
        closing: dto.closingReadingKwh,
      },
    });

    return saved;
  }

  async findAll(query: ElectricityQueryDto) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const skip = (page - 1) * limit;

    const qb = this.dataSource
      .getRepository(ElectricityReadingEntity)
      .createQueryBuilder('er')
      .orderBy('er.record_date', 'DESC')
      .addOrderBy('er.created_at', 'DESC');

    if (query.department) {
      qb.andWhere('er.department = :department', { department: query.department });
    }

    if (query.startDate) {
      qb.andWhere('er.record_date >= :startDate', { startDate: query.startDate });
    }

    if (query.endDate) {
      qb.andWhere('er.record_date <= :endDate', { endDate: query.endDate });
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
    const reading = await this.dataSource
      .getRepository(ElectricityReadingEntity)
      .findOne({ where: { id } });

    if (!reading) {
      throw new NotFoundException(`Electricity reading with ID ${id} not found.`);
    }

    return reading;
  }
}
