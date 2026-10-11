import {
  Injectable,
  NotFoundException,
  ConflictException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import { MilkingLogEntity, MilkingSession, MilkDisposition } from './entities/milking-log.entity';
import { CreateMilkingLogDto } from './dto/create-milking-log.dto';
import { UpdateMilkingLogDto } from './dto/update-milking-log.dto';
import { MilkingQueryDto } from './dto/milking-query.dto';
import { paginateQuery } from '../../common/pagination/paginate.util';
import { PaginatedResult } from '../../common/pagination/pagination.dto';
import { AuditService } from '../audit/audit.service';
import { AnimalEntity } from '../herd/entities/animal.entity';
import { HealthRecordEntity } from '../animal-health/entities/health-record.entity';
import { UserEntity } from '../users/entities/user.entity';

export interface MilkingSummaryStats {
  totalLitres: number;
  eligibleLitres: number;
  withheldLitres: number;
  calfFeedingLitres: number;
  morningLitres: number;
  eveningLitres: number;
  activeCowsMilked: number;
  avgLitresPerCow: number;
}

@Injectable()
export class MilkingService {
  constructor(
    @InjectRepository(MilkingLogEntity)
    private readonly milkingRepo: Repository<MilkingLogEntity>,
    @InjectRepository(AnimalEntity)
    private readonly animalRepo: Repository<AnimalEntity>,
    @InjectRepository(HealthRecordEntity)
    private readonly healthRepo: Repository<HealthRecordEntity>,
    @InjectRepository(UserEntity)
    private readonly userRepo: Repository<UserEntity>,
    private readonly dataSource: DataSource,
    private readonly auditService: AuditService,
  ) {}

  async create(dto: CreateMilkingLogDto, currentUserId?: string): Promise<MilkingLogEntity> {
    if (!dto.animalId && !dto.groupName) {
      throw new BadRequestException('Either animalId or groupName must be specified.');
    }

    let animalTag = '';
    // 1. Verify animal if animalId is provided
    if (dto.animalId) {
      const animal = await this.animalRepo.findOne({ where: { id: dto.animalId } });
      if (!animal) {
        throw new NotFoundException(`Animal with ID "${dto.animalId}" does not exist.`);
      }
      animalTag = animal.earTag;

      // 2. Enforce duplicate check for same animal, date, and shift
      const existing = await this.milkingRepo.findOne({
        where: {
          animal_id: dto.animalId,
          record_date: dto.recordDate,
          session: dto.session,
        },
      });

      if (existing) {
        throw new ConflictException(
          `Milking record already exists for animal ${animalTag} on ${dto.recordDate} (${dto.session} shift). Please update the existing entry to modify yield.`,
        );
      }

      // 3. Enforce active withdrawal check from health records
      const activeWithdrawal = await this.healthRepo
        .createQueryBuilder('health')
        .where('health.animal_id = :animalId', { animalId: dto.animalId })
        .andWhere('health.withdrawal_until >= :recordDate', { recordDate: dto.recordDate })
        .orderBy('health.withdrawal_until', 'DESC')
        .getOne();

      if (activeWithdrawal && activeWithdrawal.withdrawalUntil) {
        // Enforce WITHHELD disposition
        dto.disposition = MilkDisposition.WITHHELD;
        const autoReason = `Active safety withdrawal period until ${activeWithdrawal.withdrawalUntil}`;
        dto.withheldReason = dto.withheldReason ? `${autoReason} (${dto.withheldReason})` : autoReason;
      }
    } else if (dto.groupName) {
      // Duplicate check for group milking
      const existing = await this.milkingRepo.findOne({
        where: {
          group_name: dto.groupName,
          record_date: dto.recordDate,
          session: dto.session,
        },
      });

      if (existing) {
        throw new ConflictException(
          `Milking record already exists for group "${dto.groupName}" on ${dto.recordDate} (${dto.session} shift).`,
        );
      }
    }

    // 4. Resolve Operator name
    let operatorName = dto.operatorName;
    const operatorId = dto.operatorId || currentUserId;
    if (operatorId && !operatorName) {
      const opUser = await this.userRepo.findOne({ where: { id: operatorId } });
      if (opUser) {
        operatorName = opUser.fullName;
      }
    }

    const log = this.milkingRepo.create({
      id: uuidv4(),
      animal_id: dto.animalId || null,
      group_name: dto.groupName || null,
      record_date: dto.recordDate,
      session: dto.session,
      yield_litres: dto.yieldLitres,
      disposition: dto.disposition || MilkDisposition.ELIGIBLE,
      withheld_reason: dto.withheldReason || null,
      operator_id: operatorId || null,
      operator_name: operatorName || null,
      notes: dto.notes || null,
    });

    const saved = await this.milkingRepo.save(log);

    await this.auditService.logAction({
      userId: currentUserId || 'system',
      action: 'MILKING_LOG_RECORDED',
      entityType: 'milking_logs',
      entityId: saved.id,
      newValues: {
        animalId: saved.animal_id,
        groupName: saved.group_name,
        date: saved.record_date,
        session: saved.session,
        yieldLitres: saved.yield_litres,
        disposition: saved.disposition,
      },
    });

    return (await this.findById(saved.id))!;
  }

  async findAll(query: MilkingQueryDto): Promise<PaginatedResult<MilkingLogEntity>> {
    const qb = this.milkingRepo
      .createQueryBuilder('milking')
      .leftJoinAndSelect('milking.animal', 'animal');

    if (query.date) {
      qb.andWhere('milking.record_date = :date', { date: query.date });
    }
    if (query.startDate) {
      qb.andWhere('milking.record_date >= :startDate', { startDate: query.startDate });
    }
    if (query.endDate) {
      qb.andWhere('milking.record_date <= :endDate', { endDate: query.endDate });
    }
    if (query.session) {
      qb.andWhere('milking.session = :session', { session: query.session });
    }
    if (query.animalId) {
      qb.andWhere('milking.animal_id = :animalId', { animalId: query.animalId });
    }
    if (query.groupName) {
      qb.andWhere('milking.group_name = :groupName', { groupName: query.groupName });
    }
    if (query.disposition) {
      qb.andWhere('milking.disposition = :disposition', { disposition: query.disposition });
    }
    if (query.search) {
      const term = `%${query.search}%`;
      qb.andWhere(
        '(animal.ear_tag LIKE :term OR milking.group_name LIKE :term OR milking.operator_name LIKE :term OR milking.notes LIKE :term)',
        { term },
      );
    }

    const sortColumn = query.sortBy || 'record_date';
    const sortDirection = query.sortOrder || 'DESC';

    if (sortColumn === 'record_date') {
      qb.orderBy('milking.record_date', sortDirection).addOrderBy('milking.session', 'ASC');
    } else {
      qb.orderBy(`milking.${sortColumn}`, sortDirection);
    }

    return paginateQuery(qb, query);
  }

  async findById(id: string): Promise<MilkingLogEntity> {
    const log = await this.milkingRepo
      .createQueryBuilder('milking')
      .leftJoinAndSelect('milking.animal', 'animal')
      .where('milking.id = :id', { id })
      .getOne();

    if (!log) {
      throw new NotFoundException(`Milking log with ID "${id}" was not found.`);
    }

    return log;
  }

  async update(id: string, dto: UpdateMilkingLogDto, currentUserId?: string): Promise<MilkingLogEntity> {
    const existing = await this.findById(id);

    // If session or date or animal is changed, enforce duplicate check
    const newAnimalId = dto.animalId !== undefined ? dto.animalId : existing.animal_id;
    const newDate = dto.recordDate || existing.record_date;
    const newSession = dto.session || existing.session;

    if (
      newAnimalId &&
      (newAnimalId !== existing.animal_id || newDate !== existing.record_date || newSession !== existing.session)
    ) {
      const conflict = await this.milkingRepo.findOne({
        where: {
          animal_id: newAnimalId,
          record_date: newDate,
          session: newSession,
        },
      });
      if (conflict && conflict.id !== id) {
        throw new ConflictException(
          `Milking record already exists for animal on ${newDate} (${newSession} shift).`,
        );
      }
    }

    // Enforce withdrawal check if updated date or animal
    if (newAnimalId) {
      const activeWithdrawal = await this.healthRepo
        .createQueryBuilder('health')
        .where('health.animal_id = :animalId', { animalId: newAnimalId })
        .andWhere('health.withdrawal_until >= :recordDate', { recordDate: newDate })
        .orderBy('health.withdrawal_until', 'DESC')
        .getOne();

      if (activeWithdrawal && activeWithdrawal.withdrawalUntil) {
        dto.disposition = MilkDisposition.WITHHELD;
        dto.withheldReason = `Active safety withdrawal period until ${activeWithdrawal.withdrawalUntil}`;
      }
    }

    Object.assign(existing, {
      ...(dto.animalId !== undefined ? { animal_id: dto.animalId || null } : {}),
      ...(dto.groupName !== undefined ? { group_name: dto.groupName || null } : {}),
      ...(dto.recordDate ? { record_date: dto.recordDate } : {}),
      ...(dto.session ? { session: dto.session } : {}),
      ...(dto.yieldLitres !== undefined ? { yield_litres: dto.yieldLitres } : {}),
      ...(dto.disposition ? { disposition: dto.disposition } : {}),
      ...(dto.withheldReason !== undefined ? { withheld_reason: dto.withheldReason } : {}),
      ...(dto.operatorId !== undefined ? { operator_id: dto.operatorId } : {}),
      ...(dto.operatorName !== undefined ? { operator_name: dto.operatorName } : {}),
      ...(dto.notes !== undefined ? { notes: dto.notes } : {}),
    });

    const updated = await this.milkingRepo.save(existing);

    await this.auditService.logAction({
      userId: currentUserId || 'system',
      action: 'MILKING_LOG_UPDATED',
      entityType: 'milking_logs',
      entityId: id,
      newValues: { yieldLitres: updated.yield_litres, disposition: updated.disposition },
    });

    return updated;
  }

  async remove(id: string, currentUserId?: string): Promise<void> {
    const existing = await this.findById(id);

    await this.milkingRepo.remove(existing);

    await this.auditService.logAction({
      userId: currentUserId || 'system',
      action: 'MILKING_LOG_DELETED',
      entityType: 'milking_logs',
      entityId: id,
      oldValues: { yieldLitres: existing.yield_litres, date: existing.record_date },
    });
  }

  async getSummary(startDate?: string, endDate?: string): Promise<MilkingSummaryStats> {
    const qb = this.milkingRepo.createQueryBuilder('m');

    if (startDate) {
      qb.andWhere('m.record_date >= :startDate', { startDate });
    }
    if (endDate) {
      qb.andWhere('m.record_date <= :endDate', { endDate });
    }

    const rows = await qb
      .select([
        'COALESCE(SUM(m.yield_litres), 0) as totalLitres',
        "COALESCE(SUM(CASE WHEN m.disposition = 'ELIGIBLE' THEN m.yield_litres ELSE 0 END), 0) as eligibleLitres",
        "COALESCE(SUM(CASE WHEN m.disposition = 'WITHHELD' THEN m.yield_litres ELSE 0 END), 0) as withheldLitres",
        "COALESCE(SUM(CASE WHEN m.disposition = 'CALF_FEEDING' THEN m.yield_litres ELSE 0 END), 0) as calfFeedingLitres",
        "COALESCE(SUM(CASE WHEN m.session = 'MORNING' THEN m.yield_litres ELSE 0 END), 0) as morningLitres",
        "COALESCE(SUM(CASE WHEN m.session = 'EVENING' THEN m.yield_litres ELSE 0 END), 0) as eveningLitres",
        'COUNT(DISTINCT m.animal_id) as activeCowsMilked',
      ])
      .getRawOne();

    const totalLitres = parseFloat(rows?.totalLitres || '0');
    const eligibleLitres = parseFloat(rows?.eligibleLitres || '0');
    const withheldLitres = parseFloat(rows?.withheldLitres || '0');
    const calfFeedingLitres = parseFloat(rows?.calfFeedingLitres || '0');
    const morningLitres = parseFloat(rows?.morningLitres || '0');
    const eveningLitres = parseFloat(rows?.eveningLitres || '0');
    const activeCowsMilked = parseInt(rows?.activeCowsMilked || '0', 10);
    const avgLitresPerCow =
      activeCowsMilked > 0 ? parseFloat((totalLitres / activeCowsMilked).toFixed(2)) : 0;

    return {
      totalLitres,
      eligibleLitres,
      withheldLitres,
      calfFeedingLitres,
      morningLitres,
      eveningLitres,
      activeCowsMilked,
      avgLitresPerCow,
    };
  }
}
