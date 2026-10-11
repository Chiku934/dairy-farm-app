import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../app.module';

describe('Phase 5: Dashboard Overview API & RBAC Integration Tests', () => {
  let app: INestApplication;
  let adminToken: string;
  let storekeeperToken: string;

  beforeAll(async () => {
    process.env.DB_DATABASE = 'dairy_farm_test_db';

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.setGlobalPrefix('api/v1');
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );
    await app.init();

    // 1. Obtain Admin Token (Full Access)
    const adminLogin = await request(app.getHttpServer())
      .post('/api/v1/auth/login')
      .send({
        email: 'admin@dairyfarm.local',
        password: 'Password@123',
      });
    expect([200, 201]).toContain(adminLogin.status);
    adminToken = adminLogin.body.data?.accessToken || adminLogin.body.accessToken;

    // 2. Obtain Storekeeper Token (Operational, No Finance Access)
    const storeLogin = await request(app.getHttpServer())
      .post('/api/v1/auth/login')
      .send({
        email: 'store@dairyfarm.local',
        password: 'Password@123',
      });
    expect([200, 201]).toContain(storeLogin.status);
    storekeeperToken = storeLogin.body.data?.accessToken || storeLogin.body.accessToken;
  });

  afterAll(async () => {
    if (app) {
      await app.close();
    }
  });

  describe('GET /api/v1/dashboard/overview - Admin Access (Full Data & Calculations)', () => {
    it('should return 200 with full KPIs, alerts, herd count and bmc status for today', async () => {
      const res = await request(app.getHttpServer())
        .get('/api/v1/dashboard/overview?period=today')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
      const data = res.body;

      // Period info
      expect(data.period.type).toBe('today');
      expect(data.period.startDate).toBeDefined();
      expect(data.period.endDate).toBeDefined();

      // Milk Recorded KPI
      // Eligible cows today: c-01 (13.5+11.0), c-02 (10+8.5), c-03 (8+6.5) = 57.50 L
      // (c-04 withheld milk 17.0 L must be excluded!)
      expect(data.kpis.milkRecorded.value).toBe(57.5);
      expect(data.kpis.milkRecorded.unit).toBe('L');
      expect(data.kpis.milkRecorded.amYield).toBe(31.5);
      expect(data.kpis.milkRecorded.pmYield).toBe(26.0);

      // Dry Fertiliser KPI (bio-01 today has 75 kg)
      expect(data.kpis.dryFertiliser.value).toBe(75.0);
      expect(data.kpis.dryFertiliser.unit).toBe('kg');

      // Sales Revenue (dsp-01 2560 + dsp-02 180 = 2740)
      expect(data.kpis.salesRevenue).not.toBeNull();
      expect(data.kpis.salesRevenue.value).toBe(2740.0);
      expect(data.kpis.salesRevenue.currency).toBe('₹');

      // Operating Cost
      expect(data.kpis.operatingCost).not.toBeNull();
      expect(data.kpis.operatingCost.value).toBeGreaterThan(0);

      // Cost per Litre calculation
      expect(data.kpis.costPerLitre.status).toBe('CALCULATED');
      expect(data.kpis.costPerLitre.value).toBeGreaterThan(0);
      expect(data.kpis.costPerLitre.value).toBe(
        Number((data.kpis.operatingCost.value / data.kpis.milkRecorded.value).toFixed(2)),
      );

      // Herd Breakdown
      expect(data.herd.totalActive).toBe(9);
      expect(data.herd.lactating).toBe(4);
      expect(data.herd.dry).toBe(1);
      expect(data.herd.pregnant).toBe(1);

      // BMC Tank Status
      expect(data.bmcTank.capacityLitres).toBe(2000);
      expect(data.bmcTank.currentBalanceLitres).toBeGreaterThan(0);
      expect(data.bmcTank.utilizationPercent).toBeGreaterThan(0);

      // Alerts
      expect(data.alerts.totalCount).toBeGreaterThan(0);
      const alertTypes = data.alerts.items.map((a: any) => a.type);
      expect(alertTypes).toContain('EXPIRING_LICENCE');
      expect(alertTypes).toContain('LOW_INVENTORY');
      expect(alertTypes).toContain('WITHDRAWAL_WARNING');

      // Trends & Activity
      expect(Array.isArray(data.trends.dailyYields)).toBe(true);
      expect(Array.isArray(data.trends.dailyRevenue)).toBe(true);
      expect(data.recentActivity.length).toBeGreaterThan(0);
    });

    it('should support week filter and calculate period comparison', async () => {
      const res = await request(app.getHttpServer())
        .get('/api/v1/dashboard/overview?period=week')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.period.type).toBe('week');
      expect(res.body.kpis.milkRecorded.value).toBeGreaterThan(57.5); // Includes past days
    });

    it('should handle custom date range with 0 entries smoothly (empty state test)', async () => {
      const res = await request(app.getHttpServer())
        .get('/api/v1/dashboard/overview?period=custom&startDate=2015-01-01&endDate=2015-01-02')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.kpis.milkRecorded.value).toBe(0);
      expect(res.body.kpis.dryFertiliser.value).toBe(0);
      expect(res.body.kpis.salesRevenue.value).toBe(0);
      // Cost per litre with 0 milk must be INCOMPLETE
      expect(res.body.kpis.costPerLitre.status).toBe('INCOMPLETE');
      expect(res.body.kpis.costPerLitre.value).toBeNull();
    });
  });

  describe('GET /api/v1/dashboard/overview - RBAC Financial Data Protection', () => {
    it('should redact sales revenue and operating cost for Storekeeper lacking finance permission', async () => {
      const res = await request(app.getHttpServer())
        .get('/api/v1/dashboard/overview?period=today')
        .set('Authorization', `Bearer ${storekeeperToken}`);

      expect(res.status).toBe(200);
      const data = res.body;

      // Operational metrics remain visible
      expect(data.kpis.milkRecorded.value).toBe(57.5);
      expect(data.kpis.dryFertiliser.value).toBe(75.0);
      expect(data.herd.totalActive).toBe(9);
      expect(data.bmcTank.currentBalanceLitres).toBeGreaterThan(0);

      // Financial fields MUST be null / restricted
      expect(data.kpis.salesRevenue).toBeNull();
      expect(data.kpis.operatingCost).toBeNull();
      expect(data.kpis.costPerLitre.status).toBe('RESTRICTED');
      expect(data.kpis.costPerLitre.value).toBeNull();
      expect(data.trends.dailyRevenue).toBeUndefined();
    });
  });

  describe('POST /api/v1/dashboard/invalidate-cache - Cache Management & Authorization', () => {
    it('should allow Farm Owner to invalidate the cache', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/v1/dashboard/invalidate-cache')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.message).toContain('invalidated');
    });

    it('should reject Storekeeper from calling cache invalidation (403 Forbidden)', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/v1/dashboard/invalidate-cache')
        .set('Authorization', `Bearer ${storekeeperToken}`);

      expect(res.status).toBe(403);
    });
  });
});
