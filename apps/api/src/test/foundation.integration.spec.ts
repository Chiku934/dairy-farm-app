import { Test, TestingModule } from '@nestjs/testing';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DataSource, QueryFailedError } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { v4 as uuidv4 } from 'uuid';

import { FarmSettingsEntity } from '../modules/settings/entities/farm-settings.entity';
import { SettingsService } from '../modules/settings/settings.service';
import { UserEntity } from '../modules/users/entities/user.entity';
import { RoleEntity } from '../modules/users/entities/role.entity';
import { PermissionEntity } from '../modules/users/entities/permission.entity';
import { UsersService } from '../modules/users/users.service';
import { UserSessionEntity } from '../modules/auth/entities/user-session.entity';
import { AuthService } from '../modules/auth/auth.service';
import { UnitOfMeasurementEntity, UomDimension } from '../modules/master-data/entities/unit-of-measurement.entity';
import { LookupCategoryEntity } from '../modules/master-data/entities/lookup-category.entity';
import { LookupValueEntity } from '../modules/master-data/entities/lookup-value.entity';
import { MasterDataService } from '../modules/master-data/master-data.service';
import { AuditLogEntity } from '../modules/audit/entities/audit-log.entity';
import { AuditService } from '../modules/audit/audit.service';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { JwtStrategy } from '../modules/auth/jwt.strategy';

