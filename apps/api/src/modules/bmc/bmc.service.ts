import {
  Injectable,
  NotFoundException,
  ConflictException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import {
  BmcIntakeLog,
  MilkIntakeSource,
  IntakeShift,
  Decision,
} from './entities/bmc-intake-log.entity';
import { CreateBmcIntakeDto } from './dto/create-bmc-intake.dto';
import { BmcQueryDto } from './dto/bmc-query.dto';
import { AuthenticatedUser } from '../../common/decorators/current-user.decorator';

@Injectable()
export class BmcService {
  constructor(
    @InjectRepository(BmcIntakeLog)
    private readonly bmcIntakeRepo: Repository<BmcIntakeLog>,
    private readonly dataSource: DataSource,
  ) {}

  async createIntake(
    dto: CreateBmcIntakeDto,
    currentUser?: AuthenticatedUser,
  ): Promise<BmcIntakeLog> {
    // 1. Duplicate check: Farm can only have 1 intake per date & shift
    if (dto.source === MilkIntakeSource.FARM) {
      const existing = await this.bmcIntakeRepo.findOne({
        where: {
          recordDate: dto.recordDate,
          shift: dto.shift,
          source: MilkIntakeSource.FARM,
        },
      });
      if (existing) {
        throw new ConflictException(
          `A Farm milk intake record already exists for ${dto.recordDate} (${dto.shift} shift).`,
        );
      }
    } else if (dto.supplierRoute) {
      const existing = await this.bmcIntakeRepo.findOne({
        where: {
          recordDate: dto.recordDate,
          shift: dto.shift,
          source: MilkIntakeSource.EXTERNAL,
          supplierRoute: dto.supplierRoute,
        },
      });
      if (existing) {
        throw new ConflictException(
          `An external intake record for route '${dto.supplierRoute}' already exists for ${dto.recordDate} (${dto.shift} shift).`,
        );
      }
    }

    // 2. Validate Rejection Reason
    if (dto.decision === Decision.REJECTED && (!dto.rejectionReason || dto.rejectionReason.trim() === '')) {
      throw new BadRequestException('Rejection reason is mandatory when milk is rejected.');
    }

    // 3. Generate unique batch number
    const prefix = dto.source === MilkIntakeSource.FARM ? 'INT-FRM' : 'INT-EXT';
    const cleanDate = dto.recordDate.replace(/-/g, '');
    const randomSuffix = Math.floor(100 + Math.random() * 900);
    const batchNumber = `${prefix}-${cleanDate}-${dto.shift}-${randomSuffix}`;

    const intake = this.bmcIntakeRepo.create({
      ...dto,
      batchNumber,
      operatorId: currentUser?.userId,
      operatorName: dto.operatorName || currentUser?.fullName || 'Authorized Operator',
    });

    return await this.bmcIntakeRepo.save(intake);
  }

  async findAllIntakes(query: BmcQueryDto) {
    const qb = this.bmcIntakeRepo.createQueryBuilder('intake');

    if (query.date) {
      qb.andWhere('intake.record_date = :date', { date: query.date });
    }
    if (query.startDate) {
      qb.andWhere('intake.record_date >= :startDate', { startDate: query.startDate });
    }
    if (query.endDate) {
      qb.andWhere('intake.record_date <= :endDate', { endDate: query.endDate });
    }
    if (query.shift) {
      qb.andWhere('intake.shift = :shift', { shift: query.shift });
    }
    if (query.source) {
      qb.andWhere('intake.source = :source', { source: query.source });
    }
    if (query.decision) {
      qb.andWhere('intake.decision = :decision', { decision: query.decision });
    }
    if (query.search) {
      qb.andWhere(
        '(intake.batch_number LIKE :search OR intake.supplier_route LIKE :search OR intake.operator_name LIKE :search)',
        { search: `%${query.search}%` },
      );
    }

    qb.orderBy('intake.record_date', 'DESC')
      .addOrderBy('intake.created_at', 'DESC');

    const page = query.page || 1;
    const limit = query.limit || 20;
    const skip = (page - 1) * limit;

    const [items, total] = await qb.skip(skip).take(limit).getManyAndCount();

    return {
      items,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit) || 1,
    };
  }

  async findOneIntake(id: string): Promise<BmcIntakeLog> {
    const intake = await this.bmcIntakeRepo.findOne({
      where: { id },
      relations: ['batchLinks', 'batchLinks.productionBatch'],
    });

    if (!intake) {
      throw new NotFoundException(`BMC Intake record with ID '${id}' not found.`);
    }

    return intake;
  }

  async getTankBalance() {
    // 1. Settings capacity
    const settingsRaw = await this.dataSource.query(
      `SELECT bmc_capacity_litres FROM farm_settings WHERE id = 1 LIMIT 1`,
    );
    const capacity = Number(settingsRaw[0]?.bmc_capacity_litres || 2000.0);

    // 2. Sum Accepted Intakes
    const intakeRaw = await this.dataSource.query(
      `SELECT COALESCE(SUM(quantity_litres), 0) AS accepted_litres
       FROM bmc_intake_logs
       WHERE decision = 'ACCEPTED'`,
    );
    const acceptedLitres = Number(intakeRaw[0]?.accepted_litres || 0);

    // 3. Sum Production Consumption
    const prodRaw = await this.dataSource.query(
      `SELECT COALESCE(SUM(bmc_milk_consumed_l), 0) AS consumed_litres
       FROM production_batches
       WHERE status != 'CANCELLED'`,
    );
    const consumedLitres = Number(prodRaw[0]?.consumed_litres || 0);

    // 4. Sum BMC Wastage
    const wasteRaw = await this.dataSource.query(
      `SELECT COALESCE(SUM(quantity_lost), 0) AS lost_litres
       FROM wastage_records
       WHERE stock_type = 'BMC'`,
    );
    const wastageLitres = Number(wasteRaw[0]?.lost_litres || 0);

    // 5. Net Live Balance
    const currentBalance = Math.max(0, acceptedLitres - consumedLitres - wastageLitres);
    const availableCapacity = Math.max(0, capacity - currentBalance);
    const utilizationPct = Number(((currentBalance / capacity) * 100).toFixed(1));

    let status: 'NORMAL' | 'WARNING' | 'CRITICAL' = 'NORMAL';
    if (utilizationPct >= 90) {
      status = 'CRITICAL';
    } else if (utilizationPct >= 75) {
      status = 'WARNING';
    }

    // 6. Today's breakdown
    const todayRaw = await this.dataSource.query(
      `SELECT 
         COALESCE(SUM(CASE WHEN source = 'FARM' AND decision = 'ACCEPTED' THEN quantity_litres ELSE 0 END), 0) as today_farm_accepted,
         COALESCE(SUM(CASE WHEN source = 'EXTERNAL' AND decision = 'ACCEPTED' THEN quantity_litres ELSE 0 END), 0) as today_external_accepted,
         COALESCE(SUM(CASE WHEN decision = 'REJECTED' THEN quantity_litres ELSE 0 END), 0) as today_rejected
       FROM bmc_intake_logs
       WHERE record_date = CURDATE()`,
    );

    return {
      capacityLitres: capacity,
      currentBalanceLitres: Number(currentBalance.toFixed(2)),
      availableCapacityLitres: Number(availableCapacity.toFixed(2)),
      utilizationPercentage: utilizationPct,
      status,
      ledger: {
        totalAcceptedIntake: Number(acceptedLitres.toFixed(2)),
        totalProductionConsumed: Number(consumedLitres.toFixed(2)),
        totalWastageLost: Number(wastageLitres.toFixed(2)),
      },
      today: {
        farmAcceptedLitres: Number(todayRaw[0]?.today_farm_accepted || 0),
        externalAcceptedLitres: Number(todayRaw[0]?.today_external_accepted || 0),
        rejectedLitres: Number(todayRaw[0]?.today_rejected || 0),
      },
    };
  }
}
