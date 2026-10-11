import { Test, TestingModule } from '@nestjs/testing';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { JwtModule, JwtService } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import {
  UnauthorizedException,
  ForbiddenException,
  HttpStatus,
  ExecutionContext,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';

import { UserEntity } from '../modules/users/entities/user.entity';
import { RoleEntity } from '../modules/users/entities/role.entity';
import { PermissionEntity } from '../modules/users/entities/permission.entity';
import { UserSessionEntity } from '../modules/auth/entities/user-session.entity';
import { FarmSettingsEntity } from '../modules/settings/entities/farm-settings.entity';
import { UnitOfMeasurementEntity } from '../modules/master-data/entities/unit-of-measurement.entity';
import { LookupCategoryEntity } from '../modules/master-data/entities/lookup-category.entity';
import { LookupValueEntity } from '../modules/master-data/entities/lookup-value.entity';
import { AuditLogEntity } from '../modules/audit/entities/audit-log.entity';

import { UsersService } from '../modules/users/users.service';
import { AuthService } from '../modules/auth/auth.service';
import { AuditService } from '../modules/audit/audit.service';
import { JwtStrategy } from '../modules/auth/jwt.strategy';
import { JwtAuthGuard } from '../modules/auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '../common/guards/permissions.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { RateLimitGuard } from '../common/guards/rate-limit.guard';

describe('Auth & RBAC Integration Tests (Security Suite)', () => {
  let module: TestingModule;
  let dataSource: DataSource;
  let usersService: UsersService;
  let authService: AuthService;
  let jwtService: JwtService;
  let permissionsGuard: PermissionsGuard;
  let rolesGuard: RolesGuard;
  let rateLimitGuard: RateLimitGuard;
  let reflector: Reflector;

  const adminEmail = `admin_sec_${Date.now()}@dairyfarm.local`;
  const adminPassword = 'AdminSecurePassword@123';

  beforeAll(async () => {
    // Isolated dedicated test database
    module = await Test.createTestingModule({
      imports: [
        TypeOrmModule.forRoot({
          type: 'mysql',
          host: process.env.DB_HOST || '127.0.0.1',
          port: parseInt(process.env.DB_PORT || '3306', 10),
          username: process.env.DB_USERNAME || 'root',
          password: process.env.DB_PASSWORD || '',
          database: 'dairy_farm_test_db',
          entities: [
            UserEntity,
            RoleEntity,
            PermissionEntity,
            UserSessionEntity,
            FarmSettingsEntity,
            UnitOfMeasurementEntity,
            LookupCategoryEntity,
            LookupValueEntity,
            AuditLogEntity,
          ],
          synchronize: false,
          logging: false,
        }),
        TypeOrmModule.forFeature([
          UserEntity,
          RoleEntity,
          PermissionEntity,
          UserSessionEntity,
          FarmSettingsEntity,
          UnitOfMeasurementEntity,
          LookupCategoryEntity,
          LookupValueEntity,
          AuditLogEntity,
        ]),
        PassportModule.register({ defaultStrategy: 'jwt' }),
        JwtModule.register({
          secret: 'test-secret-key-12345',
          signOptions: { expiresIn: '15m' },
        }),
      ],
      providers: [
        UsersService,
        AuthService,
        AuditService,
        JwtStrategy,
        JwtAuthGuard,
        PermissionsGuard,
        RolesGuard,
        RateLimitGuard,
      ],
    }).compile();

    dataSource = module.get<DataSource>(DataSource);
    usersService = module.get<UsersService>(UsersService);
    authService = module.get<AuthService>(AuthService);
    jwtService = module.get<JwtService>(JwtService);
    permissionsGuard = module.get<PermissionsGuard>(PermissionsGuard);
    rolesGuard = module.get<RolesGuard>(RolesGuard);
    rateLimitGuard = module.get<RateLimitGuard>(RateLimitGuard);
    reflector = module.get<Reflector>(Reflector);

    // Create self-contained admin user with FARM_OWNER role
    await usersService.createUser({
      email: adminEmail,
      password: adminPassword,
      fullName: 'Security Suite Admin',
      roleIds: ['role-01'],
    });
  });

  beforeEach(() => {
    RateLimitGuard.resetTrackers();
  });

  afterAll(async () => {
    if (dataSource && dataSource.isInitialized) {
      await dataSource.destroy();
    }
  });

  describe('Credential Security & Authentication Flow', () => {
    it('should reject invalid credentials with 401 Unauthorized', async () => {
      await expect(
        authService.login({
          email: adminEmail,
          password: 'IncorrectPassword!',
        }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('should issue a short-lived access token and rotating refresh token', async () => {
      const res = await authService.login({
        email: adminEmail,
        password: adminPassword,
      });

      expect(res.accessToken).toBeDefined();
      expect(res.refreshToken).toBeDefined();
      expect(res.expiresInSeconds).toBe(900); // 15 minutes
      expect(res.user.roles).toContain('FARM_OWNER');
    });

    it('should reject authentication for a deactivated user', async () => {
      const email = `inactive_user_${Date.now()}@dairy.local`;
      const user = await usersService.createUser({
        email,
        password: 'Password@123',
        fullName: 'Inactive Staff Member',
      });

      // Deactivate user
      await usersService.updateStatus(user.id, false);

      await expect(
        authService.login({
          email,
          password: 'Password@123',
        }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('should immediately revoke active sessions upon user deactivation', async () => {
      const email = `session_revoke_${Date.now()}@dairy.local`;
      const user = await usersService.createUser({
        email,
        password: 'Password@123',
        fullName: 'Session Revocation Tester',
      });

      // User logs in and acquires tokens
      const loginRes = await authService.login({
        email,
        password: 'Password@123',
      });

      // Deactivate user
      await usersService.updateStatus(user.id, false);

      // Attempting to refresh with the token must fail immediately
      await expect(
        authService.refreshToken({
          refreshToken: loginRes.refreshToken,
        }),
      ).rejects.toThrow(UnauthorizedException);
    });
  });

  describe('Token Expiry & Signature Validation', () => {
    it('should reject a tampered or invalid JWT signature', async () => {
      const tamperedToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.invalidpayload.invalidsignature';
      
      expect(() => {
        jwtService.verify(tamperedToken);
      }).toThrow();
    });

    it('should reject an expired JWT token', async () => {
      // Create a token that expired 1 second ago
      const expiredToken = jwtService.sign(
        { sub: 'usr-dev-admin', email: adminEmail },
        { expiresIn: '-1s' },
      );

      expect(() => {
        jwtService.verify(expiredToken);
      }).toThrow();
    });
  });

  describe('Rate Limiter Protection on Auth Endpoints', () => {
    it('should enforce rate limits and throw 429 Too Many Requests after 5 attempts', () => {
      const mockContext = (ip: string): ExecutionContext =>
        ({
          switchToHttp: () => ({
            getRequest: () => ({
              ip,
              method: 'POST',
              path: '/api/v1/auth/login',
              headers: {},
              socket: {},
            }),
          }),
          getHandler: () => {},
          getClass: () => {},
        } as any);

      jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue({
        ttlSeconds: 60,
        maxRequests: 5,
      });

      const clientIp = '192.168.1.100';
      const ctx = mockContext(clientIp);

      // 1st to 5th request must pass
      for (let i = 0; i < 5; i++) {
        expect(rateLimitGuard.canActivate(ctx)).toBe(true);
      }

      // 6th request must throw 429
      expect(() => rateLimitGuard.canActivate(ctx)).toThrow(
        expect.objectContaining({
          status: HttpStatus.TOO_MANY_REQUESTS,
        }),
      );
    });
  });

  describe('Role-Based Access Control (RBAC) & Permission Guards', () => {
    it('should allow Super Admin / FARM_OWNER unrestricted access across permissions', () => {
      const mockCtx: ExecutionContext = {
        switchToHttp: () => ({
          getRequest: () => ({
            user: {
              userId: 'usr-dev-admin',
              roles: ['FARM_OWNER'],
              permissions: ['users:read', 'users:write'],
            },
          }),
        }),
        getHandler: () => {},
        getClass: () => {},
      } as any;

      jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue(['users:write', 'finance:write']);

      expect(permissionsGuard.canActivate(mockCtx)).toBe(true);
    });

    it('should deny access (403 Forbidden) when user lacks required permission', () => {
      const mockCtx: ExecutionContext = {
        switchToHttp: () => ({
          getRequest: () => ({
            user: {
              userId: 'usr-dev-store',
              roles: ['STOREKEEPER'],
              permissions: ['inventory:read', 'inventory:write'],
            },
          }),
        }),
        getHandler: () => {},
        getClass: () => {},
      } as any;

      // Endpoint requires 'users:write'
      jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue(['users:write']);

      expect(() => permissionsGuard.canActivate(mockCtx)).toThrow(ForbiddenException);
    });

    it('should verify Read-only Auditor has view permissions but lacks write permissions', async () => {
      const auditor = await usersService.findByEmail('auditor@dairyfarm.local');
      expect(auditor).toBeDefined();

      const permissions = (auditor?.roles || []).flatMap((r) =>
        (r.permissions || []).map((p) => p.code),
      );

      // Auditor must have read permissions
      expect(permissions).toContain('audit:read');
      expect(permissions).toContain('finance:read');
      expect(permissions).toContain('animals:read');

      // Auditor must NOT have write or admin permissions
      expect(permissions).not.toContain('users:write');
      expect(permissions).not.toContain('farm:settings:write');
      expect(permissions).not.toContain('finance:write');
    });
  });
});