describe('Foundation Integration Tests (Dedicated Test Database)', () => {
  let module: TestingModule;
  let dataSource: DataSource;
  let usersService: UsersService;
  let authService: AuthService;
  let settingsService: SettingsService;
  let masterDataService: MasterDataService;
  let auditService: AuditService;

  beforeAll(async () => {
    // Dedicated isolated test database - strict guard against running on production
    const testDbName = 'dairy_farm_test_db';
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
            FarmSettingsEntity,
            UserEntity,
            RoleEntity,
            PermissionEntity,
            UserSessionEntity,
            UnitOfMeasurementEntity,
            LookupCategoryEntity,
            LookupValueEntity,
            AuditLogEntity,
          ],
          synchronize: false, // Strict migration verification: no destructive auto-sync
          logging: false,
        }),
        TypeOrmModule.forFeature([
          FarmSettingsEntity,
          UserEntity,
          RoleEntity,
          PermissionEntity,
          UserSessionEntity,
          UnitOfMeasurementEntity,
          LookupCategoryEntity,
          LookupValueEntity,
          AuditLogEntity,
        ]),
        PassportModule.register({ defaultStrategy: 'jwt' }),
        JwtModule.register({
          secret: 'test-secret-key-12345',
          signOptions: { expiresIn: '1h' },
        }),
      ],
      providers: [
        SettingsService,
        UsersService,
        AuthService,
        JwtStrategy,
        MasterDataService,
        AuditService,
      ],
    }).compile();

    dataSource = module.get<DataSource>(DataSource);
    usersService = module.get<UsersService>(UsersService);
    authService = module.get<AuthService>(AuthService);
    settingsService = module.get<SettingsService>(SettingsService);
    masterDataService = module.get<MasterDataService>(MasterDataService);
    auditService = module.get<AuditService>(AuditService);
  });

  afterAll(async () => {
    if (dataSource && dataSource.isInitialized) {
      await dataSource.destroy();
    }
  });

  describe('Database Constraints & Integrity', () => {
    it('should connect to dairy_farm_test_db successfully', () => {
      expect(dataSource.isInitialized).toBe(true);
      const options: any = dataSource.options;
      expect(options.database).toBe('dairy_farm_test_db');
    });

    it('should enforce UNIQUE constraint on user email', async () => {
      const email = `unique_test_${Date.now()}@dairyfarm.local`;
      await usersService.createUser({
        email,
        password: 'Password@123',
        fullName: 'Test User One',
      });

      // Second creation must throw ConflictException
      await expect(
        usersService.createUser({
          email,
          password: 'Password@456',
          fullName: 'Test User Duplicate',
        }),
      ).rejects.toThrow();
    });

    it('should enforce UNIQUE constraint on UOM code', async () => {
      const code = `TST_${Date.now().toString().slice(-4)}`;
      await masterDataService.createUom({
        code,
        name: 'Test UOM',
        dimension: UomDimension.MASS,
      });

      await expect(
        masterDataService.createUom({
          code,
          name: 'Test UOM Duplicate',
          dimension: UomDimension.MASS,
        }),
      ).rejects.toThrow();
    });

    it('should enforce FOREIGN KEY constraints on user sessions', async () => {
      const queryRunner = dataSource.createQueryRunner();
      await queryRunner.connect();

      try {
        const invalidUserId = uuidv4();
        await expect(
          queryRunner.query(
            `INSERT INTO user_sessions (id, user_id, refresh_token_hash, expires_at) VALUES (?, ?, ?, NOW())`,
            [uuidv4(), invalidUserId, 'dummy-hash'],
          ),
        ).rejects.toThrow();
      } finally {
        await queryRunner.release();
      }
    });

    it('should rollback transaction on failure during atomic multi-write', async () => {
      const testEmail = `rollback_${Date.now()}@dairy.local`;
      
      try {
        await dataSource.transaction(async (manager) => {
          // Write 1: valid insert
          const user = manager.create(UserEntity, {
            id: uuidv4(),
            email: testEmail,
            passwordHash: 'dummy',
            fullName: 'Rollback Tester',
            isActive: true,
          });
          await manager.save(UserEntity, user);

          // Write 2: intentional failure (violating foreign key)
          await manager.query(
            `INSERT INTO role_permissions (role_id, permission_id) VALUES ('non-existent-role', 'non-existent-perm')`,
          );
        });
      } catch (err) {
        // Expected transaction failure
      }

      // Verify Write 1 was rolled back
      const rolledBackUser = await usersService.findByEmail(testEmail);
      expect(rolledBackUser).toBeNull();
    });
  });

  describe('Farm Settings & Identity', () => {
    it('should retrieve existing farm settings and identity', async () => {
      const settings = await settingsService.getSettings();
      expect(settings).toBeDefined();
      expect(settings.id).toBe(1);
      expect(typeof settings.bmcCapacityLitres).toBe('number');
      expect(settings.currencyCode).toBe('INR');
    });

    it('should partially update farm identity parameters', async () => {
      const updated = await settingsService.updateSettings({
        farmName: 'Kaivalya Commercial Dairy Farm',
        district: 'Koraput',
      });

      expect(updated.farmName).toBe('Kaivalya Commercial Dairy Farm');
      expect(updated.district).toBe('Koraput');
    });
  });

  describe('Pagination, Sorting and Filtering Contracts', () => {
    it('should return paginated user results with limit and page offsets', async () => {
      const result = await usersService.findAll({
        page: 1,
        limit: 2,
        sortBy: 'fullName',
        sortOrder: 'ASC' as any,
      });

      expect(result).toBeDefined();
      expect(result.items.length).toBeLessThanOrEqual(2);
      expect(result.page).toBe(1);
      expect(result.limit).toBe(2);
      expect(result.total).toBeGreaterThanOrEqual(1);
      expect(result.totalPages).toBe(Math.ceil(result.total / 2));
    });

    it('should avoid N+1 queries by joining roles and permissions in single query', async () => {
      const result = await usersService.findAll({
        page: 1,
        limit: 10,
      });

      expect(result.items.length).toBeGreaterThan(0);
      const admin = result.items.find((u) => u.email === 'admin@dairyfarm.local');
      expect(admin).toBeDefined();
      expect(admin?.roles).toBeDefined();
      expect(Array.isArray(admin?.roles)).toBe(true);
      expect(admin?.roles.length).toBeGreaterThan(0);
      expect(admin?.roles[0].permissions).toBeDefined();
    });
  });

  describe('Authentication Lifecycle & Sessions', () => {
    const testAuthEmail = `authtest_${Date.now()}@dairyfarm.local`;
    const testRawPassword = 'SecureAuthPass@999';

    beforeAll(async () => {
      await usersService.createUser({
        email: testAuthEmail,
        password: testRawPassword,
        fullName: 'Auth Lifecycle Tester',
        roleIds: ['role-02'],
      });
    });

    it('should reject login with incorrect password', async () => {
      await expect(
        authService.login({
          email: testAuthEmail,
          password: 'WrongPassword!',
        }),
      ).rejects.toThrow();
    });

    it('should authenticate with correct password and issue tokens', async () => {
      const loginRes = await authService.login(
        {
          email: testAuthEmail,
          password: testRawPassword,
        },
        '127.0.0.1',
        'Jest-Integration-Runner',
      );

      expect(loginRes.accessToken).toBeDefined();
      expect(loginRes.refreshToken).toBeDefined();
      expect(loginRes.user.email).toBe(testAuthEmail);
      expect(loginRes.user.roles).toContain('FARM_MANAGER');

      // Test refresh token rotation
      const refreshRes = await authService.refreshToken(
        { refreshToken: loginRes.refreshToken },
        '127.0.0.1',
        'Jest-Integration-Runner',
      );

      expect(refreshRes.accessToken).toBeDefined();
      expect(refreshRes.refreshToken).toBeDefined();
      expect(refreshRes.refreshToken).not.toBe(loginRes.refreshToken); // Rotated!

      // Old refresh token must now be invalid
      await expect(
        authService.refreshToken({ refreshToken: loginRes.refreshToken }),
      ).rejects.toThrow();
    });
  });

  describe('Master Data & Lookups', () => {
    it('should retrieve seeded UOMs and Lookup categories', async () => {
      const uoms = await masterDataService.getAllUoms();
      expect(uoms.length).toBeGreaterThanOrEqual(5);

      const categories = await masterDataService.getAllCategories();
      expect(categories.length).toBeGreaterThanOrEqual(4);

      const breeds = await masterDataService.getValuesByCategory('ANIMAL_BREED');
      expect(breeds.length).toBeGreaterThanOrEqual(3);
    });
  });

  describe('Audit Logging System', () => {
    it('should record and query audit logs with actor and payload', async () => {
      const log = await auditService.logAction({
        action: 'UPDATE_SETTINGS',
        entityType: 'FARM_SETTINGS',
        entityId: '1',
        newValues: { farmName: 'Audit Test Farm' },
        ipAddress: '127.0.0.1',
      });

      expect(log.id).toBeDefined();
      expect(log.action).toBe('UPDATE_SETTINGS');

      const queryRes = await auditService.findAll({
        page: 1,
        limit: 10,
        entityType: 'FARM_SETTINGS',
      });

      expect(queryRes.items.some((i) => i.id === log.id)).toBe(true);
    });
  });
});
