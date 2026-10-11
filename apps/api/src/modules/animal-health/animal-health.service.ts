import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import { HealthRecordEntity, CareType } from './entities/health-record.entity';
import { CreateHealthRecordDto } from './dto/create-health-record.dto';
import { UpdateHealthRecordDto } from './dto/update-health-record.dto';
import { HealthQueryDto } from './dto/health-query.dto';
import { AnimalEntity } from '../herd/entities/animal.entity';
import { paginateQuery } from '../../common/pagination/paginate.util';
import { PaginatedResult } from '../../common/pagination/pagination.dto';
import { AuditService } from '../audit/audit.service';

export interface HealthReminderItem {
  id: string;
  animalId: string;
  earTag: string;
  animalName: string | null;
  careType: CareType;
  medicineVaccine: string;
  nextDueDate: string;
  daysRemaining: number;
  isOverdue: boolean;
  notes: string | null;
}

export interface ActiveWithdrawalItem {
  id: string;
  animalId: string;
  earTag: string;
  animalName: string | null;
  medicineVaccine: string;
  prescribedDose: string;
  withdrawalUntil: string;
  daysRemaining: number;
  notes: string | null;
}

@Injectable()
export class AnimalHealthService {
  constructor(
    @InjectRepository(HealthRecordEntity)
    private readonly healthRepo: Repository<HealthRecordEntity>,
    @InjectRepository(AnimalEntity)
    private readonly animalRepo: Repository<AnimalEntity>,
    private readonly auditService: AuditService,
  ) {}

  async findAll(query: HealthQueryDto): Promise<PaginatedResult<HealthRecordEntity>> {
    const qb = this.healthRepo
      .createQueryBuilder('health')
      .leftJoinAndSelect('health.animal', 'animal');

    if (query.animalId) {
      qb.andWhere('(health.animal_id = :animalId OR animal.ear_tag = :animalId)', {
        animalId: query.animalId.trim(),
      });
    }

    if (query.careType) {
      qb.andWhere('health.care_type = :careType', { careType: query.careType });
    }

    if (query.fromDate) {
      qb.andWhere('health.record_date >= :fromDate', { fromDate: query.fromDate });
    }

    if (query.toDate) {
      qb.andWhere('health.record_date <= :toDate', { toDate: query.toDate });
    }

    if (query.activeWithdrawalOnly) {
      qb.andWhere('health.withdrawal_until >= CURRENT_DATE()');
    }

    if (query.search) {
      const s = `%${query.search.trim()}%`;
      qb.andWhere(
        '(health.medicine_vaccine LIKE :s OR health.diagnosis LIKE :s OR health.veterinarian LIKE :s OR animal.ear_tag LIKE :s OR animal.name LIKE :s)',
        { s },
      );
    }

    qb.orderBy('health.record_date', 'DESC');
    return paginateQuery(qb, query);
  }

  async getReminders(): Promise<HealthReminderItem[]> {
    const rows = await this.healthRepo
      .createQueryBuilder('health')
      .innerJoinAndSelect('health.animal', 'animal')
      .where('health.next_due_date IS NOT NULL')
      .andWhere('health.next_due_date <= DATE_ADD(CURRENT_DATE(), INTERVAL 30 DAY)')
      .orderBy('health.next_due_date', 'ASC')
      .getMany();

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    return rows.map((r) => {
      const dueDate = new Date(r.nextDueDate!);
      dueDate.setHours(0, 0, 0, 0);
      const diffTime = dueDate.getTime() - today.getTime();
      const daysRemaining = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

      return {
        id: r.id,
        animalId: r.animalId,
        earTag: r.animal.earTag,
        animalName: r.animal.name,
        careType: r.careType,
        medicineVaccine: r.medicineVaccine,
        nextDueDate: r.nextDueDate!,
        daysRemaining,
        isOverdue: daysRemaining < 0,
        notes: r.notes,
      };
    });
  }

