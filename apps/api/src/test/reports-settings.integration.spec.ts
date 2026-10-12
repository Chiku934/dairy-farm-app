import { Test, TestingModule } from '@nestjs/testing';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { ForbiddenException, BadRequestException } from '@nestjs/common';
import {
  Department,
  EmploymentStatus,
  LicenceType,
  CostCentre,
  ExpenseCategory,
  PaymentMethod,
  MilkingSession,
  MilkDisposition,
} from '@dairy-farm/api-contracts';

import { ReportsModule } from '../modules/reports/reports.module';
import { ReportsService } from '../modules/reports/reports.service';

import { SettingsModule } from '../modules/settings/settings.module';
import { SettingsService } from '../modules/settings/settings.service';

import { AuditModule } from '../modules/audit/audit.module';
import { AuditLogEntity } from '../modules/audit/entities/audit-log.entity';

import { ConfigModule } from '@nestjs/config';
import { getDatabaseConfig } from '../modules/database/database.config';
import { AuthenticatedUser } from '../common/decorators/current-user.decorator';
import { sanitizeCsvCell, generateSafeCsv } from '../common/utils/csv-sanitizer.util';

describe('Phase 13: Reports & Exports and Farm Settings Integration Tests', () => {
  let module: TestingModule;
  let dataSource: DataSource;
  let reportsService: ReportsService;
  let settingsService: SettingsService;

  const hrAdminUser: AuthenticatedUser = {
    userId: 'usr-hr-admin',
    email: 'hr@dairyfarm.com',
    fullName: 'HR Administrator',
    roles: ['HR_ADMIN'],
    permissions: ['hr:read', 'hr:write'],
  };

  const accountantUser: AuthenticatedUser = {
    userId: 'usr-accountant',
    email: 'acct@dairyfarm.com',
    fullName: 'Senior Accountant',
    roles: ['ACCOUNTANT'],
    permissions: ['hr:read', 'finance:read', 'finance:write'],
  };

  const farmOwnerUser: AuthenticatedUser = {
    userId: 'usr-farm-owner',
    email: 'owner@dairyfarm.com',
    fullName: 'Farm Owner',
    roles: ['FARM_OWNER'],
    permissions: ['*'],
  };

  const farmManagerUser: AuthenticatedUser = {
    userId: 'usr-farm-mgr',
    email: 'mgr@dairyfarm.com',
    fullName: 'Farm Manager',
    roles: ['FARM_MANAGER'],
    permissions: ['hr:read', 'animals:read', 'inventory:read', 'milking:read'],
  };

  const auditorUser: AuthenticatedUser = {
    userId: 'usr-auditor',
    email: 'auditor@dairyfarm.com',
    fullName: 'Compliance Auditor',
    roles: ['AUDITOR'],
    permissions: ['hr:read', 'farm:settings:read', 'audit:read', 'finance:read'],
  };

  beforeAll(async () => {
    module = await Test.createTestingModule({
      imports: [
        ConfigModule.forRoot({ isGlobal: true }),
        TypeOrmModule.forRootAsync({
          useFactory: () => getDatabaseConfig(),
        }),
        ReportsModule,
        SettingsModule,
        AuditModule,
      ],
    }).compile();

    dataSource = module.get<DataSource>(DataSource);
    reportsService = module.get<ReportsService>(ReportsService);
    settingsService = module.get<SettingsService>(SettingsService);
  });

  afterAll(async () => {
    if (dataSource && dataSource.isInitialized) {
      await dataSource.destroy();
    }
  });

  // --------------------------------------------------------------------------
  // 1. Report SQL Aggregations & Reconciliation against Fixtures
  // --------------------------------------------------------------------------
  describe('1. Report SQL Aggregations & Reconciliation against Fixtures', () => {
    const testAnimalId = `cow-rep-${Date.now()}`;
    const testHealthId = `hlth-rep-${Date.now()}`;
    const testExpenseId = `exp-rep-${Date.now()}`;
    const testMilkingId1 = `milk-rep-${Date.now()}-1`;
    const testMilkingId2 = `milk-rep-${Date.now()}-2`;

    beforeAll(async () => {
      // Seed test animal
      await dataSource.query(
        `INSERT INTO animals (id, ear_tag, breed, sex, status, date_of_birth)
         VALUES (?, ?, 'GIR', 'FEMALE', 'LACTATING', '2021-03-15')`,
        [testAnimalId, `TAG-REP-${Date.now().toString().slice(-4)}`],
      );

      // Seed health record with future withdrawal date
      await dataSource.query(
        `INSERT INTO health_records (id, animal_id, record_date, care_type, medicine_vaccine, prescribed_dose, withdrawal_until)
         VALUES (?, ?, '2026-10-09', 'TREATMENT', 'Oxytetracycline', '10ml', '2026-10-20')`,
        [testHealthId, testAnimalId],
      );

      // Seed 2 milking records into milking_logs (1 eligible 15L, 1 withheld 5L)
      await dataSource.query(
        `INSERT INTO milking_logs (id, animal_id, record_date, session, yield_litres, disposition)
         VALUES 
         (?, ?, '2026-10-10', 'MORNING', 15.00, 'ELIGIBLE'),
         (?, ?, '2026-10-10', 'EVENING', 5.00, 'WITHHELD')`,
        [testMilkingId1, testAnimalId, testMilkingId2, testAnimalId],
      );

      // Seed test operating expense
      await dataSource.query(
        `INSERT INTO operating_expenses (id, expense_number, record_date, cost_centre, category, amount, payee, payment_method)
         VALUES (?, ?, '2026-10-10', 'FARM', 'VET', 2450.00, 'City Vet Clinic', 'UPI')`,
        [testExpenseId, `EXP-REP-${Date.now().toString().slice(-4)}`],
      );
    });

    afterAll(async () => {
      await dataSource.query(`DELETE FROM milking_logs WHERE id IN (?, ?)`, [testMilkingId1, testMilkingId2]);
      await dataSource.query(`DELETE FROM health_records WHERE id = ?`, [testHealthId]);
      await dataSource.query(`DELETE FROM operating_expenses WHERE id = ?`, [testExpenseId]);
      await dataSource.query(`DELETE FROM animals WHERE id = ?`, [testAnimalId]);
    });

    it('reconciles Milk Production report summary and tabular results', async () => {
      const res = await reportsService.getMilkProductionReport({
        startDate: '2026-10-10',
        endDate: '2026-10-10',
      });

      expect(res.summary).toBeDefined();
      expect(res.summary.totalYieldLitres).toBeGreaterThanOrEqual(20.0);
      expect(res.summary.withheldLitres).toBeGreaterThanOrEqual(5.0);
      expect(res.items.length).toBeGreaterThanOrEqual(2);

      const foundWithheld = res.items.find((item) => item.id === testMilkingId2);
      expect(foundWithheld).toBeDefined();
      expect(foundWithheld.disposition).toBe('WITHHELD');
      expect(Number(foundWithheld.yield_litres)).toBe(5.0);
    });

    it('reconciles Operating Expenses report summary and cost centre breakdown', async () => {
      const res = await reportsService.getExpensesReport({
        startDate: '2026-10-10',
        endDate: '2026-10-10',
      });

      expect(res.summary.totalExpenses).toBeGreaterThanOrEqual(2450.0);
      expect(res.summary.farmExpenses).toBeGreaterThanOrEqual(2450.0);
      const foundExp = res.items.find((item) => item.id === testExpenseId);
      expect(foundExp).toBeDefined();
      expect(Number(foundExp.amount)).toBe(2450.0);
      expect(foundExp.payee).toBe('City Vet Clinic');
    });

    it('reconciles Herd Inventory report status and withdrawal counts', async () => {
      const res = await reportsService.getHerdReport({});
      expect(res.summary.totalHeadCount).toBeGreaterThan(0);
      expect(res.summary.lactatingCount).toBeGreaterThan(0);
      expect(res.summary.withheldCount).toBeGreaterThan(0);

      const foundCow = res.items.find((item) => item.id === testAnimalId);
      expect(foundCow).toBeDefined();
      expect(foundCow.status).toBe('LACTATING');
      expect(foundCow.active_withdrawal).toBe('YES');
    });

    it('reconciles Inventory Valuation report and low stock detection', async () => {
      const res = await reportsService.getInventoryReport({});
      expect(res.summary).toBeDefined();
      expect(res.summary.totalItems).toBeGreaterThan(0);
      expect(res.items.length).toBeGreaterThan(0);
      expect(res.items[0]).toHaveProperty('stock_valuation');
      expect(res.items[0]).toHaveProperty('is_low_stock');
    });
  });

  // --------------------------------------------------------------------------
  // 2. Spreadsheet Formula Injection Prevention (CWE-1236)
  // --------------------------------------------------------------------------
  describe('2. Spreadsheet Formula Injection Prevention (CWE-1236)', () => {
    it('escapes cells starting with formula triggers (=, +, -, @, \\t, \\r)', () => {
      // Cell starting with =
      expect(sanitizeCsvCell("=cmd|' /C calc'!A0")).toBe("'=cmd|' /C calc'!A0");
      // Cell starting with +
      expect(sanitizeCsvCell('+12345')).toBe("'+12345");
      // Cell starting with -
      expect(sanitizeCsvCell('-5+5')).toBe("'-5+5");
      // Cell starting with @
      expect(sanitizeCsvCell('@SUM(A1:A10)')).toBe("'@SUM(A1:A10)");
      // Cell starting with tab
      expect(sanitizeCsvCell('\tSecret')).toBe("'\tSecret");
    });

    it('properly quotes cells containing commas, double quotes, and newlines', () => {
      // Commas
      expect(sanitizeCsvCell('Koraput, Odisha')).toBe('"Koraput, Odisha"');
      // Quotes
      expect(sanitizeCsvCell('He said "Hello"')).toBe('"He said ""Hello"""');
      // Formula + Comma: formula escape first, then quotes
      expect(sanitizeCsvCell('=SUM(A1, B1)')).toBe('"\'=SUM(A1, B1)"');
    });

    it('generates injection-safe CSV document correctly', () => {
      const columns = [
        { key: 'name', label: 'Item Name' },
        { key: 'notes', label: 'Notes' },
      ];
      const rows = [
        { name: '=1+1', notes: 'Safe text' },
        { name: 'Normal Cow', notes: '@HYPERLINK("http://malicious.site")' },
        { name: 'Pincode, District', notes: 'Normal note' },
      ];

      const csv = generateSafeCsv(columns, rows);
      const lines = csv.split('\r\n');

      expect(lines.length).toBe(4);
      expect(lines[0]).toBe('Item Name,Notes');
      // First row escaped with leading single quote
      expect(lines[1]).toBe("'=1+1,Safe text");
      // Second row escaped with leading single quote and quoted due to inner quotes
      expect(lines[2]).toBe('Normal Cow,"\'@HYPERLINK(""http://malicious.site"")"');
      // Third row properly quoted for comma
      expect(lines[3]).toBe('"Pincode, District",Normal note');
    });
  });

  // --------------------------------------------------------------------------
  // 3. Sensitive Export & Report Permissions (Strict RBAC)
  // --------------------------------------------------------------------------
  describe('3. Sensitive Export & Report Permissions (Strict RBAC)', () => {
    it('allows HR_ADMIN to access staff wage report and export', async () => {
      const report = await reportsService.getStaffPayrollReport({}, hrAdminUser);
      expect(report.summary).toBeDefined();
      expect(report.summary.totalEmployees).toBeGreaterThan(0);
      expect(report.summary.totalMonthlySalary).toBeGreaterThan(0);

      const csv = await reportsService.exportStaffPayrollReport({}, hrAdminUser);
      expect(csv).toContain('Employee Code');
      expect(csv).toContain('Approved Monthly Salary (₹)');
      expect(csv).toContain('Daily Wage Rate (₹)');
    });

    it('allows ACCOUNTANT to access staff wage report and export', async () => {
      const report = await reportsService.getStaffPayrollReport({}, accountantUser);
      expect(report.summary).toBeDefined();

      const csv = await reportsService.exportStaffPayrollReport({}, accountantUser);
      expect(csv).toContain('Employee Code');
    });

    it('allows FARM_OWNER to access staff wage report and export', async () => {
      const report = await reportsService.getStaffPayrollReport({}, farmOwnerUser);
      expect(report.summary).toBeDefined();

      const csv = await reportsService.exportStaffPayrollReport({}, farmOwnerUser);
      expect(csv).toContain('Approved Monthly Salary (₹)');
    });

    it('strictly forbids FARM_MANAGER from accessing staff wage report and export', async () => {
      await expect(
        reportsService.getStaffPayrollReport({}, farmManagerUser),
      ).rejects.toThrow(ForbiddenException);

      await expect(
        reportsService.exportStaffPayrollReport({}, farmManagerUser),
      ).rejects.toThrow(ForbiddenException);
    });

    it('strictly forbids AUDITOR from accessing staff wage report and export', async () => {
      await expect(
        reportsService.getStaffPayrollReport({}, auditorUser),
      ).rejects.toThrow(ForbiddenException);

      await expect(
        reportsService.exportStaffPayrollReport({}, auditorUser),
      ).rejects.toThrow(ForbiddenException);
    });
  });

  // --------------------------------------------------------------------------
  // 4. Farm Settings & Audit Logging
  // --------------------------------------------------------------------------
  describe('4. Farm Settings & Audit Logging', () => {
    afterAll(async () => {
      await dataSource.query(`DELETE FROM audit_logs WHERE action = 'UPDATE_FARM_SETTINGS'`);
    });

    it('retrieves current farm operational parameters and identity', async () => {
      const settings = await settingsService.getSettings();
      expect(settings).toBeDefined();
      expect(settings.farmName).toBeDefined();
      expect(settings.bmcCapacityLitres).toBeGreaterThanOrEqual(100);
      expect(settings.currencyCode).toBe('INR');
    });

    it('updates master farm profile and creates immutable audit log entry', async () => {
      const updated = await settingsService.updateSettings(
        {
          farmName: 'Kaivalya Organic Dairy Enterprise',
          contactPhone: '+91 9437011223',
          electricityTariff: 1.55,
          bmcCapacityLitres: 2500.0,
        },
        farmOwnerUser,
      );

      expect(updated.farmName).toBe('Kaivalya Organic Dairy Enterprise');
      expect(updated.contactPhone).toBe('+91 9437011223');
      expect(Number(updated.electricityTariff)).toBe(1.55);
      expect(Number(updated.bmcCapacityLitres)).toBe(2500.0);

      // Verify audit trail entry
      const auditLog = await dataSource.getRepository(AuditLogEntity).findOne({
        where: { action: 'UPDATE_FARM_SETTINGS', entityType: 'FARM_SETTINGS' },
        order: { createdAt: 'DESC' },
      });

      expect(auditLog).toBeDefined();
      expect(auditLog?.userId).toBe(farmOwnerUser.userId);
      expect(auditLog?.newValues).toBeDefined();
      expect(auditLog?.newValues.farmName).toBe('Kaivalya Organic Dairy Enterprise');
    });
  });
});
