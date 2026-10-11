import { Test, TestingModule } from '@nestjs/testing';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { v4 as uuidv4 } from 'uuid';
import * as bcrypt from 'bcrypt';

import { AnimalEntity, AnimalSex, AnimalStatus } from '../modules/herd/entities/animal.entity';
import { HealthRecordEntity, CareType } from '../modules/animal-health/entities/health-record.entity';
import { BreedingRecordEntity, BreedingEventType } from '../modules/breeding/entities/breeding-record.entity';
import { UserEntity } from '../modules/users/entities/user.entity';
import { RoleEntity } from '../modules/users/entities/role.entity';
import { PermissionEntity } from '../modules/users/entities/permission.entity';
import { UserSessionEntity } from '../modules/auth/entities/user-session.entity';
import { AuditLogEntity } from '../modules/audit/entities/audit-log.entity';

import { HerdService } from '../modules/herd/herd.service';
import { HerdController } from '../modules/herd/herd.controller';
import { AnimalHealthService } from '../modules/animal-health/animal-health.service';
import { AnimalHealthController } from '../modules/animal-health/animal-health.controller';
import { BreedingService } from '../modules/breeding/breeding.service';
import { BreedingController } from '../modules/breeding/breeding.controller';
import { AuditService } from '../modules/audit/audit.service';
import { UsersService } from '../modules/users/users.service';
import { AuthService } from '../modules/auth/auth.service';
import { JwtStrategy } from '../modules/auth/jwt.strategy';
import { PermissionsGuard } from '../common/guards/permissions.guard';
import { Reflector } from '@nestjs/core';
import { ConflictException, NotFoundException, BadRequestException, ForbiddenException } from '@nestjs/common';

