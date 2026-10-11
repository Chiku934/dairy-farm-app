import {
  Injectable,
  NotFoundException,
  ConflictException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import { AnimalEntity, AnimalStatus } from './entities/animal.entity';
import { CreateAnimalDto } from './dto/create-animal.dto';
import { UpdateAnimalDto } from './dto/update-animal.dto';
import { ArchiveAnimalDto } from './dto/archive-animal.dto';
import { AnimalQueryDto } from './dto/animal-query.dto';
import { paginateQuery } from '../../common/pagination/paginate.util';
import { PaginatedResult } from '../../common/pagination/pagination.dto';
import { AuditService } from '../audit/audit.service';
import { HealthRecordEntity } from '../animal-health/entities/health-record.entity';
import { BreedingRecordEntity } from '../breeding/entities/breeding-record.entity';

export interface AnimalHistoryTimelineItem {
  id: string;
  date: string;
  type: 'HEALTH' | 'BREEDING' | 'MILKING';
  title: string;
  subtitle: string;
  details?: Record<string, any>;
  badge?: string;
}

export interface HerdSummaryCounts {
  totalActive: number;
  lactating: number;
  dry: number;
  pregnant: number;
  heifer: number;
  calf: number;
  bull: number;
  archived: number;
}

@Injectable()
export class HerdService {
  constructor(
    @InjectRepository(AnimalEntity)
    private readonly animalRepo: Repository<AnimalEntity>,
    @InjectRepository(HealthRecordEntity)
    private readonly healthRepo: Repository<HealthRecordEntity>,
    @InjectRepository(BreedingRecordEntity)
    private readonly breedingRepo: Repository<BreedingRecordEntity>,
    private readonly dataSource: DataSource,
    private readonly auditService: AuditService,
  ) {}

  async findAll(query: AnimalQueryDto): Promise<PaginatedResult<AnimalEntity>> {
    const qb = this.animalRepo.createQueryBuilder('animal');

    if (!query.includeArchived) {
      qb.andWhere('animal.is_archived = :isArchived', { isArchived: false });
    }

    if (query.status) {
      qb.andWhere('animal.status = :status', { status: query.status });
    }

    if (query.breed) {
      qb.andWhere('animal.breed = :breed', { breed: query.breed });
    }

    if (query.sex) {
      qb.andWhere('animal.sex = :sex', { sex: query.sex });
    }

    if (query.search) {
      const s = `%${query.search.trim()}%`;
      qb.andWhere(
        '(animal.ear_tag LIKE :s OR animal.name LIKE :s OR animal.dam_tag LIKE :s OR animal.breed LIKE :s)',
        { s },
      );
    }

    qb.orderBy('animal.created_at', 'DESC');
    return paginateQuery(qb, query);
  }

  async getSummary(): Promise<HerdSummaryCounts> {
    const rawCounts = await this.animalRepo
      .createQueryBuilder('animal')
      .select('animal.status', 'status')
      .addSelect('animal.is_archived', 'isArchived')
      .addSelect('COUNT(*)', 'count')
      .groupBy('animal.status')
      .addGroupBy('animal.is_archived')
      .getRawMany();

    const summary: HerdSummaryCounts = {
      totalActive: 0,
      lactating: 0,
      dry: 0,
      pregnant: 0,
      heifer: 0,
      calf: 0,
      bull: 0,
      archived: 0,
    };

    for (const row of rawCounts) {
      const count = parseInt(row.count, 10);
      const isArchived = Boolean(row.isArchived);
      const status = row.status as AnimalStatus;

      if (isArchived) {
        summary.archived += count;
      } else {
        summary.totalActive += count;
        if (status === AnimalStatus.LACTATING) summary.lactating += count;
        else if (status === AnimalStatus.DRY) summary.dry += count;
        else if (status === AnimalStatus.PREGNANT) summary.pregnant += count;
        else if (status === AnimalStatus.HEIFER) summary.heifer += count;
        else if (status === AnimalStatus.CALF) summary.calf += count;
        else if (status === AnimalStatus.BULL) summary.bull += count;
      }
    }

    return summary;
  }

  async findByIdOrTag(idOrTag: string): Promise<AnimalEntity> {
    const animal = await this.animalRepo
      .createQueryBuilder('animal')
      .where('animal.id = :idOrTag OR animal.ear_tag = :idOrTag', { idOrTag: idOrTag.trim() })
      .getOne();

    if (!animal) {
      throw new NotFoundException(`Animal with identifier "${idOrTag}" was not found`);
    }

    return animal;
  }

  async getHistory(idOrTag: string): Promise<{ animal: AnimalEntity; timeline: AnimalHistoryTimelineItem[] }> {
    const animal = await this.findByIdOrTag(idOrTag);

    // 1. Fetch Health Records
    const healthRecords = await this.healthRepo.find({
      where: { animalId: animal.id },
      order: { recordDate: 'DESC', createdAt: 'DESC' },
    });

    // 2. Fetch Breeding Records
    const breedingRecords = await this.breedingRepo.find({
      where: { animalId: animal.id },
      order: { recordDate: 'DESC', createdAt: 'DESC' },
    });

    // 3. Fetch Milking Records (Last 30 records)
    const milkingRows: Array<{
      id: string;
      record_date: string;
      session: string;
      yield_litres: string;
      disposition: string;
      notes: string | null;
    }> = await this.dataSource.query(
      `SELECT id, record_date, session, yield_litres, disposition, notes
       FROM milking_logs
       WHERE animal_id = ?
       ORDER BY record_date DESC, session DESC
       LIMIT 30`,
      [animal.id],
    );

    const timeline: AnimalHistoryTimelineItem[] = [];

    // Map Health items
    for (const h of healthRecords) {
      timeline.push({
        id: h.id,
        date: h.recordDate,
        type: 'HEALTH',
        title: `${h.careType}: ${h.medicineVaccine}`,
        subtitle: h.diagnosis ? `Diagnosis: ${h.diagnosis} | Dose: ${h.prescribedDose}` : `Dose: ${h.prescribedDose}`,
        details: {
          careType: h.careType,
          diagnosis: h.diagnosis,
          veterinarian: h.veterinarian,
          withdrawalUntil: h.withdrawalUntil,
          nextDueDate: h.nextDueDate,
          notes: h.notes,
        },
        badge: h.withdrawalUntil ? `Withdrawal: ${h.withdrawalUntil}` : undefined,
      });
    }

    // Map Breeding items
    for (const b of breedingRecords) {
      let subtitle = b.notes || '';
      if (b.sireSemenId) subtitle = `Sire/Semen: ${b.sireSemenId} ${subtitle ? '· ' + subtitle : ''}`;
      if (b.expectedCalvingDate) subtitle += ` · Exp. Calving: ${b.expectedCalvingDate}`;
      if (b.calfTag) subtitle += ` · Calf: ${b.calfTag}`;

      timeline.push({
        id: b.id,
        date: b.recordDate,
        type: 'BREEDING',
        title: `Breeding: ${b.eventType.replace('_', ' ')}`,
        subtitle: subtitle.trim(),
        details: {
          eventType: b.eventType,
          sireSemenId: b.sireSemenId,
          expectedCalvingDate: b.expectedCalvingDate,
          nextCheckDate: b.nextCheckDate,
          calfTag: b.calfTag,
          notes: b.notes,
        },
        badge: b.expectedCalvingDate ? `Due: ${b.expectedCalvingDate}` : undefined,
      });
    }

    // Map Milking items
    for (const m of milkingRows) {
      const dateStr = typeof m.record_date === 'string' ? m.record_date : new Date(m.record_date).toISOString().substring(0, 10);
      timeline.push({
        id: m.id,
        date: dateStr,
        type: 'MILKING',
        title: `Milking: ${m.yield_litres} L (${m.session})`,
        subtitle: `Disposition: ${m.disposition}${m.notes ? ' · ' + m.notes : ''}`,
        details: {
          session: m.session,
          yieldLitres: parseFloat(m.yield_litres),
          disposition: m.disposition,
        },
        badge: `${m.yield_litres} L`,
      });
    }

    // Sort complete timeline in descending chronological order
    timeline.sort((a, b) => b.date.localeCompare(a.date));

    return { animal, timeline };
  }

  async create(dto: CreateAnimalDto, userId?: string): Promise<AnimalEntity> {
    const formattedTag = dto.earTag.trim().toUpperCase();

    // Check unique earTag
    const existing = await this.animalRepo.findOne({ where: { earTag: formattedTag } });
    if (existing) {
      throw new ConflictException(`Animal with Ear Tag "${formattedTag}" already exists`);
    }

    // If dam tag provided, check if valid
    if (dto.damTag) {
      dto.damTag = dto.damTag.trim().toUpperCase();
      if (dto.damTag === formattedTag) {
        throw new BadRequestException('Dam tag cannot be the same as the animal ear tag');
      }
    }

    const animal = this.animalRepo.create({
      id: uuidv4(),
      earTag: formattedTag,
      name: dto.name ? dto.name.trim() : null,
      breed: dto.breed.trim(),
      sex: dto.sex,
      dateOfBirth: dto.dateOfBirth || null,
      status: dto.status || AnimalStatus.LACTATING,
      bodyWeightKg: dto.bodyWeightKg ?? null,
      damTag: dto.damTag || null,
      lastCalvingDate: dto.lastCalvingDate || null,
      bodyConditionScore: dto.bodyConditionScore ?? null,
      notes: dto.notes ? dto.notes.trim() : null,
      isArchived: false,
      archivedAt: null,
      archiveReason: null,
    });

    const saved = await this.animalRepo.save(animal);

    await this.auditService.logAction({
      userId,
      action: 'CREATE_ANIMAL',
      entityType: 'ANIMAL',
      entityId: saved.id,
      newValues: saved,
    });

    return saved;
  }

  async update(id: string, dto: UpdateAnimalDto, userId?: string): Promise<AnimalEntity> {
    const animal = await this.findByIdOrTag(id);
    const oldValues = { ...animal };

    if (dto.earTag) {
      const formattedTag = dto.earTag.trim().toUpperCase();
      if (formattedTag !== animal.earTag) {
        const existing = await this.animalRepo.findOne({ where: { earTag: formattedTag } });
        if (existing) {
          throw new ConflictException(`Animal with Ear Tag "${formattedTag}" already exists`);
        }
        animal.earTag = formattedTag;
      }
    }

    if (dto.name !== undefined) animal.name = dto.name ? dto.name.trim() : null;
    if (dto.breed !== undefined) animal.breed = dto.breed.trim();
    if (dto.sex !== undefined) animal.sex = dto.sex;
    if (dto.dateOfBirth !== undefined) animal.dateOfBirth = dto.dateOfBirth || null;
    if (dto.status !== undefined) animal.status = dto.status;
    if (dto.bodyWeightKg !== undefined) animal.bodyWeightKg = dto.bodyWeightKg;
    if (dto.damTag !== undefined) animal.damTag = dto.damTag ? dto.damTag.trim().toUpperCase() : null;
    if (dto.lastCalvingDate !== undefined) animal.lastCalvingDate = dto.lastCalvingDate || null;
    if (dto.bodyConditionScore !== undefined) animal.bodyConditionScore = dto.bodyConditionScore;
    if (dto.notes !== undefined) animal.notes = dto.notes ? dto.notes.trim() : null;

    const saved = await this.animalRepo.save(animal);

    await this.auditService.logAction({
      userId,
      action: 'UPDATE_ANIMAL',
      entityType: 'ANIMAL',
      entityId: saved.id,
      oldValues,
      newValues: saved,
    });

    return saved;
  }

  async archive(id: string, dto: ArchiveAnimalDto, userId?: string): Promise<AnimalEntity> {
    const animal = await this.findByIdOrTag(id);
    const oldValues = { ...animal };

    animal.isArchived = true;
    animal.archivedAt = new Date();
    animal.archiveReason = dto.archiveReason.trim();

    if (dto.status) {
      animal.status = dto.status;
    } else if (animal.status !== AnimalStatus.SOLD && animal.status !== AnimalStatus.DECEASED) {
      animal.status = AnimalStatus.SOLD;
    }

    const saved = await this.animalRepo.save(animal);

    await this.auditService.logAction({
      userId,
      action: 'ARCHIVE_ANIMAL',
      entityType: 'ANIMAL',
      entityId: saved.id,
      oldValues,
      newValues: saved,
    });

    return saved;
  }
}
