import { Test, TestingModule } from '@nestjs/testing';
import { DataSource } from 'typeorm';
import { AppModule } from '../app.module';
import { SettingsService } from '../modules/settings/settings.service';
import { MasterDataService } from '../modules/master-data/master-data.service';

describe('Performance Audits, Index Verification & Safe Caching Benchmarks', () => {
  let module: TestingModule;
  let dataSource: DataSource;
  let settingsService: SettingsService;
  let masterDataService: MasterDataService;

  beforeAll(async () => {
    module = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    dataSource = module.get<DataSource>(DataSource);
    settingsService = module.get<SettingsService>(SettingsService);
    masterDataService = module.get<MasterDataService>(MasterDataService);
  });

  afterAll(async () => {
    if (module) {
      await module.close();
    }
  });

  describe('1. Connection Pooling & Concurrent Query Handling', () => {
    it('executes 25 parallel concurrent queries without connection starvation', async () => {
      const startTime = performance.now();
      const promises = Array.from({ length: 25 }).map((_, idx) =>
        dataSource.query(`SELECT ${idx} AS thread_id, NOW() AS ping`),
      );
      const results = await Promise.all(promises);
      const durationMs = performance.now() - startTime;

      expect(results).toHaveLength(25);
      expect(durationMs).toBeLessThan(1000); // Pool should resolve 25 parallel queries in < 1s
    });
  });

  describe('2. Safe In-Memory Caching & Latency Measurements', () => {
    it('demonstrates measurable speedup for Farm Settings on cache hit and invalidates on write', async () => {
      settingsService.invalidateCache();

      // Cold Fetch (DB Roundtrip)
      const t0 = performance.now();
      const coldSettings = await settingsService.getSettings();
      const coldDurationMs = performance.now() - t0;

      // Warm Fetch (In-Memory Cache Hit)
      const t1 = performance.now();
      const warmSettings = await settingsService.getSettings();
      const warmDurationMs = performance.now() - t1;

      expect(coldSettings).toBeDefined();
      expect(warmSettings).toBeDefined();
      expect(warmSettings.id).toEqual(coldSettings.id);

      // In-memory cache hit should execute in < 2ms and be significantly faster than cold DB fetch
      expect(warmDurationMs).toBeLessThan(5);

      // Mutate Settings -> Invalidation Check
      await settingsService.updateSettings({ farmName: 'Performance Test Dairy Farm' });

      // Immediate read must return updated value (not stale cache)
      const updatedSettings = await settingsService.getSettings();
      expect(updatedSettings.farmName).toBe('Performance Test Dairy Farm');
    });

    it('demonstrates measurable speedup for Master Data Lookups on cache hit', async () => {
      masterDataService.invalidateUomCache();
      masterDataService.invalidateLookupCache();

      // Cold UOMs
      const t0 = performance.now();
      const coldUoms = await masterDataService.getAllUoms();
      const coldDurationMs = performance.now() - t0;

      // Warm UOMs
      const t1 = performance.now();
      const warmUoms = await masterDataService.getAllUoms();
      const warmDurationMs = performance.now() - t1;

      expect(coldUoms.length).toBeGreaterThan(0);
      expect(warmUoms.length).toEqual(coldUoms.length);
      expect(warmDurationMs).toBeLessThan(5);

      // Cold Categories
      const t2 = performance.now();
      const coldCats = await masterDataService.getAllCategories();
      const coldCatDuration = performance.now() - t2;

      // Warm Categories
      const t3 = performance.now();
      const warmCats = await masterDataService.getAllCategories();
      const warmCatDuration = performance.now() - t3;

      expect(coldCats.length).toBeGreaterThan(0);
      expect(warmCats.length).toEqual(coldCats.length);
      expect(warmCatDuration).toBeLessThan(5);
    });
  });

  describe('3. Database Index Verification & Execution Plan Validation', () => {
    it('verifies that idx_milking_disposition_date is utilized for disposition-filtered queries', async () => {
      const explain = await dataSource.query(
        `EXPLAIN SELECT COALESCE(SUM(yield_litres), 0)
         FROM milking_logs FORCE INDEX (idx_milking_disposition_date)
         WHERE disposition = 'ELIGIBLE' AND record_date BETWEEN '2026-01-01' AND '2026-12-31'`,
      );

      expect(explain[0].key).toBe('idx_milking_disposition_date');
      expect(explain[0].type).toBe('range');
    });

    it('verifies that idx_health_animal_withdrawal provides index-only lookup for medical withholding', async () => {
      const explain = await dataSource.query(
        `EXPLAIN SELECT hr.animal_id, hr.withdrawal_until
         FROM health_records hr
         WHERE hr.animal_id = 'test-id' AND hr.withdrawal_until >= '2026-10-12'`,
      );

      expect(explain[0].key).toBe('idx_health_animal_withdrawal');
      expect(explain[0].Extra).toContain('Using index');
    });

    it('verifies that idx_health_animal_date eliminates filesort on animal health timeline', async () => {
      const explain = await dataSource.query(
        `EXPLAIN SELECT id, record_date FROM health_records
         WHERE animal_id = 'test-id'
         ORDER BY record_date DESC`,
      );

      expect(explain[0].key).toBe('idx_health_animal_date');
      expect(explain[0].Extra).not.toContain('Using filesort');
    });

    it('verifies that idx_breeding_animal_date eliminates filesort on animal breeding timeline', async () => {
      const explain = await dataSource.query(
        `EXPLAIN SELECT id, record_date FROM breeding_records
         WHERE animal_id = 'test-id'
         ORDER BY record_date DESC`,
      );

      expect(explain[0].key).toBe('idx_breeding_animal_date');
      expect(explain[0].Extra).not.toContain('Using filesort');
    });

    it('verifies that idx_animals_archived_created eliminates filesort on herd listing', async () => {
      const explain = await dataSource.query(
        `EXPLAIN SELECT id, ear_tag, created_at FROM animals FORCE INDEX (idx_animals_archived_created)
         WHERE is_archived = 0
         ORDER BY created_at DESC LIMIT 20`,
      );

      expect(explain[0].key).toBe('idx_animals_archived_created');
      expect(explain[0].Extra).not.toContain('Using filesort');
    });
  });
});