describe('Phase 6: Herd, Health & Breeding Integration Tests (Test Database)', () => {
  let module: TestingModule;
  let dataSource: DataSource;
  let herdService: HerdService;
  let healthService: AnimalHealthService;
  let breedingService: BreedingService;
  let permissionsGuard: PermissionsGuard;
  let reflector: Reflector;

  const testDbName = 'dairy_farm_test_db';

  beforeAll(async () => {
    if (!testDbName.includes('test')) {
      throw new Error('FATAL: Attempting to run tests against a non-test database!');
    }

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
            AnimalEntity,
            HealthRecordEntity,
            BreedingRecordEntity,
            UserEntity,
            RoleEntity,
            PermissionEntity,
            UserSessionEntity,
            AuditLogEntity,
          ],
          synchronize: false,
        }),
        TypeOrmModule.forFeature([
          AnimalEntity,
          HealthRecordEntity,
          BreedingRecordEntity,
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
      controllers: [HerdController, AnimalHealthController, BreedingController],
      providers: [
        HerdService,
        AnimalHealthService,
        BreedingService,
        AuditService,
        UsersService,
        AuthService,
        JwtStrategy,
        PermissionsGuard,
      ],
    }).compile();

    dataSource = module.get<DataSource>(DataSource);
    herdService = module.get<HerdService>(HerdService);
    healthService = module.get<AnimalHealthService>(AnimalHealthService);
    breedingService = module.get<BreedingService>(BreedingService);
    permissionsGuard = module.get<PermissionsGuard>(PermissionsGuard);
    reflector = module.get<Reflector>(Reflector);
  });

  afterAll(async () => {
    if (dataSource && dataSource.isInitialized) {
      await dataSource.query(`DELETE b FROM breeding_records b JOIN animals a ON b.animal_id = a.id WHERE a.ear_tag LIKE 'TEST-%' OR a.ear_tag LIKE 'HEIFER-%'`);
      await dataSource.query(`DELETE h FROM health_records h JOIN animals a ON h.animal_id = a.id WHERE a.ear_tag LIKE 'TEST-%' OR a.ear_tag LIKE 'HEIFER-%'`);
      await dataSource.query(`DELETE FROM health_records WHERE medicine_vaccine LIKE '%Ceftiofur Sodium Sterile%' OR medicine_vaccine LIKE '%FMD Oil%'`);
      await dataSource.query(`DELETE FROM animals WHERE ear_tag LIKE 'TEST-%' OR ear_tag LIKE 'HEIFER-%' OR ear_tag LIKE 'CALF-%'`);
      await dataSource.destroy();
    }
  });

  describe('1. Herd & Calves Management Workflows', () => {
    const testEarTag = `TEST-${Date.now().toString().slice(-6)}`;
    let createdAnimalId: string;

    it('should successfully register a new cow with validated ear tag and initial status', async () => {
      const animal = await herdService.create(
        {
          earTag: testEarTag,
          name: 'Sundari Test',
          breed: 'GIR',
          sex: AnimalSex.FEMALE,
          dateOfBirth: '2023-01-15',
          status: AnimalStatus.LACTATING,
          bodyWeightKg: 465.5,
          bodyConditionScore: 3.5,
          notes: 'Test cattle created for Phase 6 automated suite',
        },
        'usr-dev-admin',
      );

      expect(animal).toBeDefined();
      expect(animal.id).toBeDefined();
      expect(animal.earTag).toBe(testEarTag);
      expect(animal.status).toBe(AnimalStatus.LACTATING);
      expect(animal.isArchived).toBe(false);

      createdAnimalId = animal.id;
    });

    it('should reject creating an animal with duplicate ear tag', async () => {
      await expect(
        herdService.create(
          {
            earTag: testEarTag,
            breed: 'JERSEY',
          },
          'usr-dev-admin',
        ),
      ).rejects.toThrow(ConflictException);
    });

    it('should reject dam tag equal to animal ear tag', async () => {
      const newTag = `TAG-SELF-${Date.now().toString().slice(-4)}`;
      await expect(
        herdService.create(
          {
            earTag: newTag,
            breed: 'GIR',
            damTag: newTag,
          },
          'usr-dev-admin',
        ),
      ).rejects.toThrow(BadRequestException);
    });

    it('should list animals with pagination and filtering', async () => {
      const list = await herdService.findAll({
        page: 1,
        limit: 10,
        status: AnimalStatus.LACTATING,
      });

      expect(list.items).toBeDefined();
      expect(list.items.length).toBeGreaterThanOrEqual(1);
      expect(list.items.some((a) => a.id === createdAnimalId)).toBe(true);
    });

    it('should update animal body weight and status', async () => {
      const updated = await herdService.update(
        createdAnimalId,
        {
          bodyWeightKg: 478.0,
          bodyConditionScore: 4.0,
          status: AnimalStatus.DRY,
          notes: 'Transitioned to dry cow ration',
        },
        'usr-dev-admin',
      );

      expect(updated.bodyWeightKg).toBe(478.0);
      expect(updated.status).toBe(AnimalStatus.DRY);
    });

    it('should archive animal while preserving historical record', async () => {
      const archived = await herdService.archive(
        createdAnimalId,
        {
          status: AnimalStatus.SOLD,
          archiveReason: 'Sold to verified local farmer',
        },
        'usr-dev-admin',
      );

      expect(archived.isArchived).toBe(true);
      expect(archived.status).toBe(AnimalStatus.SOLD);
      expect(archived.archiveReason).toBe('Sold to verified local farmer');
      expect(archived.archivedAt).toBeDefined();

      // Ensure excluded from default query
      const activeList = await herdService.findAll({ page: 1, limit: 50, includeArchived: false });
      expect(activeList.items.some((a) => a.id === createdAnimalId)).toBe(false);

      // Ensure present when includeArchived = true
      const fullList = await herdService.findAll({ page: 1, limit: 50, includeArchived: true });
      expect(fullList.items.some((a) => a.id === createdAnimalId)).toBe(true);
    });
  });

  describe('2. Health & Vaccination Workflows (Distinct Diagnosis & Withdrawal)', () => {
    let testCowId: string;

    beforeAll(async () => {
      // Find an active female cow
      const cow = await dataSource.getRepository(AnimalEntity).findOne({ where: { status: AnimalStatus.LACTATING } });
      testCowId = cow ? cow.id : 'c-01';
    });

    it('should record treatment keeping diagnosis distinct from medication and dose', async () => {
      const withdrawalDate = new Date();
      withdrawalDate.setDate(withdrawalDate.getDate() + 4);
      const withdrawalStr = withdrawalDate.toISOString().substring(0, 10);

      const record = await healthService.create(
        {
          animalId: testCowId,
          recordDate: '2026-10-11',
          careType: CareType.TREATMENT,
          diagnosis: 'Subclinical Mastitis in Right Rear Quarter',
          medicineVaccine: 'Ceftiofur Sodium Sterile Powder',
          prescribedDose: '10ml IM once daily for 3 days',
          veterinarian: 'Dr. B. K. Panda',
          withdrawalUntil: withdrawalStr,
          notes: 'Milk must be withheld from BMC collection until withdrawal expires',
        },
        'usr-dev-admin',
      );

      expect(record).toBeDefined();
      expect(record.careType).toBe(CareType.TREATMENT);
      expect(record.diagnosis).toBe('Subclinical Mastitis in Right Rear Quarter');
      expect(record.medicineVaccine).toBe('Ceftiofur Sodium Sterile Powder');
      expect(record.withdrawalUntil).toBe(withdrawalStr);
    });

    it('should reflect active milk withdrawal in withdrawals list with days remaining', async () => {
      const activeWithdrawals = await healthService.getActiveWithdrawals();
      expect(activeWithdrawals).toBeDefined();
      expect(activeWithdrawals.length).toBeGreaterThanOrEqual(1);

      const entry = activeWithdrawals.find((w) => w.animalId === testCowId);
      expect(entry).toBeDefined();
      expect(entry?.daysRemaining).toBeGreaterThanOrEqual(1);
    });

    it('should record vaccination and retrieve upcoming booster reminders', async () => {
      const dueDate = new Date();
      dueDate.setDate(dueDate.getDate() + 15);
      const dueStr = dueDate.toISOString().substring(0, 10);

      const vacRecord = await healthService.create(
        {
          animalId: testCowId,
          recordDate: '2026-10-11',
          careType: CareType.VACCINATION,
          diagnosis: 'Routine Prophylactic Immunization',
          medicineVaccine: 'FMD Oil Adjuvant Vaccine',
          prescribedDose: '2ml Subcutaneously',
          veterinarian: 'Dr. B. K. Panda',
          nextDueDate: dueStr,
          notes: 'Bi-annual Foot and Mouth Disease booster',
        },
        'usr-dev-admin',
      );

      expect(vacRecord.nextDueDate).toBe(dueStr);

      const reminders = await healthService.getReminders();
      expect(reminders.some((r) => r.id === vacRecord.id)).toBe(true);
      const reminder = reminders.find((r) => r.id === vacRecord.id);
      expect(reminder?.daysRemaining).toBe(15);
      expect(reminder?.isOverdue).toBe(false);
    });
  });

  describe('3. Breeding & Calving Lifecycle (280-Day Gestation & State Updates)', () => {
    let breedingCowId: string;
    let breedingCowEarTag: string;

    beforeAll(async () => {
      // Create a fresh eligible heifer
      const tag = `HEIFER-${Date.now().toString().slice(-5)}`;
      const heifer = await herdService.create({
        earTag: tag,
        name: 'Heifer Kalyani',
        breed: 'GIR',
        sex: AnimalSex.FEMALE,
        status: AnimalStatus.HEIFER,
      });
      breedingCowId = heifer.id;
      breedingCowEarTag = heifer.earTag;
    });

    it('should auto-calculate ~280-day expected calving and 45-day pregnancy check on Insemination', async () => {
      const aiRecord = await breedingService.create(
        {
          animalId: breedingCowId,
          recordDate: '2026-10-11',
          eventType: BreedingEventType.INSEMINATION,
          sireSemenId: 'SIRE-GIR-PRIME-09',
          notes: 'Artificial insemination performed with elite Gir semen straw',
        },
        'usr-dev-admin',
      );

      expect(aiRecord.expectedCalvingDate).toBeDefined();
      // 2026-10-11 + 280 days is ~2027-07-18
      const expDate = new Date(aiRecord.expectedCalvingDate!);
      const recDate = new Date('2026-10-11');
      const diffDays = Math.round((expDate.getTime() - recDate.getTime()) / (1000 * 60 * 60 * 24));
      expect(diffDays).toBe(280);

      // Next check date ~45 days
      expect(aiRecord.nextCheckDate).toBeDefined();
      const checkDate = new Date(aiRecord.nextCheckDate!);
      const checkDiff = Math.round((checkDate.getTime() - recDate.getTime()) / (1000 * 60 * 60 * 24));
      expect(checkDiff).toBe(45);
    });

    it('should transition cow status to PREGNANT upon PREGNANCY_CONFIRMED', async () => {
      await breedingService.create(
        {
          animalId: breedingCowId,
          recordDate: '2026-11-26',
          eventType: BreedingEventType.PREGNANCY_CONFIRMED,
          notes: 'Ultrasound confirmed active single fetus',
        },
        'usr-dev-admin',
      );

      const cow = await herdService.findByIdOrTag(breedingCowId);
      expect(cow.status).toBe(AnimalStatus.PREGNANT);
    });

    it('should transition cow status to LACTATING and update lastCalvingDate on CALVING', async () => {
      const calfTag = `CALF-${Date.now().toString().slice(-4)}`;
      await breedingService.create(
        {
          animalId: breedingCowId,
          recordDate: '2027-07-18',
          eventType: BreedingEventType.CALVING,
          calfTag,
          notes: 'Normal unassisted delivery. Healthy female calf born.',
        },
        'usr-dev-admin',
      );

      const cow = await herdService.findByIdOrTag(breedingCowId);
      expect(cow.status).toBe(AnimalStatus.LACTATING);
      expect(cow.lastCalvingDate).toBe('2027-07-18');
    });

    it('should retrieve full chronological unified history timeline for the animal', async () => {
      const history = await herdService.getHistory(breedingCowId);
      expect(history.animal).toBeDefined();
      expect(history.timeline).toBeDefined();
      expect(history.timeline.length).toBeGreaterThanOrEqual(3);

      // Verify chronological ordering descending
      for (let i = 0; i < history.timeline.length - 1; i++) {
        expect(history.timeline[i].date.localeCompare(history.timeline[i + 1].date)).toBeGreaterThanOrEqual(0);
      }
    });
  });

  describe('4. Server-Side Role-Based Authorization Enforcement', () => {
    it('should allow ANIMAL_CARE role with animals:write and health:write permissions', () => {
      const context: any = {
        getHandler: () => ({}),
        getClass: () => ({}),
        switchToHttp: () => ({
          getRequest: () => ({
            user: {
              roles: ['ANIMAL_CARE'],
              permissions: ['animals:read', 'animals:write', 'health:read', 'health:write', 'breeding:read', 'breeding:write'],
            },
          }),
        }),
      };

      jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue(['animals:write']);
      const canActivate = permissionsGuard.canActivate(context);
      expect(canActivate).toBe(true);
    });

    it('should reject non-permitted role (e.g. STOREKEEPER) attempting animals:write', () => {
      const context: any = {
        getHandler: () => ({}),
        getClass: () => ({}),
        switchToHttp: () => ({
          getRequest: () => ({
            user: {
              roles: ['STOREKEEPER'],
              permissions: ['inventory:read', 'inventory:write'],
            },
          }),
        }),
      };

      jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue(['animals:write']);
      expect(() => permissionsGuard.canActivate(context)).toThrow(ForbiddenException);
    });
  });
});
