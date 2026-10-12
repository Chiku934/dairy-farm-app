import { Test, TestingModule } from '@nestjs/testing';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { ConflictException, BadRequestException } from '@nestjs/common';
import {
  Department,
  EmploymentStatus,
  LicenceType,
  LicenceStatus,
  ReminderStatus,
} from '@dairy-farm/api-contracts';

import { EmployeesModule } from '../modules/employees/employees.module';
import { EmployeesService } from '../modules/employees/employees.service';
import { EmployeeEntity } from '../modules/employees/entities/employee.entity';

import { LicencesModule } from '../modules/licences/licences.module';
import { LicencesService } from '../modules/licences/licences.service';
import { LicenceNotificationService } from '../modules/licences/licence-notification.service';
import { RegulatoryLicenceEntity } from '../modules/licences/entities/regulatory-licence.entity';

import { AuditModule } from '../modules/audit/audit.module';
import { AuditLogEntity } from '../modules/audit/entities/audit-log.entity';

import { ConfigModule } from '@nestjs/config';
import { getDatabaseConfig } from '../modules/database/database.config';
import { AuthenticatedUser } from '../common/decorators/current-user.decorator';

describe('Phase 12: Employees and FSSAI & Licences Integration Tests', () => {
  let module: TestingModule;
  let dataSource: DataSource;
  let employeesService: EmployeesService;
  let licencesService: LicencesService;
  let notificationService: LicenceNotificationService;

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
    permissions: ['hr:read', 'animals:read', 'inventory:read'],
  };

  const auditorUser: AuthenticatedUser = {
    userId: 'usr-auditor',
    email: 'auditor@dairyfarm.com',
    fullName: 'Compliance Auditor',
    roles: ['AUDITOR'],
    permissions: ['hr:read', 'farm:settings:read', 'audit:read'],
  };

  beforeAll(async () => {
    module = await Test.createTestingModule({
      imports: [
        ConfigModule.forRoot({ isGlobal: true }),
        TypeOrmModule.forRootAsync({
          useFactory: () => getDatabaseConfig(),
        }),
        EmployeesModule,
        LicencesModule,
        AuditModule,
      ],
    }).compile();

    dataSource = module.get<DataSource>(DataSource);
    employeesService = module.get<EmployeesService>(EmployeesService);
    licencesService = module.get<LicencesService>(LicencesService);
    notificationService = module.get<LicenceNotificationService>(LicenceNotificationService);
  });

  afterAll(async () => {
    if (dataSource && dataSource.isInitialized) {
      await dataSource.destroy();
    }
  });

  // --------------------------------------------------------------------------
  // 1. Employee Profiles, Salary Rate Calculation & Date Validations
  // --------------------------------------------------------------------------
  describe('1. Employee Profiles, Salary Rate Calculation & Date Validations', () => {
    const testEmpCode1 = `EMP-TEST-${Date.now().toString().slice(-4)}-1`;
    const testEmpCode2 = `EMP-TEST-${Date.now().toString().slice(-4)}-2`;
    let createdEmpId: string;

    afterAll(async () => {
      await dataSource.query(`DELETE FROM employees WHERE employee_code LIKE 'EMP-TEST-%'`);
      await dataSource.query(`DELETE FROM audit_logs WHERE action IN ('CREATE_EMPLOYEE', 'UPDATE_EMPLOYEE', 'DEACTIVATE_EMPLOYEE')`);
    });

    it('creates an employee profile and verifies daily salary rate computation', async () => {
      const result = await employeesService.create(
        {
          employeeCode: testEmpCode1,
          fullName: 'Bikash Mohanty',
          department: Department.FARM,
          jobTitle: 'Cattle Specialist',
          joiningDate: '2025-02-01',
          monthlySalary: 36000.0,
          status: EmploymentStatus.ACTIVE,
          phone: '+919437012345',
          email: 'bikash@dairyfarm.local',
        },
        hrAdminUser,
      );

      expect(result).toBeDefined();
      expect(result.id).toBeDefined();
      createdEmpId = result.id;
      expect(result.employeeCode).toBe(testEmpCode1);
      expect(result.monthlySalary).toBe(36000.0);
      // daily rate is monthly_salary / 30.00 = 1200.00
      expect(Number(result.dailySalaryRate)).toBeCloseTo(1200.0, 2);
      expect(result.status).toBe(EmploymentStatus.ACTIVE);
      expect(result.isActive).toBe(true);
    });

    it('rejects joining date in the future with BadRequestException', async () => {
      const futureDate = new Date(Date.now() + 86400000 * 30).toISOString().slice(0, 10);
      await expect(
        employeesService.create(
          {
            employeeCode: testEmpCode2,
            fullName: 'Future Staff',
            department: Department.PRODUCTION,
            jobTitle: 'Dairy Tech',
            joiningDate: futureDate,
            monthlySalary: 25000.0,
          },
          hrAdminUser,
        ),
      ).rejects.toThrow(BadRequestException);
    });

    it('rejects leaving date before joining date with BadRequestException', async () => {
      await expect(
        employeesService.create(
          {
            employeeCode: testEmpCode2,
            fullName: 'Invalid Staff',
            department: Department.MANAGEMENT,
            jobTitle: 'Supervisor',
            joiningDate: '2025-05-10',
            leavingDate: '2025-05-01',
            monthlySalary: 30000.0,
          },
          hrAdminUser,
        ),
      ).rejects.toThrow(BadRequestException);
    });

    it('rejects duplicate employee code with ConflictException', async () => {
      await expect(
        employeesService.create(
          {
            employeeCode: testEmpCode1,
            fullName: 'Duplicate Employee',
            department: Department.FARM,
            jobTitle: 'Assistant',
            joiningDate: '2025-03-01',
            monthlySalary: 20000.0,
          },
          hrAdminUser,
        ),
      ).rejects.toThrow(ConflictException);
    });
  });

  // --------------------------------------------------------------------------
  // 2. Strict Role-Based Salary Privacy & Audit Sanitization
  // --------------------------------------------------------------------------
  describe('2. Strict Role-Based Salary Privacy & Audit Sanitization', () => {
    const privacyEmpCode = `EMP-PRIV-${Date.now().toString().slice(-4)}`;
    let privacyEmpId: string;

    beforeAll(async () => {
      const emp = await employeesService.create(
        {
          employeeCode: privacyEmpCode,
          fullName: 'Subhashree Nayak',
          department: Department.MANAGEMENT,
          jobTitle: 'HR Executive',
          joiningDate: '2025-01-10',
          monthlySalary: 45000.0,
          status: EmploymentStatus.ACTIVE,
        },
        hrAdminUser,
      );
      privacyEmpId = emp.id;
    });

    afterAll(async () => {
      await dataSource.query(`DELETE FROM employees WHERE employee_code = ?`, [privacyEmpCode]);
    });

    it('allows HR_ADMIN to view unredacted salary fields', async () => {
      const emp = await employeesService.findOne(privacyEmpId, hrAdminUser);
      expect(emp.monthlySalary).toBe(45000.0);
      expect(Number(emp.dailySalaryRate)).toBeCloseTo(1500.0, 2);
    });

    it('allows FARM_OWNER to view unredacted salary fields', async () => {
      const emp = await employeesService.findOne(privacyEmpId, farmOwnerUser);
      expect(emp.monthlySalary).toBe(45000.0);
      expect(Number(emp.dailySalaryRate)).toBeCloseTo(1500.0, 2);
    });

    it('allows ACCOUNTANT to view unredacted salary fields', async () => {
      const emp = await employeesService.findOne(privacyEmpId, accountantUser);
      expect(emp.monthlySalary).toBe(45000.0);
      expect(Number(emp.dailySalaryRate)).toBeCloseTo(1500.0, 2);
    });

    it('strictly redacts salary fields for FARM_MANAGER', async () => {
      const emp = await employeesService.findOne(privacyEmpId, farmManagerUser);
      expect(emp.fullName).toBe('Subhashree Nayak');
      expect(emp.jobTitle).toBe('HR Executive');
      expect(emp.monthlySalary).toBeNull();
      expect(emp.dailySalaryRate).toBeNull();
    });

    it('strictly redacts salary fields for AUDITOR', async () => {
      const emp = await employeesService.findOne(privacyEmpId, auditorUser);
      expect(emp.fullName).toBe('Subhashree Nayak');
      expect(emp.monthlySalary).toBeNull();
      expect(emp.dailySalaryRate).toBeNull();
    });

    it('redacts salary fields in list query results for unauthorized roles', async () => {
      const res = await employeesService.findAll(
        { search: privacyEmpCode },
        farmManagerUser,
      );
      expect(res.data.length).toBe(1);
      expect(res.data[0].employeeCode).toBe(privacyEmpCode);
      expect(res.data[0].monthlySalary).toBeNull();
      expect(res.data[0].dailySalaryRate).toBeNull();
    });

    it('ensures audit log records mask salary values with [REDACTED]', async () => {
      const auditLog = await dataSource.getRepository(AuditLogEntity).findOne({
        where: { entityType: 'EMPLOYEE', entityId: privacyEmpId, action: 'CREATE_EMPLOYEE' },
      });

      expect(auditLog).toBeDefined();
      expect(auditLog?.newValues).toBeDefined();
      const newVals = auditLog?.newValues;
      expect(newVals.monthlySalary).toBe('[REDACTED]');
      expect(newVals.dailySalaryRate).toBe('[REDACTED]');
      // Plain text salary must NOT be present
      expect(JSON.stringify(newVals)).not.toContain('45000');
    });

    it('updates employee profile and deactivates record safely', async () => {
      const updated = await employeesService.update(
        privacyEmpId,
        {
          jobTitle: 'Senior HR Manager',
          monthlySalary: 51000.0,
        },
        hrAdminUser,
      );

      expect(updated.jobTitle).toBe('Senior HR Manager');
      expect(updated.monthlySalary).toBe(51000.0);

      // Deactivate
      const removal = await employeesService.remove(privacyEmpId, hrAdminUser);
      expect(removal.message).toContain('successfully deactivated');

      const deactivated = await employeesService.findOne(privacyEmpId, hrAdminUser);
      expect(deactivated.isActive).toBe(false);
      expect(deactivated.status).toBe(EmploymentStatus.TERMINATED);
      expect(deactivated.leavingDate).toBeDefined();
    });
  });

  // --------------------------------------------------------------------------
  // 3. Regulatory Licences, Expiry State Machine & Configured Reminders
  // --------------------------------------------------------------------------
  describe('3. Regulatory Licences, Expiry State Machine & Configured Reminders', () => {
    const testLicNum1 = `FSSAI-TEST-${Date.now().toString().slice(-5)}-1`;
    const testLicNum2 = `POLL-TEST-${Date.now().toString().slice(-5)}-2`;
    let activeLicId: string;
    let expiringLicId: string;

    afterAll(async () => {
      await dataSource.query(`DELETE FROM regulatory_licences WHERE licence_number LIKE '%-TEST-%'`);
      await dataSource.query(`DELETE FROM audit_logs WHERE action IN ('CREATE_REGULATORY_LICENCE', 'UPDATE_REGULATORY_LICENCE', 'DISPATCH_LICENCE_REMINDER', 'DISMISS_LICENCE_REMINDER')`);
    });

    it('creates regulatory licence with valid issue and expiry dates', async () => {
      const lic = await licencesService.create(
        {
          licenceName: 'Central FSSAI Dairy Processing Licence',
          licenceType: LicenceType.FSSAI,
          licenceNumber: testLicNum1,
          issuingAuthority: 'FSSAI Eastern Regional Office',
          licenceHolder: 'Green Pastures Organic Dairy',
          issueDate: '2024-01-01',
          expiryDate: '2027-12-31',
          reminderDaysBefore: 30,
        },
        farmOwnerUser,
      );

      expect(lic).toBeDefined();
      expect(lic.id).toBeDefined();
      activeLicId = lic.id;
      expect(lic.licenceType).toBe(LicenceType.FSSAI);
      expect(lic.status).toBe(LicenceStatus.ACTIVE);
      expect(lic.reminderStatus).toBe(ReminderStatus.PENDING);
    });

    it('rejects licence where expiry date is on or before issue date with BadRequestException', async () => {
      await expect(
        licencesService.create(
          {
            licenceName: 'Inverted Date Licence',
            licenceType: LicenceType.OTHER,
            licenceNumber: `INV-${Date.now()}`,
            issuingAuthority: 'Test Authority',
            licenceHolder: 'Green Pastures',
            issueDate: '2025-06-01',
            expiryDate: '2025-06-01', // Equal to issue date -> invalid
          },
          farmOwnerUser,
        ),
      ).rejects.toThrow(BadRequestException);
    });

    it('rejects duplicate licence number with ConflictException', async () => {
      await expect(
        licencesService.create(
          {
            licenceName: 'Duplicate Licence',
            licenceType: LicenceType.TRADE_LICENSE,
            licenceNumber: testLicNum1,
            issuingAuthority: 'Municipal Corp',
            licenceHolder: 'Green Pastures',
            issueDate: '2025-01-01',
            expiryDate: '2026-01-01',
          },
          farmOwnerUser,
        ),
      ).rejects.toThrow(ConflictException);
    });

    it('correctly derives EXPIRING_SOON status when expiry date is within reminder window', async () => {
      // Expiry 10 days from today
      const soonDate = new Date(Date.now() + 10 * 86400000).toISOString().slice(0, 10);
      const lic = await licencesService.create(
        {
          licenceName: 'Pollution Control Consent to Operate',
          licenceType: LicenceType.POLLUTION_CONTROL,
          licenceNumber: testLicNum2,
          issuingAuthority: 'State Pollution Control Board',
          licenceHolder: 'Green Pastures Organic Dairy',
          issueDate: '2023-01-01',
          expiryDate: soonDate,
          reminderDaysBefore: 30,
        },
        farmOwnerUser,
      );

      expect(lic.status).toBe(LicenceStatus.EXPIRING_SOON);
      expiringLicId = lic.id;
    });

    it('withholds reminder dispatch when notification service is unconfigured', async () => {
      // Ensure notification service is NOT configured
      notificationService.setConfigured(false);
      expect(notificationService.isServiceConfigured()).toBe(false);

      const result = await licencesService.processReminders(farmOwnerUser);
      expect(result.configured).toBe(false);
      expect(result.dispatchedCount).toBe(0);
      expect(result.message).toContain('Notification service is not configured');

      // Verify reminderStatus remains PENDING
      const lic = await licencesService.findOne(expiringLicId);
      expect(lic.reminderStatus).toBe(ReminderStatus.PENDING);
      expect(lic.reminderSentAt).toBeNull();
    });

    it('dispatches reminder and updates reminderStatus when notification service is explicitly configured', async () => {
      // Enable notification service
      notificationService.setConfigured(true);
      expect(notificationService.isServiceConfigured()).toBe(true);

      const result = await licencesService.processReminders(farmOwnerUser);
      expect(result.configured).toBe(true);
      expect(result.dispatchedCount).toBeGreaterThanOrEqual(1);

      // Verify reminderStatus transitioned to NOTIFIED
      const lic = await licencesService.findOne(expiringLicId);
      expect(lic.reminderStatus).toBe(ReminderStatus.NOTIFIED);
      expect(lic.reminderSentAt).toBeDefined();

      // Verify audit log entry
      const audit = await dataSource.getRepository(AuditLogEntity).findOne({
        where: { entityType: 'REGULATORY_LICENCE', entityId: expiringLicId, action: 'DISPATCH_LICENCE_REMINDER' },
      });
      expect(audit).toBeDefined();
    });

    it('dismisses a reminder alert and records audit log', async () => {
      const dismissed = await licencesService.dismissReminder(expiringLicId, farmOwnerUser);
      expect(dismissed.reminderStatus).toBe(ReminderStatus.DISMISSED);

      const audit = await dataSource.getRepository(AuditLogEntity).findOne({
        where: { entityType: 'REGULATORY_LICENCE', entityId: expiringLicId, action: 'DISMISS_LICENCE_REMINDER' },
      });
      expect(audit).toBeDefined();
    });
  });
});
