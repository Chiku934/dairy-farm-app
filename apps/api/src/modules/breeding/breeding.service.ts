import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import { BreedingRecordEntity, BreedingEventType } from './entities/breeding-record.entity';
import { CreateBreedingRecordDto } from './dto/create-breeding-record.dto';
import { UpdateBreedingRecordDto } from './dto/update-breeding-record.dto';
import { BreedingQueryDto } from './dto/breeding-query.dto';
import { AnimalEntity, AnimalSex, AnimalStatus } from '../herd/entities/animal.entity';
import { paginateQuery } from '../../common/pagination/paginate.util';
import { PaginatedResult } from '../../common/pagination/pagination.dto';
import { AuditService } from '../audit/audit.service';

export interface BreedingReminderItem {
  id: string;
  animalId: string;
  earTag: string;
  animalName: string | null;
  reminderType: 'UPCOMING_CALVING' | 'PREGNANCY_CHECK';
  targetDate: string;
  daysRemaining: number;
  sireSemenId?: string | null;
  notes?: string | null;
}

@Injectable()
export class BreedingService {
  constructor(
    @InjectRepository(BreedingRecordEntity)
    private readonly breedingRepo: Repository<BreedingRecordEntity>,
    @InjectRepository(AnimalEntity)
    private readonly animalRepo: Repository<AnimalEntity>,
    private readonly auditService: AuditService,
  ) {}

  async findAll(query: BreedingQueryDto): Promise<PaginatedResult<BreedingRecordEntity>> {
    const qb = this.breedingRepo
      .createQueryBuilder('breeding')
      .leftJoinAndSelect('breeding.animal', 'animal');

    if (query.animalId) {
      qb.andWhere('(breeding.animal_id = :animalId OR animal.ear_tag = :animalId)', {
        animalId: query.animalId.trim(),
      });
    }

    if (query.eventType) {
      qb.andWhere('breeding.event_type = :eventType', { eventType: query.eventType });
    }

    if (query.fromDate) {
      qb.andWhere('breeding.record_date >= :fromDate', { fromDate: query.fromDate });
    }

    if (query.toDate) {
      qb.andWhere('breeding.record_date <= :toDate', { toDate: query.toDate });
    }

    if (query.search) {
      const s = `%${query.search.trim()}%`;
      qb.andWhere(
        '(breeding.sire_semen_id LIKE :s OR breeding.calf_tag LIKE :s OR breeding.notes LIKE :s OR animal.ear_tag LIKE :s OR animal.name LIKE :s)',
        { s },
      );
    }

    qb.orderBy('breeding.record_date', 'DESC');
    return paginateQuery(qb, query);
  }

  async getReminders(): Promise<BreedingReminderItem[]> {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const reminders: BreedingReminderItem[] = [];

    // 1. Upcoming Calvings within 30 days
    const upcomingCalvings = await this.breedingRepo
      .createQueryBuilder('breeding')
      .innerJoinAndSelect('breeding.animal', 'animal')
      .where('breeding.expected_calving_date IS NOT NULL')
      .andWhere('breeding.expected_calving_date <= DATE_ADD(CURRENT_DATE(), INTERVAL 30 DAY)')
      .andWhere('breeding.expected_calving_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)')
      .andWhere('animal.status = :pregnantStatus', { pregnantStatus: AnimalStatus.PREGNANT })
      .orderBy('breeding.expected_calving_date', 'ASC')
      .getMany();

    for (const b of upcomingCalvings) {
      const cDate = new Date(b.expectedCalvingDate!);
      cDate.setHours(0, 0, 0, 0);
      const diffTime = cDate.getTime() - today.getTime();
      const daysRemaining = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

      reminders.push({
        id: b.id,
        animalId: b.animalId,
        earTag: b.animal.earTag,
        animalName: b.animal.name,
        reminderType: 'UPCOMING_CALVING',
        targetDate: b.expectedCalvingDate!,
        daysRemaining,
        sireSemenId: b.sireSemenId,
        notes: b.notes,
      });
    }

    // 2. Pending Pregnancy Checks within 21 days
    const pendingChecks = await this.breedingRepo
      .createQueryBuilder('breeding')
      .innerJoinAndSelect('breeding.animal', 'animal')
      .where('breeding.next_check_date IS NOT NULL')
      .andWhere('breeding.next_check_date <= DATE_ADD(CURRENT_DATE(), INTERVAL 21 DAY)')
      .andWhere('breeding.event_type IN (:...events)', {
        events: [BreedingEventType.INSEMINATION, BreedingEventType.HEAT],
      })
      .orderBy('breeding.next_check_date', 'ASC')
      .getMany();

    for (const b of pendingChecks) {
      const chDate = new Date(b.nextCheckDate!);
      chDate.setHours(0, 0, 0, 0);
      const diffTime = chDate.getTime() - today.getTime();
      const daysRemaining = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

      reminders.push({
        id: b.id,
        animalId: b.animalId,
        earTag: b.animal.earTag,
        animalName: b.animal.name,
        reminderType: 'PREGNANCY_CHECK',
        targetDate: b.nextCheckDate!,
        daysRemaining,
        sireSemenId: b.sireSemenId,
        notes: b.notes,
      });
    }

    return reminders;
  }

