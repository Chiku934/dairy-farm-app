import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe, BadRequestException, ConflictException } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule } from '@nestjs/config';
import { DataSource } from 'typeorm';

import { getDatabaseConfig } from '../modules/database/database.config';
import { PackagingModule } from '../modules/packaging/packaging.module';
import { QualityModule } from '../modules/quality/quality.module';
import { MaterialsModule } from '../modules/materials/materials.module';
import { ElectricityModule } from '../modules/electricity/electricity.module';
import { ProductionModule } from '../modules/production/production.module';
import { BmcModule } from '../modules/bmc/bmc.module';

import { PackagingService } from '../modules/packaging/packaging.service';
import { QualityService } from '../modules/quality/quality.service';
import { MaterialsService } from '../modules/materials/materials.service';
import { ElectricityService } from '../modules/electricity/electricity.service';
import { ProductionService } from '../modules/production/production.service';
import { BmcService } from '../modules/bmc/bmc.service';

import { StockItemEntity } from '../modules/feed/entities/stock-item.entity';
import { PackagingRunEntity } from '../modules/packaging/entities/packaging-run.entity';
import { QualityRecordEntity } from '../modules/quality/entities/quality-record.entity';
import { MaterialIssueEntity } from '../modules/materials/entities/material-issue.entity';
import { ElectricityReadingEntity } from '../modules/electricity/entities/electricity-reading.entity';

import {
  Department,
  QualityTargetType,
  QualityDecision,
  ProductType,
  IntakeShift,
  MilkIntakeSource,
  Decision,
} from '@dairy-farm/api-contracts';
import { UnitOfMeasure } from '../modules/production/entities/production-batch.entity';
import { AuthenticatedUser } from '../common/decorators/current-user.decorator';

