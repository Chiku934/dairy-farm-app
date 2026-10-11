import { Test, TestingModule } from '@nestjs/testing';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { v4 as uuidv4 } from 'uuid';
import { ConflictException, NotFoundException, BadRequestException, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';

import { MilkingLogEntity, MilkingSession, MilkDisposition } from '../modules/milking/entities/milking-log.entity';
import { FeedEntryEntity, FeedType, FeedShift } from '../modules/feed/entities/feed-entry.entity';
import { StockItemEntity } from '../modules/feed/entities/stock-item.entity';
import { RationDefinitionEntity, TargetAnimalStage } from '../modules/feed/entities/ration-definition.entity';
import { RationItemEntity } from '../modules/feed/entities/ration-item.entity';
import { AnimalEntity, AnimalSex, AnimalStatus } from '../modules/herd/entities/animal.entity';
import { HealthRecordEntity, CareType } from '../modules/animal-health/entities/health-record.entity';
import { UserEntity } from '../modules/users/entities/user.entity';
import { RoleEntity } from '../modules/users/entities/role.entity';
import { PermissionEntity } from '../modules/users/entities/permission.entity';
import { UserSessionEntity } from '../modules/auth/entities/user-session.entity';
import { AuditLogEntity } from '../modules/audit/entities/audit-log.entity';

import { MilkingService } from '../modules/milking/milking.service';
import { MilkingController } from '../modules/milking/milking.controller';
import { FeedService } from '../modules/feed/feed.service';
import { FeedController } from '../modules/feed/feed.controller';
import { CostingService } from '../modules/costing/costing.service';
import { CostingController } from '../modules/costing/costing.controller';
import { AuditService } from '../modules/audit/audit.service';
import { UsersService } from '../modules/users/users.service';
import { AuthService } from '../modules/auth/auth.service';
import { JwtStrategy } from '../modules/auth/jwt.strategy';
import { PermissionsGuard } from '../common/guards/permissions.guard';

describe('Phase 7: Milking Log, Feed & Ration Planning, and Unit Costing Integration Tests', () => {
  let module: TestingModule;
  let dataSource: DataSource;
  let milkingService: MilkingService;
  let feedService: FeedService;
  let costingService: CostingService;
  let permissionsGuard: PermissionsGuard;
  let reflector: Reflector;

  const testDbName = 'dairy_farm_test_db';
  const testIdsToCleanup: {
    milkingIds: string[];
    feedIds: string[];
    rationIds: string[];
    healthIds: string[];
    stockAdjustments: { itemId: string; qtyToAdd: number }[];
  } = {
    milkingIds: [],
    feedIds: [],
    rationIds: [],
    healthIds: [],
    stockAdjustments: [],
  };

  beforeAll(async () => {
    module = await Test.createTestingModule({
      imports: [
        TypeOrmModule.forRoot({
          type: 'mysql',
          host: process.env.DB_HOST || '127.0.0.1',
          port: parseInt(process.env.DB_PORT || '3306', 10),
          username: process.env.DB_USERNAME || 'root',
          password: process.env.DB_PASSWORD || '',
          database: testDbName,
          entities: [
            MilkingLogEntity,
            FeedEntryEntity,
            StockItemEntity,
            RationDefinitionEntity,
            RationItemEntity,
            AnimalEntity,
            HealthRecordEntity,
            UserEntity,
            RoleEntity,
            PermissionEntity,
            UserSessionEntity,
            AuditLogEntity,
          ],
          synchronize: false,
        }),
        TypeOrmModule.forFeature([
          MilkingLogEntity,
          FeedEntryEntity,
          StockItemEntity,
          RationDefinitionEntity,
          RationItemEntity,
          AnimalEntity,
          HealthRecordEntity,
          UserEntity,
          RoleEntity,
          PermissionEntity,
          UserSessionEntity,
          AuditLogEntity,
        ]),
        PassportModule.register({ defaultStrategy: 'jwt' }),
        JwtModule.register({
          secret: 'super_secret_development_jwt_key_min_32_chars_dairy',
          signOptions: { expiresIn: '1h' },
        }),
      ],
      controllers: [MilkingController, FeedController, CostingController],
      providers: [
        MilkingService,
        FeedService,
        CostingService,
        AuditService,
        UsersService,
        AuthService,
        JwtStrategy,
        PermissionsGuard,
        Reflector,
      ],
    }).compile();

    dataSource = module.get<DataSource>(DataSource);
    milkingService = module.get<MilkingService>(MilkingService);
    feedService = module.get<FeedService>(FeedService);
    costingService = module.get<CostingService>(CostingService);
    permissionsGuard = module.get<PermissionsGuard>(PermissionsGuard);
    reflector = module.get<Reflector>(Reflector);
  });

  afterAll(async () => {
    if (dataSource && dataSource.isInitialized) {
      if (testIdsToCleanup.milkingIds.length > 0) {
        await dataSource.query(
          `DELETE FROM milking_logs WHERE id IN (${testIdsToCleanup.milkingIds.map((id) => `'${id}'`).join(',')})`,
        );
      }
      if (testIdsToCleanup.feedIds.length > 0) {
        await dataSource.query(
          `DELETE FROM feed_entries WHERE id IN (${testIdsToCleanup.feedIds.map((id) => `'${id}'`).join(',')})`,
        );
      }
      if (testIdsToCleanup.rationIds.length > 0) {
        await dataSource.query(
          `DELETE FROM ration_items WHERE ration_id IN (${testIdsToCleanup.rationIds.map((id) => `'${id}'`).join(',')})`,
        );
        await dataSource.query(
          `DELETE FROM ration_definitions WHERE id IN (${testIdsToCleanup.rationIds.map((id) => `'${id}'`).join(',')})`,
        );
      }
      if (testIdsToCleanup.healthIds.length > 0) {
        await dataSource.query(
          `DELETE FROM health_records WHERE id IN (${testIdsToCleanup.healthIds.map((id) => `'${id}'`).join(',')})`,
        );
      }
      for (const adj of testIdsToCleanup.stockAdjustments) {
        await dataSource.query(
          `UPDATE stock_items SET current_stock = current_stock + ? WHERE id = ?`,
          [adj.qtyToAdd, adj.itemId],
        );
      }
      await dataSource.destroy();
    }
    await module.close();
  });

  describe('1. Milking Log Workflows & Duplicate Rules', () => {
    const testDate = '2026-10-25';

    it('should record an individual cow milking session with operator and ELIGIBLE disposition', async () => {
      const log = await milkingService.create(
        {
          animalId: 'c-01',
          recordDate: testDate,
          session: MilkingSession.MORNING,
          yieldLitres: 14.5,
          operatorId: 'usr-dev-admin',
          notes: 'Test morning milking session',
        },
        'usr-dev-admin',
      );

      testIdsToCleanup.milkingIds.push(log.id);

      expect(log).toBeDefined();
      expect(log.animal_id).toBe('c-01');
      expect(log.yield_litres).toBe(14.5);
      expect(log.session).toBe(MilkingSession.MORNING);
      expect(log.disposition).toBe(MilkDisposition.ELIGIBLE);
      expect(log.operator_name).toBe('Arjun Patel');
    });

    it('should REJECT duplicate milking session for the same cow, date, and shift with ConflictException (409)', async () => {
      await expect(
        milkingService.create(
          {
            animalId: 'c-01',
            recordDate: testDate,
            session: MilkingSession.MORNING,
            yieldLitres: 15.0,
            operatorId: 'usr-dev-admin',
          },
          'usr-dev-admin',
        ),
      ).rejects.toThrow(ConflictException);
    });

    it('should record group milking and reject duplicate shift for the same group', async () => {
      const groupLog = await milkingService.create(
        {
          groupName: 'Test High Yielders Herd',
          recordDate: testDate,
          session: MilkingSession.MORNING,
          yieldLitres: 125.0,
          operatorId: 'usr-dev-admin',
        },
        'usr-dev-admin',
      );

      testIdsToCleanup.milkingIds.push(groupLog.id);
      expect(groupLog.group_name).toBe('Test High Yielders Herd');
      expect(groupLog.yield_litres).toBe(125.0);

      // Duplicate shift for same group rejects
      await expect(
        milkingService.create(
          {
            groupName: 'Test High Yielders Herd',
            recordDate: testDate,
            session: MilkingSession.MORNING,
            yieldLitres: 130.0,
          },
          'usr-dev-admin',
        ),
      ).rejects.toThrow(ConflictException);
    });

    it('should enforce WITHHELD disposition if cow has active safety withdrawal', async () => {
      // Create active antibiotic withdrawal for cow c-03
      const withdrawalDate = '2026-10-30';
      const healthRecordId = uuidv4();
      await dataSource.query(
        `INSERT INTO health_records (id, animal_id, record_date, care_type, medicine_vaccine, prescribed_dose, diagnosis, withdrawal_until, notes)
         VALUES (?, 'c-03', '2026-10-24', 'TREATMENT', 'Ceftiofur 500mg', '10ml IM', 'Clinical mastitis', ?, 'Under withdrawal')`,
        [healthRecordId, withdrawalDate],
      );
      testIdsToCleanup.healthIds.push(healthRecordId);

      // Attempt to record milking for c-03 with ELIGIBLE disposition
      const log = await milkingService.create(
        {
          animalId: 'c-03',
          recordDate: testDate, // 2026-10-25 < withdrawalDate 2026-10-30
          session: MilkingSession.MORNING,
          yieldLitres: 11.0,
          disposition: MilkDisposition.ELIGIBLE,
          operatorId: 'usr-dev-admin',
        },
        'usr-dev-admin',
      );

      testIdsToCleanup.milkingIds.push(log.id);

      // Must be automatically forced to WITHHELD with reason
      expect(log.disposition).toBe(MilkDisposition.WITHHELD);
      expect(log.withheld_reason).toContain('Active safety withdrawal period until 2026-10-30');
    });

    it('should aggregate summary metrics accurately for date range', async () => {
      const summary = await milkingService.getSummary(testDate, testDate);
      expect(summary).toBeDefined();
      expect(summary.totalLitres).toBeGreaterThan(0);
      expect(summary.eligibleLitres).toBeGreaterThan(0);
      expect(summary.withheldLitres).toBeGreaterThanOrEqual(11.0);
    });
  });

  describe('2. Feed & Ration Planning Workflows & Calculations', () => {
    it('should issue feed consumption and deduct inventory balance', async () => {
      const stockItem = await dataSource.query(`SELECT current_stock, weighted_avg_price FROM stock_items WHERE id = 'stk-conc'`);
      const initialStock = parseFloat(stockItem[0].current_stock);
      const unitPrice = parseFloat(stockItem[0].weighted_avg_price);

      const entry = await feedService.recordFeedConsumption(
        {
          animalId: 'c-01',
          recordDate: '2026-10-25',
          stockItemId: 'stk-conc',
          quantityKg: 7.0,
          feedType: FeedType.CONCENTRATE,
          shift: FeedShift.MORNING,
          notes: 'Morning ration issue',
        },
        'usr-dev-admin',
      );

      testIdsToCleanup.feedIds.push(entry.id);
      testIdsToCleanup.stockAdjustments.push({ itemId: 'stk-conc', qtyToAdd: 7.0 });

      expect(entry).toBeDefined();
      expect(entry.quantity_kg).toBe(7.0);
      expect(entry.unit_cost).toBe(unitPrice);
      expect(entry.total_cost).toBe(parseFloat((7.0 * unitPrice).toFixed(2)));

      // Verify stock was deducted
      const updatedStock = await dataSource.query(`SELECT current_stock FROM stock_items WHERE id = 'stk-conc'`);
      expect(parseFloat(updatedStock[0].current_stock)).toBe(parseFloat((initialStock - 7.0).toFixed(2)));
    });

    it('should calculate milk-linked target concentrate using approved formula min(1 + 0.4 * Yield, 8)', async () => {
      const target = await feedService.calculateConcentrateTarget('c-01');
      expect(target).toBeDefined();
      expect(target.animalId).toBe('c-01');
      expect(target.feedBaseKg).toBe(1.0);
      expect(target.feedRatePerLitre).toBe(0.4);
      expect(target.feedMaxCapKg).toBe(8.0);
      expect(target.targetConcentrateKg).toBeGreaterThanOrEqual(1.0);
      expect(target.targetConcentrateKg).toBeLessThanOrEqual(8.0);
    });

    it('should create a custom ration recipe and reconcile total and unit costs with known values', async () => {
      const testRationCode = 'TEST-RAT-' + Date.now();
      const created = await feedService.createRation(
        {
          name: 'Integration Test Balanced TMR',
          code: testRationCode,
          targetStage: TargetAnimalStage.LACTATING,
          description: 'Standard test diet',
          items: [
            { stockItemId: 'stk-conc', quantityKg: 6.0 }, // 6 * 24.50 = 147.00
            { stockItemId: 'stk-green', quantityKg: 20.0 }, // 20 * 3.50 = 70.00
            { stockItemId: 'stk-dry', quantityKg: 5.0 }, // 5 * 6.00 = 30.00
          ],
        },
        'usr-dev-admin',
      );

      testIdsToCleanup.rationIds.push(created.id);

      const retrieved = await feedService.findRationById(created.id);
      expect(retrieved).toBeDefined();
      expect(retrieved.items?.length).toBe(3);

      // Expected Reconciliation:
      // Total Qty = 6.0 + 20.0 + 5.0 = 31.00 kg
      // Total Cost = 147.00 + 70.00 + 30.00 = 247.00 INR
      // Unit Cost per kg = 247.00 / 31.00 = 7.97 INR/kg
      expect(retrieved.totalQuantityKg).toBe(31.0);
      expect(retrieved.totalCost).toBe(247.0);
      expect(retrieved.unitCostPerKg).toBe(7.97);
    });
  });

  describe('3. Daily Unit Costing Reconciliation (REQ-YD-07)', () => {
    it('should compute daily farm milk cost per litre and component breakdown for date with eligible milk', async () => {
      // Oct 11, 2026 has seeded milk and operational costs
      const result = await costingService.getDailyMilkCosting({ date: '2026-10-11' });

      expect(result).toBeDefined();
      expect(result.date).toBe('2026-10-11');
      expect(result.status).toBe('COMPLETE');
      expect(result.eligibleMilkLitres).toBeGreaterThan(0);
      expect(result.totalDailyFarmCost).toBeGreaterThan(0);
      expect(result.costPerLitre).toBeDefined();

      // Reconciliation mathematical verification:
      // Cost per Litre = Total Daily Farm Cost / Eligible Milk Litres
      const calculatedCpl = parseFloat((result.totalDailyFarmCost / result.eligibleMilkLitres).toFixed(2));
      expect(result.costPerLitre).toBeCloseTo(calculatedCpl, 2);

      // Verify breakdown items
      expect(result.breakdown).toBeDefined();
      expect(result.breakdown.dailySalaries).toBeGreaterThan(0);
      expect(result.breakdown.electricityCost).toBeGreaterThan(0);
    });

    it('should reconcile ZERO eligible milk date with INCOMPLETE status, null costPerLitre, and clear warning', async () => {
      const futureDate = '2029-05-01';
      const result = await costingService.getDailyMilkCosting({ date: futureDate });

      expect(result).toBeDefined();
      expect(result.date).toBe(futureDate);
      expect(result.status).toBe('INCOMPLETE');
      expect(result.costPerLitre).toBeNull();
      expect(result.eligibleMilkLitres).toBe(0);
      expect(result.warningMessage).toContain('No eligible milk recorded for this date. Cost per litre cannot be computed.');
    });
  });

  describe('4. RBAC Server-Side Permissions Security Gate', () => {
    it('should allow FARM_OWNER (all permissions) to access costing, milking, and feed', async () => {
      const mockExecutionContext: any = {
        getHandler: () => ({}),
        getClass: () => ({}),
        switchToHttp: () => ({
          getRequest: () => ({
            user: {
              id: 'usr-dev-admin',
              roles: ['FARM_OWNER'],
              permissions: ['milking:read', 'milking:write', 'feed:read', 'feed:write', 'finance:read'],
            },
          }),
        }),
      };

      jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue(['finance:read']);
      const canAccessCosting = await permissionsGuard.canActivate(mockExecutionContext);
      expect(canAccessCosting).toBe(true);

      jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue(['milking:write']);
      const canWriteMilking = await permissionsGuard.canActivate(mockExecutionContext);
      expect(canWriteMilking).toBe(true);

      jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue(['feed:write']);
      const canWriteFeed = await permissionsGuard.canActivate(mockExecutionContext);
      expect(canWriteFeed).toBe(true);
    });

    it('should REJECT MILKING_STAFF from viewing unit costing (finance:read) with ForbiddenException (403)', () => {
      const mockExecutionContext: any = {
        getHandler: () => ({}),
        getClass: () => ({}),
        switchToHttp: () => ({
          getRequest: () => ({
            user: {
              id: 'usr-milking-staff',
              roles: ['MILKING_STAFF'],
              permissions: ['milking:read', 'milking:write'],
            },
          }),
        }),
      };

      jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue(['finance:read']);
      expect(() => permissionsGuard.canActivate(mockExecutionContext)).toThrow(ForbiddenException);
    });

    it('should REJECT STOREKEEPER from recording milking logs (milking:write) with ForbiddenException (403)', () => {
      const mockExecutionContext: any = {
        getHandler: () => ({}),
        getClass: () => ({}),
        switchToHttp: () => ({
          getRequest: () => ({
            user: {
              id: 'usr-storekeeper',
              roles: ['STOREKEEPER'],
              permissions: ['inventory:read', 'inventory:write'],
            },
          }),
        }),
      };

      jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue(['milking:write']);
      expect(() => permissionsGuard.canActivate(mockExecutionContext)).toThrow(ForbiddenException);
    });
  });
});