  async getActiveWithdrawals(): Promise<ActiveWithdrawalItem[]> {
    const rows = await this.healthRepo
      .createQueryBuilder('health')
      .innerJoinAndSelect('health.animal', 'animal')
      .where('health.withdrawal_until >= CURRENT_DATE()')
      .orderBy('health.withdrawal_until', 'ASC')
      .getMany();

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    return rows.map((r) => {
      const wDate = new Date(r.withdrawalUntil!);
      wDate.setHours(0, 0, 0, 0);
      const diffTime = wDate.getTime() - today.getTime();
      const daysRemaining = Math.max(1, Math.ceil(diffTime / (1000 * 60 * 60 * 24)));

      return {
        id: r.id,
        animalId: r.animalId,
        earTag: r.animal.earTag,
        animalName: r.animal.name,
        medicineVaccine: r.medicineVaccine,
        prescribedDose: r.prescribedDose,
        withdrawalUntil: r.withdrawalUntil!,
        daysRemaining,
        notes: r.notes,
      };
    });
  }

  async findById(id: string): Promise<HealthRecordEntity> {
    const record = await this.healthRepo.findOne({
      where: { id },
      relations: ['animal'],
    });

    if (!record) {
      throw new NotFoundException(`Health record with ID "${id}" was not found`);
    }

    return record;
  }

  async create(dto: CreateHealthRecordDto, userId?: string): Promise<HealthRecordEntity> {
    // Resolve animal by ID or earTag
    const animal = await this.animalRepo
      .createQueryBuilder('animal')
      .where('animal.id = :id OR animal.ear_tag = :id', { id: dto.animalId.trim() })
      .getOne();

    if (!animal) {
      throw new NotFoundException(`Animal with ID or Ear Tag "${dto.animalId}" was not found`);
    }

    // Keep treatment distinct from diagnosis:
    // If diagnosis provided, validate it's a non-empty string.
    const record = this.healthRepo.create({
      id: uuidv4(),
      animalId: animal.id,
      recordDate: dto.recordDate,
      careType: dto.careType,
      diagnosis: dto.diagnosis ? dto.diagnosis.trim() : null,
      medicineVaccine: dto.medicineVaccine.trim(),
      prescribedDose: dto.prescribedDose.trim(),
      veterinarian: dto.veterinarian ? dto.veterinarian.trim() : null,
      nextDueDate: dto.nextDueDate || null,
      withdrawalUntil: dto.withdrawalUntil || null,
      notes: dto.notes ? dto.notes.trim() : null,
      createdBy: userId || null,
    });

    const saved = await this.healthRepo.save(record);

    await this.auditService.logAction({
      userId,
      action: 'CREATE_HEALTH_RECORD',
      entityType: 'HEALTH_RECORD',
      entityId: saved.id,
      newValues: saved,
    });

    return this.findById(saved.id);
  }

  async update(id: string, dto: UpdateHealthRecordDto, userId?: string): Promise<HealthRecordEntity> {
    const record = await this.findById(id);
    const oldValues = { ...record };

    if (dto.recordDate !== undefined) record.recordDate = dto.recordDate;
    if (dto.careType !== undefined) record.careType = dto.careType;
    if (dto.diagnosis !== undefined) record.diagnosis = dto.diagnosis ? dto.diagnosis.trim() : null;
    if (dto.medicineVaccine !== undefined) record.medicineVaccine = dto.medicineVaccine.trim();
    if (dto.prescribedDose !== undefined) record.prescribedDose = dto.prescribedDose.trim();
    if (dto.veterinarian !== undefined) record.veterinarian = dto.veterinarian ? dto.veterinarian.trim() : null;
    if (dto.nextDueDate !== undefined) record.nextDueDate = dto.nextDueDate || null;
    if (dto.withdrawalUntil !== undefined) record.withdrawalUntil = dto.withdrawalUntil || null;
    if (dto.notes !== undefined) record.notes = dto.notes ? dto.notes.trim() : null;

    const saved = await this.healthRepo.save(record);

    await this.auditService.logAction({
      userId,
      action: 'UPDATE_HEALTH_RECORD',
      entityType: 'HEALTH_RECORD',
      entityId: saved.id,
      oldValues,
      newValues: saved,
    });

    return this.findById(saved.id);
  }
}