describe('Phase 9: Packaging, Quality Records, Material Issues & Electricity Integration Tests', () => {
  let app: INestApplication;
  let dataSource: DataSource;

  let packagingService: PackagingService;
  let qualityService: QualityService;
  let materialsService: MaterialsService;
  let electricityService: ElectricityService;
  let productionService: ProductionService;
  let bmcService: BmcService;

  const mockAdminUser: AuthenticatedUser = {
    userId: 'usr-phase9-admin',
    email: 'admin@dairyfarm.com',
    fullName: 'Farm Super Admin',
    roles: ['FARM_OWNER'],
    permissions: ['*'],
  };

  const testDate = '2026-10-18';
  let testBatchId: string;
  let testIntakeId: string;
  const testPackagingItemId = 'item-pkg-test-01';
  const testMaterialItemId = 'item-mat-test-01';

  beforeAll(async () => {
    const moduleRef: TestingModule = await Test.createTestingModule({
      imports: [
        ConfigModule.forRoot({ isGlobal: true }),
        TypeOrmModule.forRootAsync({
          useFactory: () => getDatabaseConfig(),
        }),
        PackagingModule,
        QualityModule,
        MaterialsModule,
        ElectricityModule,
        ProductionModule,
        BmcModule,
      ],
    }).compile();

    app = moduleRef.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({ transform: true, whitelist: true }));
    await app.init();

    dataSource = moduleRef.get<DataSource>(DataSource);
    packagingService = moduleRef.get<PackagingService>(PackagingService);
    qualityService = moduleRef.get<QualityService>(QualityService);
    materialsService = moduleRef.get<MaterialsService>(MaterialsService);
    electricityService = moduleRef.get<ElectricityService>(ElectricityService);
    productionService = moduleRef.get<ProductionService>(ProductionService);
    bmcService = moduleRef.get<BmcService>(BmcService);

    // Setup test stock items
    await dataSource.query(
      `INSERT INTO stock_items (id, name, used_by, category, unit, current_stock, weighted_avg_price, reorder_level)
       VALUES (?, ?, 'PRODUCTION', 'PACKAGING', 'units', 100.00, 2.50, 20.00)
       ON DUPLICATE KEY UPDATE current_stock = 100.00, weighted_avg_price = 2.50`,
      [testPackagingItemId, 'Test Milk Pouch 500ml'],
    );

    await dataSource.query(
      `INSERT INTO stock_items (id, name, used_by, category, unit, current_stock, weighted_avg_price, reorder_level)
       VALUES (?, ?, 'PRODUCTION', 'CLEANING', 'kg', 50.00, 45.00, 10.00)
       ON DUPLICATE KEY UPDATE current_stock = 50.00, weighted_avg_price = 45.00`,
      [testMaterialItemId, 'Test Caustic Soda Cleaning'],
    );

    // Create a base milk intake and production batch for linking
    const intake = await bmcService.createIntake(
      {
        source: MilkIntakeSource.EXTERNAL,
        supplierRoute: 'Phase 9 Test Supplier Route',
        recordDate: testDate,
        shift: IntakeShift.AM,
        quantityLitres: 200.0,
        fatPercentage: 4.2,
        snfPercentage: 8.8,
        clr: 30.0,
        ph: 6.65,
        temperatureC: 4.0,
        decision: Decision.ACCEPTED,
      },
      mockAdminUser,
    );
    testIntakeId = intake.id;

    const batch = await productionService.createBatch(
      {
        recordDate: testDate,
        shift: IntakeShift.AM,
        productType: ProductType.MILK,
        bmcMilkConsumedL: 100.0,
        finishedQuantity: 99.0,
        unitOfMeasure: UnitOfMeasure.LITRE,
        expiryDate: '2026-10-21',
        linkedIntakes: [{ intakeId: testIntakeId, litresUsed: 100.0 }],
      },
      mockAdminUser,
    );
    testBatchId = batch.id;
  });

  afterAll(async () => {
    // Clean up test data
    if (dataSource && dataSource.isInitialized) {
      await dataSource.query(`DELETE FROM packaging_runs WHERE record_date = ?`, [testDate]);
      await dataSource.query(`DELETE FROM quality_records WHERE record_date = ?`, [testDate]);
      await dataSource.query(`DELETE FROM material_issues WHERE record_date = ?`, [testDate]);
      await dataSource.query(`DELETE FROM electricity_readings WHERE record_date = ?`, [testDate]);
      await dataSource.query(`DELETE FROM stock_ledger_entries WHERE record_date = ?`, [testDate]);
      await dataSource.query(`DELETE FROM production_batch_intakes WHERE production_batch_id = ?`, [testBatchId]);
      await dataSource.query(`DELETE FROM production_batches WHERE id = ?`, [testBatchId]);
      await dataSource.query(`DELETE FROM bmc_intake_logs WHERE id = ?`, [testIntakeId]);
      await dataSource.query(`DELETE FROM stock_items WHERE id IN (?, ?)`, [
        testPackagingItemId,
        testMaterialItemId,
      ]);
    }
    await app.close();
  });

  describe('1. Packaging Runs', () => {
    it('successfully creates packaging run, deducts batch volume, decrements packaging stock, and writes stock ledger entry', async () => {
      // Packaging 40 packs of 1.0 L milk (total 40 L) with 2 scrap units -> 42 units consumed
      const run = await packagingService.createRun(
        {
          recordDate: testDate,
          productionBatchId: testBatchId,
          packSize: 1.0,
          packUnit: 'LITRE',
          numberOfPacks: 40,
          packagingItemId: testPackagingItemId,
          scrapUnits: 2,
          notes: 'Morning pasteurized milk packaging run',
        },
        mockAdminUser,
      );

      expect(run).toBeDefined();
      expect(Number(run.total_packaged_quantity)).toBe(40.0);
      expect(Number(run.material_consumed)).toBe(42.0); // 40 + 2 scrap

      // Verify packaging stock was decremented from 100.00 to 58.00
      const [item] = await dataSource.query(`SELECT current_stock FROM stock_items WHERE id = ?`, [
        testPackagingItemId,
      ]);
      expect(Number(item.current_stock)).toBe(58.0);

      // Verify stock ledger entry was recorded
      const [ledger] = await dataSource.query(
        `SELECT * FROM stock_ledger_entries WHERE reference_id = ? AND transaction_type = 'PACKAGING_CONSUMPTION'`,
        [run.id],
      );
      expect(ledger).toBeDefined();
      expect(Number(ledger.quantity_change)).toBe(-42.0);
      expect(Number(ledger.balance_after)).toBe(58.0);
    });

    it('rejects packaging run when total packaged quantity exceeds remaining batch output', async () => {
      // Total batch output is 99.0 L, 40.0 L already packaged, remaining is 59.0 L
      // Attempting to package 70 packs of 1.0 L (70.0 L) must fail
      await expect(
        packagingService.createRun(
          {
            recordDate: testDate,
            productionBatchId: testBatchId,
            packSize: 1.0,
            packUnit: 'LITRE',
            numberOfPacks: 70,
            packagingItemId: testPackagingItemId,
          },
          mockAdminUser,
        ),
      ).rejects.toThrow(BadRequestException);
    });

    it('rolls back transaction on insufficient packaging material stock', async () => {
      // Current stock is 58.00. Attempting to consume 80 units
      const [stockBefore] = await dataSource.query(
        `SELECT current_stock FROM stock_items WHERE id = ?`,
        [testPackagingItemId],
      );

      await expect(
        packagingService.createRun(
          {
            recordDate: testDate,
            productionBatchId: testBatchId,
            packSize: 0.5,
            packUnit: 'LITRE',
            numberOfPacks: 80, // Needs 80 pouches, but only 58 available
            packagingItemId: testPackagingItemId,
          },
          mockAdminUser,
        ),
      ).rejects.toThrow(BadRequestException);

      // Verify stock remained untouched due to rollback
      const [stockAfter] = await dataSource.query(
        `SELECT current_stock FROM stock_items WHERE id = ?`,
        [testPackagingItemId],
      );
      expect(Number(stockAfter.current_stock)).toBe(Number(stockBefore.current_stock));
    });
  });

  describe('2. Quality Records', () => {
    it('creates a quality record with verified parameters for a production batch', async () => {
      const record = await qualityService.createRecord(
        {
          recordDate: testDate,
          targetType: QualityTargetType.PRODUCTION_BATCH,
          targetId: testBatchId,
          fatPercentage: 4.1,
          snfPercentage: 8.75,
          clr: 30.5,
          ph: 6.68,
          temperatureC: 4.5,
          decision: QualityDecision.APPROVED,
          testedBy: 'QC Officer Sharma',
          notes: 'Standard quality release verified',
        },
        mockAdminUser,
      );

      expect(record).toBeDefined();
      expect(record.decision).toBe(QualityDecision.APPROVED);
      expect(Number(record.fat_percentage)).toBe(4.1);
      expect(Number(record.ph)).toBe(6.68);
    });

    it('rejects impossible quality readings outside physical boundaries', async () => {
      // Impossible negative fat
      await expect(
        qualityService.createRecord(
          {
            recordDate: testDate,
            targetType: QualityTargetType.PRODUCTION_BATCH,
            targetId: testBatchId,
            fatPercentage: -2.5,
            decision: QualityDecision.REJECTED,
          },
          mockAdminUser,
        ),
      ).rejects.toThrow(BadRequestException);

      // Impossible pH > 14
      await expect(
        qualityService.createRecord(
          {
            recordDate: testDate,
            targetType: QualityTargetType.PRODUCTION_BATCH,
            targetId: testBatchId,
            ph: 15.2,
            decision: QualityDecision.REJECTED,
          },
          mockAdminUser,
        ),
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe('3. Material Issues', () => {
    it('successfully issues material, updates stock balance atomically, and writes stock ledger', async () => {
      // Issue 15 kg Caustic Soda to PRODUCTION (stock starts at 50 kg @ ₹45.00/kg)
      const issue = await materialsService.createIssue(
        {
          recordDate: testDate,
          department: Department.PRODUCTION,
          stockItemId: testMaterialItemId,
          quantity: 15.0,
          productionBatchId: testBatchId,
          issuedTo: 'CIP Operator Suresh',
          notes: 'Pasteurizer line CIP sanitization',
        },
        mockAdminUser,
      );

      expect(issue).toBeDefined();
      expect(Number(issue.quantity)).toBe(15.0);
      expect(Number(issue.unit_cost)).toBe(45.0);
      expect(Number(issue.total_cost)).toBe(675.0); // 15 * 45

      // Verify stock was decremented to 35.00
      const [item] = await dataSource.query(`SELECT current_stock FROM stock_items WHERE id = ?`, [
        testMaterialItemId,
      ]);
      expect(Number(item.current_stock)).toBe(35.0);

      // Verify stock ledger entry
      const [ledger] = await dataSource.query(
        `SELECT * FROM stock_ledger_entries WHERE reference_id = ? AND transaction_type = 'ISSUE'`,
        [issue.id],
      );
      expect(ledger).toBeDefined();
      expect(Number(ledger.quantity_change)).toBe(-15.0);
      expect(Number(ledger.balance_after)).toBe(35.0);
    });

    it('rolls back material issue when requested quantity exceeds available stock', async () => {
      // Available stock is 35.0. Attempting to issue 40.0 kg
      await expect(
        materialsService.createIssue(
          {
            recordDate: testDate,
            department: Department.PRODUCTION,
            stockItemId: testMaterialItemId,
            quantity: 40.0,
            issuedTo: 'CIP Operator',
          },
          mockAdminUser,
        ),
      ).rejects.toThrow(BadRequestException);

      // Verify stock remains untouched at 35.00
      const [item] = await dataSource.query(`SELECT current_stock FROM stock_items WHERE id = ?`, [
        testMaterialItemId,
      ]);
      expect(Number(item.current_stock)).toBe(35.0);
    });
  });

  describe('4. Electricity Readings', () => {
    it('successfully records electricity reading using opening and closing meter counters', async () => {
      const reading = await electricityService.createReading(
        {
          recordDate: testDate,
          department: Department.PRODUCTION,
          openingReadingKwh: 12450.0,
          closingReadingKwh: 12625.0, // 175 kWh consumed
          tariffRate: 1.4,
          notes: 'Main processing dairy hall meter',
        },
        mockAdminUser,
      );

      expect(reading).toBeDefined();
      expect(Number(reading.units_kwh)).toBe(175.0);
      expect(Number(reading.tariff_rate)).toBe(1.4);
      expect(Number(reading.total_cost)).toBe(245.0); // 175 * 1.4 = 245.00
    });

    it('rejects impossible meter reading where closing is less than opening (meter rollback)', async () => {
      await expect(
        electricityService.createReading(
          {
            recordDate: testDate,
            department: Department.FARM,
            openingReadingKwh: 5000.0,
            closingReadingKwh: 4800.0, // Impossible rollback
          },
          mockAdminUser,
        ),
      ).rejects.toThrow(BadRequestException);
    });

    it('rejects duplicate electricity reading for the same date and department', async () => {
      // PRODUCTION was already logged for testDate in the first test
      await expect(
        electricityService.createReading(
          {
            recordDate: testDate,
            department: Department.PRODUCTION,
            unitsKwh: 50.0,
          },
          mockAdminUser,
        ),
      ).rejects.toThrow(ConflictException);
    });
  });
});
