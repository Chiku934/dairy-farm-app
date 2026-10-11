import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe, ForbiddenException } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule } from '@nestjs/config';
import { DataSource } from 'typeorm';
import { Reflector } from '@nestjs/core';

import { getDatabaseConfig } from '../modules/database/database.config';
import { BmcModule } from '../modules/bmc/bmc.module';
import { ProductionModule } from '../modules/production/production.module';
import { BmcService } from '../modules/bmc/bmc.service';
import { ProductionService } from '../modules/production/production.service';
import {
  BmcIntakeLog,
  MilkIntakeSource,
  IntakeShift,
  Decision,
} from '../modules/bmc/entities/bmc-intake-log.entity';
import {
  ProductionBatch,
  ProductType,
  UnitOfMeasure,
  QualityReleaseStatus,
  BatchStatus,
} from '../modules/production/entities/production-batch.entity';
import { StockItemEntity } from '../modules/feed/entities/stock-item.entity';
import { PermissionsGuard } from '../common/guards/permissions.guard';
import { AuthenticatedUser } from '../common/decorators/current-user.decorator';

describe('Phase 8: BMC & Milk Intake and Production Batches Integration Tests', () => {
  let app: INestApplication;
  let dataSource: DataSource;
  let bmcService: BmcService;
  let productionService: ProductionService;
  let permissionsGuard: PermissionsGuard;

  const mockAdminUser: AuthenticatedUser = {
    userId: 'usr-dev-admin',
    email: 'admin@dairyfarm.com',
    fullName: 'Dev Admin',
    roles: ['FARM_OWNER'],
    permissions: ['*'],
  };

  const mockOperatorUser: AuthenticatedUser = {
    userId: 'usr-dev-operator',
    email: 'operator@dairyfarm.com',
    fullName: 'Ramesh Patel',
    roles: ['BMC_OPERATOR', 'PRODUCTION_OPERATOR'],
    permissions: ['bmc:read', 'bmc:write', 'production:read', 'production:write'],
  };

  const mockUnauthorizedUser: AuthenticatedUser = {
    userId: 'usr-dev-worker',
    email: 'worker@dairyfarm.com',
    fullName: 'Field Worker',
    roles: ['ANIMAL_CARE'],
    permissions: ['milking:read'],
  };

  beforeAll(async () => {
    const moduleRef: TestingModule = await Test.createTestingModule({
      imports: [
        ConfigModule.forRoot({ isGlobal: true }),
        TypeOrmModule.forRootAsync({
          useFactory: () => getDatabaseConfig(),
        }),
        BmcModule,
        ProductionModule,
      ],
      providers: [PermissionsGuard],
    }).compile();

    app = moduleRef.createNestApplication();
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        transform: true,
        forbidNonWhitelisted: true,
      }),
    );
    await app.init();

    dataSource = moduleRef.get<DataSource>(DataSource);
    bmcService = moduleRef.get<BmcService>(BmcService);
    productionService = moduleRef.get<ProductionService>(ProductionService);
    permissionsGuard = moduleRef.get<PermissionsGuard>(PermissionsGuard);
  });

  afterAll(async () => {
    if (app) {
      await app.close();
    }
  });

  describe('1. BMC Milk Intake & QC Acceptance', () => {
    const testDate = '2026-10-18';

    beforeEach(async () => {
      // Clean up test date records
      await dataSource.query(
        `DELETE FROM production_batch_intakes WHERE intake_id IN (SELECT id FROM bmc_intake_logs WHERE record_date = '${testDate}')`,
      );
      await dataSource.query(`DELETE FROM bmc_intake_logs WHERE record_date = '${testDate}'`);
      await dataSource.query(`DELETE FROM production_batches WHERE record_date = '${testDate}'`);
    });

    it('records an ACCEPTED Farm intake and increments live BMC tank balance', async () => {
      const initialBalance = await bmcService.getTankBalance();

      const created = await bmcService.createIntake(
        {
          recordDate: testDate,
          shift: IntakeShift.AM,
          source: MilkIntakeSource.FARM,
          quantityLitres: 120.50,
          decision: Decision.ACCEPTED,
          temperatureC: 4.2,
          fatPercentage: 4.15,
          snfPercentage: 8.65,
          clr: 29.0,
          ph: 6.68,
          notes: 'Standard morning farm collection',
        },
        mockOperatorUser,
      );

      expect(created.id).toBeDefined();
      expect(created.batchNumber).toContain('INT-FRM');
      expect(Number(created.quantityLitres)).toBe(120.50);
      expect(created.decision).toBe(Decision.ACCEPTED);
      expect(created.operatorName).toBe('Ramesh Patel');

      const updatedBalance = await bmcService.getTankBalance();
      expect(updatedBalance.currentBalanceLitres).toBeCloseTo(
        initialBalance.currentBalanceLitres + 120.50,
        2,
      );
    });

    it('rejects duplicate Farm intake on the same date and shift with 409 Conflict', async () => {
      await bmcService.createIntake(
        {
          recordDate: testDate,
          shift: IntakeShift.AM,
          source: MilkIntakeSource.FARM,
          quantityLitres: 100.0,
          decision: Decision.ACCEPTED,
        },
        mockOperatorUser,
      );

      await expect(
        bmcService.createIntake(
          {
            recordDate: testDate,
            shift: IntakeShift.AM,
            source: MilkIntakeSource.FARM,
            quantityLitres: 80.0,
            decision: Decision.ACCEPTED,
          },
          mockOperatorUser,
        ),
      ).rejects.toThrow();
    });

    it('records a REJECTED External intake without incrementing live BMC tank balance', async () => {
      const initialBalance = await bmcService.getTankBalance();

      const rejected = await bmcService.createIntake(
        {
          recordDate: testDate,
          shift: IntakeShift.PM,
          source: MilkIntakeSource.EXTERNAL,
          supplierRoute: 'Northern Route B',
          quantityLitres: 65.0,
          externalTotalCost: 2275.0,
          decision: Decision.REJECTED,
          rejectionReason: 'High temperature (14.5C) and clot-on-boiling failure',
          temperatureC: 14.5,
          fatPercentage: 3.10,
          snfPercentage: 7.60,
          ph: 6.15,
        },
        mockOperatorUser,
      );

      expect(rejected.id).toBeDefined();
      expect(rejected.decision).toBe(Decision.REJECTED);
      expect(rejected.rejectionReason).toContain('High temperature');

      const updatedBalance = await bmcService.getTankBalance();
      // Tank balance must remain identical
      expect(updatedBalance.currentBalanceLitres).toBe(initialBalance.currentBalanceLitres);
    });

    it('enforces rejection reason when milk intake is marked REJECTED', async () => {
      await expect(
        bmcService.createIntake(
          {
            recordDate: testDate,
            shift: IntakeShift.AM,
            source: MilkIntakeSource.EXTERNAL,
            supplierRoute: 'Route C',
            quantityLitres: 50.0,
            decision: Decision.REJECTED,
            rejectionReason: '',
          },
          mockOperatorUser,
        ),
      ).rejects.toThrow();
    });
  });

  describe('2. Production Batches, Conversion Yield & Stock Deduction', () => {
    const testDate = '2026-10-18';
    let acceptedIntake: BmcIntakeLog;

    beforeEach(async () => {
      await dataSource.query(
        `DELETE FROM production_batch_intakes WHERE intake_id IN (SELECT id FROM bmc_intake_logs WHERE record_date = '${testDate}')`,
      );
      await dataSource.query(`DELETE FROM bmc_intake_logs WHERE record_date = '${testDate}'`);
      await dataSource.query(`DELETE FROM production_batches WHERE record_date = '${testDate}'`);

      // Seed 200 L accepted intake on test date to ensure sufficient BMC milk
      acceptedIntake = await bmcService.createIntake(
        {
          recordDate: testDate,
          shift: IntakeShift.AM,
          source: MilkIntakeSource.FARM,
          quantityLitres: 200.0,
          decision: Decision.ACCEPTED,
        },
        mockAdminUser,
      );
    });

    it('creates a PANEER batch with approved yield (18%) and decrements BMC and LPG stock', async () => {
      // Ensure LPG stock exists
      let lpgItem = await dataSource.getRepository(StockItemEntity).findOne({
        where: { id: 'item-04' },
      });
      if (!lpgItem) {
        lpgItem = await dataSource.getRepository(StockItemEntity).save({
          id: 'item-04',
          name: 'LPG 19kg cylinder',
          used_by: 'PRODUCTION' as any,
          category: 'LPG' as any,
          unit: 'kg',
          current_stock: 38.0,
          weighted_avg_price: 110.0,
          reorder_level: 19.0,
        });
      }
      const initialLpg = Number(lpgItem.current_stock);
      const initialBmcBalance = (await bmcService.getTankBalance()).currentBalanceLitres;

      const batch = await productionService.createBatch(
        {
          recordDate: testDate,
          shift: IntakeShift.AM,
          productType: ProductType.PANEER,
          bmcMilkConsumedL: 100.0,
          finishedQuantity: 18.0, // 18% yield
          unitOfMeasure: UnitOfMeasure.KG,
          lpgUsedKg: 2.0,
          lpgStockItemId: 'item-04',
          byproductQuantityKg: 80.0,
          expiryDate: '2026-10-25',
          qualityRelease: QualityReleaseStatus.HOLD,
          linkedIntakes: [{ intakeId: acceptedIntake.id, litresUsed: 100.0 }],
        },
        mockOperatorUser,
      );

      expect(batch.id).toBeDefined();
      expect(batch.batchNumber).toContain('BATCH-PAN');
      expect(Number(batch.yieldPercentage)).toBe(18.0);
      expect(batch.qualityRelease).toBe(QualityReleaseStatus.HOLD);

      // Verify BMC tank balance decremented by 100 L
      const updatedBmcBalance = (await bmcService.getTankBalance()).currentBalanceLitres;
      expect(updatedBmcBalance).toBeCloseTo(initialBmcBalance - 100.0, 2);

      // Verify LPG stock decremented by 2.0 kg
      const updatedLpgItem = await dataSource.getRepository(StockItemEntity).findOne({
        where: { id: 'item-04' },
      });
      expect(Number(updatedLpgItem!.current_stock)).toBeCloseTo(initialLpg - 2.0, 2);
    });

    it('rejects batch creation exceeding physical maximum yield cap (Paneer > 25%)', async () => {
      await expect(
        productionService.createBatch(
          {
            recordDate: testDate,
            shift: IntakeShift.AM,
            productType: ProductType.PANEER,
            bmcMilkConsumedL: 100.0,
            finishedQuantity: 35.0, // 35% yield (Max cap is 25%)
            unitOfMeasure: UnitOfMeasure.KG,
            expiryDate: '2026-10-25',
          },
          mockOperatorUser,
        ),
      ).rejects.toThrow();
    });

    it('rejects batch creation when requested milk exceeds live BMC tank balance', async () => {
      const balance = (await bmcService.getTankBalance()).currentBalanceLitres;

      await expect(
        productionService.createBatch(
          {
            recordDate: testDate,
            shift: IntakeShift.AM,
            productType: ProductType.MILK,
            bmcMilkConsumedL: balance + 500.0, // Exceeds balance
            finishedQuantity: balance + 490.0,
            unitOfMeasure: UnitOfMeasure.LITRE,
            expiryDate: '2026-10-21',
          },
          mockOperatorUser,
        ),
      ).rejects.toThrow();
    });

    it('rejects batch creation when requested LPG exceeds available stock', async () => {
      const lpgItem = await dataSource.getRepository(StockItemEntity).findOne({
        where: { id: 'item-04' },
      });
      const stock = lpgItem ? Number(lpgItem.current_stock) : 0;

      await expect(
        productionService.createBatch(
          {
            recordDate: testDate,
            shift: IntakeShift.AM,
            productType: ProductType.KHOYA,
            bmcMilkConsumedL: 50.0,
            finishedQuantity: 10.0,
            unitOfMeasure: UnitOfMeasure.KG,
            lpgUsedKg: stock + 100.0, // Exceeds stock
            lpgStockItemId: 'item-04',
            expiryDate: '2026-10-25',
          },
          mockOperatorUser,
        ),
      ).rejects.toThrow();
    });
  });

  describe('3. Traceability Lineage & Quality Status Workflow', () => {
    const testDate = '2026-10-18';
    let batchId: string;

    beforeAll(async () => {
      // Create dedicated intake and batch for traceability
      const intake = await bmcService.createIntake(
        {
          recordDate: testDate,
          shift: IntakeShift.AM,
          source: MilkIntakeSource.EXTERNAL,
          supplierRoute: 'Dandiri Route 1',
          quantityLitres: 150.0,
          decision: Decision.ACCEPTED,
          temperatureC: 4.1,
          fatPercentage: 4.30,
          snfPercentage: 8.70,
          clr: 29.5,
          ph: 6.70,
        },
        mockOperatorUser,
      );

      const batch = await productionService.createBatch(
        {
          recordDate: testDate,
          shift: IntakeShift.AM,
          productType: ProductType.DAHI,
          bmcMilkConsumedL: 80.0,
          finishedQuantity: 78.4, // 98% yield
          unitOfMeasure: UnitOfMeasure.KG,
          expiryDate: '2026-10-24',
          qualityRelease: QualityReleaseStatus.HOLD,
          linkedIntakes: [{ intakeId: intake.id, litresUsed: 80.0 }],
        },
        mockOperatorUser,
      );

      batchId = batch.id;
    });

    it('returns complete end-to-end lineage from contributing intake lot to finished output', async () => {
      const trace = await productionService.getTraceability(batchId);

      expect(trace.batchId).toBe(batchId);
      expect(trace.productType).toBe(ProductType.DAHI);
      expect(trace.finishedQuantity).toBe(78.4);
      expect(trace.yieldPercentage).toBe(98.0);
      expect(trace.lineage.totalIntakeLotsContributing).toBe(1);

      const intakeLot = trace.lineage.intakeLots[0];
      expect(intakeLot.source).toBe(MilkIntakeSource.EXTERNAL);
      expect(intakeLot.supplierRoute).toBe('Dandiri Route 1');
      expect(intakeLot.litresUsedInBatch).toBe(80.0);
      expect(Number(intakeLot.qualityMetrics.fatPercentage)).toBe(4.30);
      expect(Number(intakeLot.qualityMetrics.snfPercentage)).toBe(8.70);
    });

    it('updates quality release status from HOLD to APPROVED with audit notes', async () => {
      const updated = await productionService.updateReleaseStatus(batchId, {
        qualityRelease: QualityReleaseStatus.APPROVED,
        status: BatchStatus.COMPLETED,
        notes: 'Microbiological culture test passed; cleared for dispatch',
      });

      expect(updated.qualityRelease).toBe(QualityReleaseStatus.APPROVED);
      expect(updated.status).toBe(BatchStatus.COMPLETED);
      expect(updated.notes).toContain('cleared for dispatch');
    });
  });

  describe('4. API Role-Based Authorization Guard Checks', () => {
    it('allows BMC_OPERATOR to access bmc:write endpoints', () => {
      const mockContext = {
        getHandler: () => ({}),
        getClass: () => ({}),
        switchToHttp: () => ({
          getRequest: () => ({ user: mockOperatorUser }),
        }),
      } as any;

      const reflector = new Reflector();
      jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue(['bmc:write']);
      const guard = new PermissionsGuard(reflector);

      expect(guard.canActivate(mockContext)).toBe(true);
    });

    it('blocks ANIMAL_CARE from accessing production:write endpoints', () => {
      const mockContext = {
        getHandler: () => ({}),
        getClass: () => ({}),
        switchToHttp: () => ({
          getRequest: () => ({ user: mockUnauthorizedUser }),
        }),
      } as any;

      const reflector = new Reflector();
      jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue(['production:write']);
      const guard = new PermissionsGuard(reflector);

      expect(() => guard.canActivate(mockContext)).toThrow(ForbiddenException);
    });

    it('allows FARM_OWNER super-admin wildcard access to all BMC and Production endpoints', () => {
      const mockContext = {
        getHandler: () => ({}),
        getClass: () => ({}),
        switchToHttp: () => ({
          getRequest: () => ({ user: mockAdminUser }),
        }),
      } as any;

      const reflector = new Reflector();
      jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue(['production:write', 'bmc:write']);
      const guard = new PermissionsGuard(reflector);

      expect(guard.canActivate(mockContext)).toBe(true);
    });
  });
});
