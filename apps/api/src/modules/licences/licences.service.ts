import {
  Injectable,
  NotFoundException,
  ConflictException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import { RegulatoryLicenceEntity } from './entities/regulatory-licence.entity';
import { CreateLicenceDto } from './dto/create-licence.dto';
import { UpdateLicenceDto } from './dto/update-licence.dto';
import { LicenceQueryDto } from './dto/licence-query.dto';
import { LicenceNotificationService } from './licence-notification.service';
import { AuditService } from '../audit/audit.service';
import { AuthenticatedUser } from '../../common/decorators/current-user.decorator';
import { LicenceStatus, ReminderStatus } from '@dairy-farm/api-contracts';

@Injectable()
export class LicencesService {
  private readonly logger = new Logger(LicencesService.name);

  constructor(
    @InjectRepository(RegulatoryLicenceEntity)
    private readonly licenceRepo: Repository<RegulatoryLicenceEntity>,
    private readonly notificationService: LicenceNotificationService,
    private readonly auditService: AuditService,
  ) {}

  private validateDates(issueDate: string, expiryDate: string): void {
    if (expiryDate <= issueDate) {
      throw new BadRequestException('expiry_date must be strictly after issue_date');
    }
  }

  private deriveStatus(
    expiryDate: string,
    reminderDays: number,
    currentStatus?: LicenceStatus,
  ): LicenceStatus {
    if (currentStatus === LicenceStatus.SUSPENDED) {
      return LicenceStatus.SUSPENDED;
    }

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const expiry = new Date(expiryDate);
    expiry.setHours(0, 0, 0, 0);

    const diffDays = Math.ceil((expiry.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));

    if (diffDays < 0) {
      return LicenceStatus.EXPIRED;
    }
    if (diffDays <= reminderDays) {
      return LicenceStatus.EXPIRING_SOON;
    }
    return LicenceStatus.ACTIVE;
  }

  async create(
    dto: CreateLicenceDto,
    user?: AuthenticatedUser,
  ): Promise<RegulatoryLicenceEntity> {
    this.validateDates(dto.issueDate, dto.expiryDate);

    const existingNumber = await this.licenceRepo.findOne({
      where: { licenceNumber: dto.licenceNumber },
    });
    if (existingNumber) {
      throw new ConflictException(`Licence number ${dto.licenceNumber} already exists`);
    }

    const reminderDays = dto.reminderDaysBefore ?? 30;
    const computedStatus = dto.status || this.deriveStatus(dto.expiryDate, reminderDays);

    const licence = this.licenceRepo.create({
      id: uuidv4(),
      licenceName: dto.licenceName,
      licenceType: dto.licenceType,
      licenceNumber: dto.licenceNumber,
      issuingAuthority: dto.issuingAuthority,
      licenceHolder: dto.licenceHolder,
      issueDate: dto.issueDate,
      expiryDate: dto.expiryDate,
      reminderDaysBefore: reminderDays,
      status: computedStatus,
      reminderStatus: dto.reminderStatus || ReminderStatus.PENDING,
      documentUrl: dto.documentUrl || null,
      notes: dto.notes || null,
    });

    const saved = await this.licenceRepo.save(licence);

    await this.auditService.logAction({
      userId: user?.userId,
      action: 'CREATE_REGULATORY_LICENCE',
      entityType: 'REGULATORY_LICENCE',
      entityId: saved.id,
      newValues: {
        licenceName: saved.licenceName,
        licenceType: saved.licenceType,
        licenceNumber: saved.licenceNumber,
        issueDate: saved.issueDate,
        expiryDate: saved.expiryDate,
        status: saved.status,
        reminderStatus: saved.reminderStatus,
      },
    });

    this.logger.log(`Created regulatory licence ${saved.licenceNumber} (${saved.licenceName})`);
    return saved;
  }

  async findAll(
    query: LicenceQueryDto,
  ): Promise<{ data: RegulatoryLicenceEntity[]; total: number; page: number; limit: number }> {
    const qb = this.licenceRepo.createQueryBuilder('licence');

    if (query.licenceType) {
      qb.andWhere('licence.licenceType = :licenceType', { licenceType: query.licenceType });
    }

    if (query.status) {
      qb.andWhere('licence.status = :status', { status: query.status });
    }

    if (query.reminderStatus) {
      qb.andWhere('licence.reminderStatus = :reminderStatus', { reminderStatus: query.reminderStatus });
    }

    if (query.search) {
      qb.andWhere(
        '(licence.licence_name LIKE :search OR licence.licence_number LIKE :search OR licence.issuing_authority LIKE :search OR licence.licence_holder LIKE :search)',
        { search: `%${query.search}%` },
      );
    }

    qb.orderBy('licence.expiryDate', 'ASC');

    const page = query.page || 1;
    const limit = query.limit || 20;
    qb.skip((page - 1) * limit).take(limit);

    const [items, total] = await qb.getManyAndCount();

    // Dynamically evaluate status for each record
    for (const lic of items) {
      const freshStatus = this.deriveStatus(lic.expiryDate, lic.reminderDaysBefore, lic.status);
      if (freshStatus !== lic.status) {
        lic.status = freshStatus;
        await this.licenceRepo.update(lic.id, { status: freshStatus });
      }
    }

    return { data: items, total, page, limit };
  }

  async findOne(id: string): Promise<RegulatoryLicenceEntity> {
    const licence = await this.licenceRepo.findOne({ where: { id } });
    if (!licence) {
      throw new NotFoundException(`Licence with ID ${id} not found`);
    }

    const freshStatus = this.deriveStatus(licence.expiryDate, licence.reminderDaysBefore, licence.status);
    if (freshStatus !== licence.status) {
      licence.status = freshStatus;
      await this.licenceRepo.update(licence.id, { status: freshStatus });
    }

    return licence;
  }

  async update(
    id: string,
    dto: UpdateLicenceDto,
    user?: AuthenticatedUser,
  ): Promise<RegulatoryLicenceEntity> {
    const licence = await this.licenceRepo.findOne({ where: { id } });
    if (!licence) {
      throw new NotFoundException(`Licence with ID ${id} not found`);
    }

    const issueDate = dto.issueDate || licence.issueDate;
    const expiryDate = dto.expiryDate || licence.expiryDate;
    this.validateDates(issueDate, expiryDate);

    if (dto.licenceNumber && dto.licenceNumber !== licence.licenceNumber) {
      const existing = await this.licenceRepo.findOne({
        where: { licenceNumber: dto.licenceNumber },
      });
      if (existing) {
        throw new ConflictException(`Licence number ${dto.licenceNumber} already exists`);
      }
      licence.licenceNumber = dto.licenceNumber;
    }

    const oldValues = {
      licenceName: licence.licenceName,
      licenceNumber: licence.licenceNumber,
      issueDate: licence.issueDate,
      expiryDate: licence.expiryDate,
      status: licence.status,
      reminderStatus: licence.reminderStatus,
    };

    if (dto.licenceName !== undefined) licence.licenceName = dto.licenceName;
    if (dto.licenceType !== undefined) licence.licenceType = dto.licenceType;
    if (dto.issuingAuthority !== undefined) licence.issuingAuthority = dto.issuingAuthority;
    if (dto.licenceHolder !== undefined) licence.licenceHolder = dto.licenceHolder;
    if (dto.issueDate !== undefined) licence.issueDate = dto.issueDate;
    if (dto.expiryDate !== undefined) licence.expiryDate = dto.expiryDate;
    if (dto.reminderDaysBefore !== undefined) licence.reminderDaysBefore = dto.reminderDaysBefore;
    if (dto.documentUrl !== undefined) licence.documentUrl = dto.documentUrl || null;
    if (dto.notes !== undefined) licence.notes = dto.notes || null;
    if (dto.reminderStatus !== undefined) licence.reminderStatus = dto.reminderStatus;

    const reminderDays = licence.reminderDaysBefore;
    licence.status = dto.status || this.deriveStatus(licence.expiryDate, reminderDays, licence.status);

    const saved = await this.licenceRepo.save(licence);

    await this.auditService.logAction({
      userId: user?.userId,
      action: 'UPDATE_REGULATORY_LICENCE',
      entityType: 'REGULATORY_LICENCE',
      entityId: saved.id,
      oldValues,
      newValues: {
        licenceName: saved.licenceName,
        licenceNumber: saved.licenceNumber,
        issueDate: saved.issueDate,
        expiryDate: saved.expiryDate,
        status: saved.status,
        reminderStatus: saved.reminderStatus,
      },
    });

    return saved;
  }

  async processReminders(user?: AuthenticatedUser): Promise<{
    configured: boolean;
    dispatchedCount: number;
    message: string;
  }> {
    if (!this.notificationService.isServiceConfigured()) {
      return {
        configured: false,
        dispatchedCount: 0,
        message: 'Notification service is not configured. Expiry reminders were not dispatched.',
      };
    }

    const eligibleLicences = await this.licenceRepo.find({
      where: [
        { status: LicenceStatus.EXPIRING_SOON, reminderStatus: ReminderStatus.PENDING },
        { status: LicenceStatus.EXPIRED, reminderStatus: ReminderStatus.PENDING },
      ],
    });

    let count = 0;
    for (const lic of eligibleLicences) {
      const result = await this.notificationService.dispatchReminder(lic);
      if (result.dispatched) {
        lic.reminderStatus = ReminderStatus.NOTIFIED;
        lic.reminderSentAt = new Date();
        await this.licenceRepo.save(lic);

        await this.auditService.logAction({
          userId: user?.userId,
          action: 'DISPATCH_LICENCE_REMINDER',
          entityType: 'REGULATORY_LICENCE',
          entityId: lic.id,
          newValues: {
            licenceNumber: lic.licenceNumber,
            reminderStatus: lic.reminderStatus,
            reminderSentAt: lic.reminderSentAt,
          },
        });
        count++;
      }
    }

    return {
      configured: true,
      dispatchedCount: count,
      message: `Successfully processed reminders. ${count} notifications dispatched.`,
    };
  }

  async dismissReminder(id: string, user?: AuthenticatedUser): Promise<RegulatoryLicenceEntity> {
    const licence = await this.licenceRepo.findOne({ where: { id } });
    if (!licence) {
      throw new NotFoundException(`Licence with ID ${id} not found`);
    }

    licence.reminderStatus = ReminderStatus.DISMISSED;
    const saved = await this.licenceRepo.save(licence);

    await this.auditService.logAction({
      userId: user?.userId,
      action: 'DISMISS_LICENCE_REMINDER',
      entityType: 'REGULATORY_LICENCE',
      entityId: licence.id,
      newValues: {
        reminderStatus: licence.reminderStatus,
      },
    });

    return saved;
  }
}