  async findById(id: string): Promise<BreedingRecordEntity> {
    const record = await this.breedingRepo.findOne({
      where: { id },
      relations: ['animal'],
    });

    if (!record) {
      throw new NotFoundException(`Breeding record with ID "${id}" was not found`);
    }

    return record;
  }

  async create(dto: CreateBreedingRecordDto, userId?: string): Promise<BreedingRecordEntity> {
    // Resolve animal
    const animal = await this.animalRepo
      .createQueryBuilder('animal')
      .where('animal.id = :id OR animal.ear_tag = :id', { id: dto.animalId.trim() })
      .getOne();

    if (!animal) {
      throw new NotFoundException(`Animal with ID or Ear Tag "${dto.animalId}" was not found`);
    }

    if (animal.sex !== AnimalSex.FEMALE) {
      throw new BadRequestException(`Breeding events can only be registered for female cattle (Animal ${animal.earTag} is MALE)`);
    }

    let calculatedCalvingDate = dto.expectedCalvingDate || null;
    let calculatedCheckDate = dto.nextCheckDate || null;

    // Approved domain rule: Standard ~280 days gestation for cows from Insemination date
    if (dto.eventType === BreedingEventType.INSEMINATION) {
      if (!calculatedCalvingDate) {
        const aiDate = new Date(dto.recordDate);
        aiDate.setDate(aiDate.getDate() + 280);
        calculatedCalvingDate = aiDate.toISOString().substring(0, 10);
      }
      if (!calculatedCheckDate) {
        const aiDate = new Date(dto.recordDate);
        aiDate.setDate(aiDate.getDate() + 45); // standard 45-day ultrasound/pregnancy check
        calculatedCheckDate = aiDate.toISOString().substring(0, 10);
      }
    } else if (dto.eventType === BreedingEventType.HEAT && !calculatedCheckDate) {
      const heatDate = new Date(dto.recordDate);
      heatDate.setDate(heatDate.getDate() + 21); // standard 21-day recurrence check
      calculatedCheckDate = heatDate.toISOString().substring(0, 10);
    }

    const record = this.breedingRepo.create({
      id: uuidv4(),
      animalId: animal.id,
      recordDate: dto.recordDate,
      eventType: dto.eventType,
      sireSemenId: dto.sireSemenId ? dto.sireSemenId.trim() : null,
      expectedCalvingDate: calculatedCalvingDate,
      nextCheckDate: calculatedCheckDate,
      calfTag: dto.calfTag ? dto.calfTag.trim().toUpperCase() : null,
      notes: dto.notes ? dto.notes.trim() : null,
      createdBy: userId || null,
    });

    const saved = await this.breedingRepo.save(record);

    // Update animal status based on confirmed lifecycle events
    if (dto.eventType === BreedingEventType.PREGNANCY_CONFIRMED) {
      animal.status = AnimalStatus.PREGNANT;
      await this.animalRepo.save(animal);
    } else if (dto.eventType === BreedingEventType.CALVING) {
      animal.status = AnimalStatus.LACTATING;
      animal.lastCalvingDate = dto.recordDate;
      await this.animalRepo.save(animal);
    } else if (dto.eventType === BreedingEventType.DRY_OFF) {
      animal.status = AnimalStatus.DRY;
      await this.animalRepo.save(animal);
    }

    await this.auditService.logAction({
      userId,
      action: 'CREATE_BREEDING_RECORD',
      entityType: 'BREEDING_RECORD',
      entityId: saved.id,
      newValues: saved,
    });

    return this.findById(saved.id);
  }

  async update(id: string, dto: UpdateBreedingRecordDto, userId?: string): Promise<BreedingRecordEntity> {
    const record = await this.findById(id);
    const oldValues = { ...record };

    if (dto.recordDate !== undefined) record.recordDate = dto.recordDate;
    if (dto.eventType !== undefined) record.eventType = dto.eventType;
    if (dto.sireSemenId !== undefined) record.sireSemenId = dto.sireSemenId ? dto.sireSemenId.trim() : null;
    if (dto.expectedCalvingDate !== undefined) record.expectedCalvingDate = dto.expectedCalvingDate || null;
    if (dto.nextCheckDate !== undefined) record.nextCheckDate = dto.nextCheckDate || null;
    if (dto.calfTag !== undefined) record.calfTag = dto.calfTag ? dto.calfTag.trim().toUpperCase() : null;
    if (dto.notes !== undefined) record.notes = dto.notes ? dto.notes.trim() : null;

    const saved = await this.breedingRepo.save(record);

    await this.auditService.logAction({
      userId,
      action: 'UPDATE_BREEDING_RECORD',
      entityType: 'BREEDING_RECORD',
      entityId: saved.id,
      oldValues,
      newValues: saved,
    });

    return this.findById(saved.id);
  }
}
