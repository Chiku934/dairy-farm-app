import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import { AuditLogEntity } from './entities/audit-log.entity';
import { AuditQueryDto } from './dto/audit-query.dto';
import { paginateQuery } from '../../common/pagination/paginate.util';
import { PaginatedResult } from '../../common/pagination/pagination.dto';

export interface RecordAuditParams {
  userId?: string;
  action: string;
  entityType: string;
  entityId?: string;
  oldValues?: any;
  newValues?: any;
  ipAddress?: string;
  userAgent?: string;
}

@Injectable()
export class AuditService {
  constructor(
    @InjectRepository(AuditLogEntity)
    private readonly auditRepo: Repository<AuditLogEntity>,
  ) {}

  async logAction(params: RecordAuditParams): Promise<AuditLogEntity> {
    const entry = this.auditRepo.create({
      id: uuidv4(),
      userId: params.userId || null,
      action: params.action,
      entityType: params.entityType,
      entityId: params.entityId || null,
      oldValues: params.oldValues || null,
      newValues: params.newValues || null,
      ipAddress: params.ipAddress || null,
      userAgent: params.userAgent ? params.userAgent.substring(0, 255) : null,
    });
    return this.auditRepo.save(entry);
  }

  async findAll(query: AuditQueryDto): Promise<PaginatedResult<AuditLogEntity>> {
    const qb = this.auditRepo
      .createQueryBuilder('audit')
      .leftJoinAndSelect('audit.user', 'user');

    if (query.entityType) {
      qb.andWhere('audit.entityType = :entityType', { entityType: query.entityType });
    }

    if (query.action) {
      qb.andWhere('audit.action = :action', { action: query.action });
    }

    if (query.userId) {
      qb.andWhere('audit.userId = :userId', { userId: query.userId });
    }

    if (query.search) {
      qb.andWhere(
        '(audit.action LIKE :search OR audit.entityType LIKE :search OR audit.entityId LIKE :search)',
        { search: `%${query.search}%` },
      );
    }

    qb.orderBy('audit.createdAt', query.sortOrder || 'DESC');

    return paginateQuery(qb, query);
  }
}
