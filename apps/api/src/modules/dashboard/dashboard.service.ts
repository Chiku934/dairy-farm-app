import { Injectable, Logger } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { DashboardPeriod, DashboardQueryDto } from './dto/dashboard-query.dto';
import {
  DashboardOverviewResponse,
  KpiMetric,
  CostPerLitreMetric,
  HerdSummary,
  BmcStatus,
  DashboardAlert,
  DailyYieldTrend,
  DailyRevenueTrend,
  RecentActivityItem,
} from './dto/dashboard-overview.dto';
import { AuthenticatedUser } from '../../common/decorators/current-user.decorator';

interface CacheEntry {
  timestamp: number;
  data: DashboardOverviewResponse;
}

@Injectable()
export class DashboardService {
  private readonly logger = new Logger(DashboardService.name);
  private readonly cache = new Map<string, CacheEntry>();
  private readonly CACHE_TTL_MS = 60 * 1000; // 60 seconds

  constructor(private readonly dataSource: DataSource) {}

  /**
   * Clears the in-memory dashboard cache
   */
  invalidateCache(): void {
    this.logger.log('Invalidating dashboard in-memory cache');
    this.cache.clear();
  }

  /**
   * Retrieves aggregated dashboard overview based on date filter and caller's RBAC profile
   */
  async getOverview(
    query: DashboardQueryDto,
    user: AuthenticatedUser,
  ): Promise<DashboardOverviewResponse> {
    const hasFinanceAccess = this.checkFinanceAccess(user);
    const { currentRange, priorRange, label } = this.resolveDateRanges(query);

    const cacheKey = `dash:${query.period || 'today'}:${currentRange.start}:${currentRange.end}:${hasFinanceAccess}`;
    const cached = this.cache.get(cacheKey);
    const now = Date.now();

    if (cached && now - cached.timestamp < this.CACHE_TTL_MS) {
      return cached.data;
    }

    // 1. Milk Recorded Aggregation
    const milkCurrent = await this.getMilkRecorded(currentRange.start, currentRange.end);
    const milkPrior = await this.getMilkRecorded(priorRange.start, priorRange.end);
    const milkDelta = this.calculateDelta(milkCurrent.total, milkPrior.total);

    const milkMetric: KpiMetric<number> = {
      value: Number(milkCurrent.total.toFixed(2)),
      unit: 'L',
      label: 'Milk Recorded',
      priorValue: Number(milkPrior.total.toFixed(2)),
      deltaPercent: milkDelta,
      amYield: Number(milkCurrent.am.toFixed(2)),
      pmYield: Number(milkCurrent.pm.toFixed(2)),
    };

    // 2. Dry Fertiliser Aggregation
    const fertiliserCurrent = await this.getFertiliserOutput(currentRange.start, currentRange.end);
    const fertiliserPrior = await this.getFertiliserOutput(priorRange.start, priorRange.end);
    const fertiliserDelta = this.calculateDelta(fertiliserCurrent, fertiliserPrior);

    const fertiliserMetric: KpiMetric<number> = {
      value: Number(fertiliserCurrent.toFixed(2)),
      unit: 'kg',
      label: 'Dry Fertiliser Output',
      priorValue: Number(fertiliserPrior.toFixed(2)),
      deltaPercent: fertiliserDelta,
    };

    // 3. Sales Revenue & Operating Cost (Protected by RBAC)
    let salesRevenueMetric: KpiMetric<number> | null = null;
    let operatingCostMetric: KpiMetric<number> | null = null;
    let costPerLitreMetric: CostPerLitreMetric;

    if (hasFinanceAccess) {
      const salesCurrent = await this.getSalesRevenue(currentRange.start, currentRange.end);
      const salesPrior = await this.getSalesRevenue(priorRange.start, priorRange.end);
      const salesDelta = this.calculateDelta(salesCurrent, salesPrior);

      salesRevenueMetric = {
        value: Number(salesCurrent.toFixed(2)),
        currency: '₹',
        label: 'Sales Revenue',
        priorValue: Number(salesPrior.toFixed(2)),
        deltaPercent: salesDelta,
      };

      const costCurrent = await this.getOperatingCost(currentRange.start, currentRange.end);
      const costPrior = await this.getOperatingCost(priorRange.start, priorRange.end);
      const costDelta = this.calculateDelta(costCurrent, costPrior);

      operatingCostMetric = {
        value: Number(costCurrent.toFixed(2)),
        currency: '₹',
        label: 'Operating Cost',
        priorValue: Number(costPrior.toFixed(2)),
        deltaPercent: costDelta,
      };

      // Cost per litre formula: Daily Farm Cost / Eligible Milk Recorded
      if (milkCurrent.total > 0) {
        const cpl = Number((costCurrent / milkCurrent.total).toFixed(2));
        costPerLitreMetric = {
          value: cpl,
          currency: '₹',
          label: 'Cost per Litre',
          status: 'CALCULATED',
          formulaExplanation: `₹${costCurrent.toFixed(2)} total cost / ${milkCurrent.total.toFixed(2)} L milk`,
        };
      } else {
        costPerLitreMetric = {
          value: null,
          currency: '₹',
          label: 'Cost per Litre',
          status: 'INCOMPLETE',
          formulaExplanation: 'No eligible milk recorded for selected period (Status: Incomplete)',
        };
      }
    } else {
      costPerLitreMetric = {
        value: null,
        currency: '₹',
        label: 'Cost per Litre',
        status: 'RESTRICTED',
        formulaExplanation: 'Financial records restricted to authorized roles',
      };
    }

    // 4. Herd Summary
    const herd = await this.getHerdSummary();

    // 5. BMC Live Status
    const bmcTank = await this.getBmcStatus();

    // 6. Active Alerts
    const alerts = await this.getActiveAlerts();

    // 7. Trends
    const dailyYields = await this.getDailyYieldTrends(currentRange.start, currentRange.end);
    let dailyRevenue: DailyRevenueTrend[] | undefined = undefined;
    if (hasFinanceAccess) {
      dailyRevenue = await this.getDailyRevenueTrends(currentRange.start, currentRange.end);
    }

    // 8. Recent Activity Feed
    const recentActivity = await this.getRecentActivity();

    const response: DashboardOverviewResponse = {
      period: {
        type: query.period || DashboardPeriod.TODAY,
        startDate: currentRange.start,
        endDate: currentRange.end,
        label,
      },
      kpis: {
        milkRecorded: milkMetric,
        dryFertiliser: fertiliserMetric,
        salesRevenue: salesRevenueMetric,
        operatingCost: operatingCostMetric,
        costPerLitre: costPerLitreMetric,
      },
      herd,
      bmcTank,
      alerts,
      trends: {
        dailyYields,
        dailyRevenue,
      },
      recentActivity,
    };

    this.cache.set(cacheKey, { timestamp: now, data: response });
    return response;
  }

  // --------------------------------------------------------------------------
  // Aggregation Queries
  // --------------------------------------------------------------------------

  private async getMilkRecorded(
    start: string,
    end: string,
  ): Promise<{ total: number; am: number; pm: number }> {
    const raw = await this.dataSource.query(
      `SELECT
         COALESCE(SUM(yield_litres), 0) AS total_yield,
         COALESCE(SUM(CASE WHEN session = 'MORNING' THEN yield_litres ELSE 0 END), 0) AS am_yield,
         COALESCE(SUM(CASE WHEN session = 'EVENING' THEN yield_litres ELSE 0 END), 0) AS pm_yield
       FROM milking_logs
       WHERE disposition = 'ELIGIBLE'
         AND record_date BETWEEN ? AND ?`,
      [start, end],
    );

    return {
      total: Number(raw[0]?.total_yield || 0),
      am: Number(raw[0]?.am_yield || 0),
      pm: Number(raw[0]?.pm_yield || 0),
    };
  }

  private async getFertiliserOutput(start: string, end: string): Promise<number> {
    const raw = await this.dataSource.query(
      `SELECT COALESCE(SUM(dry_fertiliser_output_kg), 0) AS total_fertiliser
       FROM biogas_runs
       WHERE record_date BETWEEN ? AND ?`,
      [start, end],
    );
    return Number(raw[0]?.total_fertiliser || 0);
  }

  private async getSalesRevenue(start: string, end: string): Promise<number> {
    const raw = await this.dataSource.query(
      `SELECT COALESCE(SUM(total_amount), 0) AS total_revenue
       FROM sales_dispatches
       WHERE record_date BETWEEN ? AND ?`,
      [start, end],
    );
    return Number(raw[0]?.total_revenue || 0);
  }

  /**
   * Approved Cost Formula:
   * Feed consumed + Medicines/Materials + Farm Salaries + Electricity + Operating Expenses
   */
  private async getOperatingCost(start: string, end: string): Promise<number> {
    // 1. Operating Expenses (FARM or unlinked)
    const expRaw = await this.dataSource.query(
      `SELECT COALESCE(SUM(amount), 0) AS exp_total
       FROM operating_expenses
       WHERE cost_centre = 'FARM'
         AND record_date BETWEEN ? AND ?`,
      [start, end],
    );
    const expensesTotal = Number(expRaw[0]?.exp_total || 0);

    // 2. Electricity Readings
    const elecRaw = await this.dataSource.query(
      `SELECT COALESCE(SUM(total_cost), 0) AS elec_total
       FROM electricity_readings
       WHERE department = 'FARM'
         AND record_date BETWEEN ? AND ?`,
      [start, end],
    );
    const electricityTotal = Number(elecRaw[0]?.elec_total || 0);

    // 3. Feed entries consumed (kg * weighted average price)
    const feedRaw = await this.dataSource.query(
      `SELECT COALESCE(SUM(f.quantity_kg * s.weighted_avg_price), 0) AS feed_total
       FROM feed_entries f
       JOIN stock_items s ON f.stock_item_id = s.id
       WHERE f.record_date BETWEEN ? AND ?`,
      [start, end],
    );
    const feedTotal = Number(feedRaw[0]?.feed_total || 0);

    // 4. Daily salaries for days in range
    // Days in interval:
    const daysInterval = Math.max(
      1,
      Math.round(
        (new Date(end).getTime() - new Date(start).getTime()) / (1000 * 60 * 60 * 24),
      ) + 1,
    );

    // Farm settings management overhead split percentage
    const settingsRaw = await this.dataSource.query(
      `SELECT mgmt_salary_to_farm_pct FROM farm_settings WHERE id = 1 LIMIT 1`,
    );
    const mgmtSplitPct = Number(settingsRaw[0]?.mgmt_salary_to_farm_pct || 50) / 100.0;

    const salaryRaw = await this.dataSource.query(
      `SELECT
         COALESCE(SUM(CASE WHEN department = 'FARM' THEN daily_salary_rate ELSE 0 END), 0) AS farm_daily,
         COALESCE(SUM(CASE WHEN department = 'MANAGEMENT' THEN daily_salary_rate ELSE 0 END), 0) AS mgmt_daily
       FROM employees
       WHERE is_active = 1`,
    );

    const farmDaily = Number(salaryRaw[0]?.farm_daily || 0);
    const mgmtDaily = Number(salaryRaw[0]?.mgmt_daily || 0) * mgmtSplitPct;
    const dailyPayroll = (farmDaily + mgmtDaily) * daysInterval;

    return expensesTotal + electricityTotal + feedTotal + dailyPayroll;
  }

  private async getHerdSummary(): Promise<HerdSummary> {
    const raw = await this.dataSource.query(
      `SELECT status, COUNT(*) AS count
       FROM animals
       WHERE status NOT IN ('SOLD', 'DECEASED')
       GROUP BY status`,
    );

    let lactating = 0;
    let dry = 0;
    let pregnant = 0;
    let heifersCalves = 0;
    let bulls = 0;

    for (const row of raw) {
      const c = Number(row.count);
      switch (row.status) {
        case 'LACTATING':
          lactating += c;
          break;
        case 'DRY':
          dry += c;
          break;
        case 'PREGNANT':
          pregnant += c;
          break;
        case 'HEIFER':
        case 'CALF':
          heifersCalves += c;
          break;
        case 'BULL':
          bulls += c;
          break;
      }
    }

    const totalActive = lactating + dry + pregnant + heifersCalves + bulls;
    return {
      totalActive,
      lactating,
      dry,
      pregnant,
      heifersCalves,
      bulls,
    };
  }

  private async getBmcStatus(): Promise<BmcStatus> {
    const settings = await this.dataSource.query(
      `SELECT bmc_capacity_litres FROM farm_settings WHERE id = 1 LIMIT 1`,
    );
    const capacity = Number(settings[0]?.bmc_capacity_litres || 2000);

    const intakeRaw = await this.dataSource.query(
      `SELECT COALESCE(SUM(quantity_litres), 0) AS accepted_litres
       FROM bmc_intake_logs
       WHERE decision = 'ACCEPTED'`,
    );
    const intake = Number(intakeRaw[0]?.accepted_litres || 0);

    const prodRaw = await this.dataSource.query(
      `SELECT COALESCE(SUM(bmc_milk_consumed_l), 0) AS consumed_litres
       FROM production_batches`,
    );
    const consumed = Number(prodRaw[0]?.consumed_litres || 0);

    const wasteRaw = await this.dataSource.query(
      `SELECT COALESCE(SUM(quantity_lost), 0) AS lost_litres
       FROM wastage_records
       WHERE stock_type = 'BMC'`,
    );
    const lost = Number(wasteRaw[0]?.lost_litres || 0);

    const balance = Math.max(0, intake - consumed - lost);
    const utilization = Number(((balance / capacity) * 100).toFixed(1));

    let status: 'NORMAL' | 'WARNING' | 'CRITICAL' = 'NORMAL';
    if (utilization >= 90) {
      status = 'CRITICAL';
    } else if (utilization >= 75) {
      status = 'WARNING';
    }

    return {
      capacityLitres: capacity,
      currentBalanceLitres: Number(balance.toFixed(2)),
      utilizationPercent: utilization,
      status,
    };
  }

  private async getActiveAlerts(): Promise<{ totalCount: number; items: DashboardAlert[] }> {
    const items: DashboardAlert[] = [];

    // 1. Expiring Licences (within reminder_days_before or 30 days)
    const licences = await this.dataSource.query(
      `SELECT id, licence_name, licence_number, expiry_date,
              DATEDIFF(expiry_date, CURDATE()) AS days_left
       FROM regulatory_licences
       WHERE status != 'EXPIRED'
         AND expiry_date <= DATE_ADD(CURDATE(), INTERVAL reminder_days_before DAY)
       ORDER BY expiry_date ASC LIMIT 5`,
    );

    for (const lic of licences) {
      const days = Number(lic.days_left);
      items.push({
        id: `alert-lic-${lic.id}`,
        type: 'EXPIRING_LICENCE',
        severity: days <= 10 ? 'CRITICAL' : 'WARNING',
        title: 'Regulatory Licence Expiring Soon',
        description: `${lic.licence_name} (${lic.licence_number}) expires in ${days} days.`,
        daysRemaining: days,
      });
    }

    // 2. Low Stock Reorder Alerts
    const lowStock = await this.dataSource.query(
      `SELECT id, name, current_stock, unit, reorder_level
       FROM stock_items
       WHERE current_stock <= reorder_level
       ORDER BY current_stock ASC LIMIT 5`,
    );

    for (const stk of lowStock) {
      items.push({
        id: `alert-stk-${stk.id}`,
        type: 'LOW_INVENTORY',
        severity: Number(stk.current_stock) === 0 ? 'CRITICAL' : 'WARNING',
        title: 'Low Inventory Reorder Alert',
        description: `${stk.name} stock (${stk.current_stock} ${stk.unit}) is at or below reorder level (${stk.reorder_level} ${stk.unit}).`,
      });
    }

    // 3. Milk Safety Withdrawal Period Warnings
    const healthAlerts = await this.dataSource.query(
      `SELECT h.id, a.ear_tag, a.name AS cow_name, h.medicine_vaccine, h.withdrawal_until,
              DATEDIFF(h.withdrawal_until, CURDATE()) AS days_left
       FROM health_records h
       JOIN animals a ON h.animal_id = a.id
       WHERE h.withdrawal_until >= CURDATE()
       ORDER BY h.withdrawal_until ASC LIMIT 5`,
    );

    for (const hl of healthAlerts) {
      items.push({
        id: `alert-hl-${hl.id}`,
        type: 'WITHDRAWAL_WARNING',
        severity: 'CRITICAL',
        title: 'Active Milk Safety Withdrawal',
        description: `${hl.cow_name || hl.ear_tag} treated with ${hl.medicine_vaccine}. Milk withheld until ${new Date(hl.withdrawal_until).toISOString().slice(0, 10)}.`,
        daysRemaining: Number(hl.days_left),
      });
    }

    // 4. Upcoming Calvings / Gestation Alerts (within 14 days)
    const calvings = await this.dataSource.query(
      `SELECT b.id, a.ear_tag, a.name AS cow_name, b.expected_calving_date,
              DATEDIFF(b.expected_calving_date, CURDATE()) AS days_left
       FROM breeding_records b
       JOIN animals a ON b.animal_id = a.id
       WHERE b.expected_calving_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 14 DAY)
       ORDER BY b.expected_calving_date ASC LIMIT 5`,
    );

    for (const br of calvings) {
      const days = Number(br.days_left);
      items.push({
        id: `alert-br-${br.id}`,
        type: 'UPCOMING_CALVING',
        severity: 'INFO',
        title: 'Upcoming Calving Alert',
        description: `${br.cow_name || br.ear_tag} expected calving in ${days} days (${new Date(br.expected_calving_date).toISOString().slice(0, 10)}).`,
        daysRemaining: days,
      });
    }

    return {
      totalCount: items.length,
      items,
    };
  }

  private async getDailyYieldTrends(start: string, end: string): Promise<DailyYieldTrend[]> {
    const raw = await this.dataSource.query(
      `SELECT
         record_date,
         COALESCE(SUM(CASE WHEN session = 'MORNING' THEN yield_litres ELSE 0 END), 0) AS morning,
         COALESCE(SUM(CASE WHEN session = 'EVENING' THEN yield_litres ELSE 0 END), 0) AS evening,
         COALESCE(SUM(yield_litres), 0) AS total
       FROM milking_logs
       WHERE disposition = 'ELIGIBLE'
         AND record_date BETWEEN ? AND ?
       GROUP BY record_date
       ORDER BY record_date ASC`,
      [start, end],
    );

    return raw.map((r: any) => ({
      date: new Date(r.record_date).toISOString().slice(0, 10),
      morningYield: Number(Number(r.morning).toFixed(2)),
      eveningYield: Number(Number(r.evening).toFixed(2)),
      totalYield: Number(Number(r.total).toFixed(2)),
    }));
  }

  private async getDailyRevenueTrends(start: string, end: string): Promise<DailyRevenueTrend[]> {
    const raw = await this.dataSource.query(
      `SELECT
         record_date,
         COALESCE(SUM(total_amount), 0) AS amount
       FROM sales_dispatches
       WHERE record_date BETWEEN ? AND ?
       GROUP BY record_date
       ORDER BY record_date ASC`,
      [start, end],
    );

    return raw.map((r: any) => ({
      date: new Date(r.record_date).toISOString().slice(0, 10),
      amount: Number(Number(r.amount).toFixed(2)),
    }));
  }

  private async getRecentActivity(): Promise<RecentActivityItem[]> {
    const items: RecentActivityItem[] = [];

    // Milking logs
    const milk = await this.dataSource.query(
      `SELECT m.id, m.record_date, m.session, m.yield_litres, m.disposition, a.ear_tag, m.created_at
       FROM milking_logs m
       JOIN animals a ON m.animal_id = a.id
       ORDER BY m.created_at DESC LIMIT 3`,
    );
    for (const m of milk) {
      items.push({
        id: `act-milk-${m.id}`,
        timestamp: new Date(m.created_at).toISOString(),
        category: 'MILKING',
        title: `Milking Recorded: ${m.ear_tag}`,
        description: `${m.session} session: ${m.yield_litres} L (${m.disposition})`,
        badge: `${m.yield_litres} L`,
      });
    }

    // BMC intakes
    const bmc = await this.dataSource.query(
      `SELECT id, batch_number, quantity_litres, decision, source, created_at
       FROM bmc_intake_logs
       ORDER BY created_at DESC LIMIT 2`,
    );
    for (const b of bmc) {
      items.push({
        id: `act-bmc-${b.id}`,
        timestamp: new Date(b.created_at).toISOString(),
        category: 'BMC',
        title: `BMC Intake: ${b.batch_number}`,
        description: `${b.source} collection: ${b.quantity_litres} L (${b.decision})`,
        badge: `${b.quantity_litres} L`,
      });
    }

    // Sales dispatches
    const sales = await this.dataSource.query(
      `SELECT s.id, s.dispatch_number, s.product_type, s.packs_sold, s.total_amount, c.name AS customer, s.created_at
       FROM sales_dispatches s
       JOIN customers c ON s.customer_id = c.id
       ORDER BY s.created_at DESC LIMIT 2`,
    );
    for (const s of sales) {
      items.push({
        id: `act-sales-${s.id}`,
        timestamp: new Date(s.created_at).toISOString(),
        category: 'SALES',
        title: `Dispatch: ${s.dispatch_number}`,
        description: `${s.packs_sold} packs of ${s.product_type} to ${s.customer}`,
        badge: `₹${s.total_amount}`,
      });
    }

    // Health treatments
    const health = await this.dataSource.query(
      `SELECT h.id, a.ear_tag, h.care_type, h.medicine_vaccine, h.created_at
       FROM health_records h
       JOIN animals a ON h.animal_id = a.id
       ORDER BY h.created_at DESC LIMIT 2`,
    );
    for (const h of health) {
      items.push({
        id: `act-hl-${h.id}`,
        timestamp: new Date(h.created_at).toISOString(),
        category: 'HEALTH',
        title: `Health Event: ${h.ear_tag}`,
        description: `${h.care_type}: ${h.medicine_vaccine}`,
        badge: h.care_type,
      });
    }

    // Sort descending by timestamp
    items.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());
    return items.slice(0, 8);
  }

  // --------------------------------------------------------------------------
  // Helpers
  // --------------------------------------------------------------------------

  private checkFinanceAccess(user: AuthenticatedUser): boolean {
    if (!user) return false;
    if (user.roles?.includes('FARM_OWNER') || user.roles?.includes('ACCOUNTANT')) {
      return true;
    }
    return user.permissions?.includes('finance:read') ?? false;
  }

  private calculateDelta(current: number, prior: number): number | null {
    if (prior <= 0) return null;
    return Number((((current - prior) / prior) * 100).toFixed(1));
  }

  private resolveDateRanges(query: DashboardQueryDto): {
    currentRange: { start: string; end: string };
    priorRange: { start: string; end: string };
    label: string;
  } {
    const today = new Date();
    const todayStr = today.toISOString().slice(0, 10);

    switch (query.period) {
      case DashboardPeriod.WEEK: {
        const start = new Date(today);
        start.setDate(today.getDate() - 6);
        const priorStart = new Date(start);
        priorStart.setDate(start.getDate() - 7);
        const priorEnd = new Date(start);
        priorEnd.setDate(start.getDate() - 1);

        return {
          currentRange: {
            start: start.toISOString().slice(0, 10),
            end: todayStr,
          },
          priorRange: {
            start: priorStart.toISOString().slice(0, 10),
            end: priorEnd.toISOString().slice(0, 10),
          },
          label: 'Last 7 Days',
        };
      }
      case DashboardPeriod.MONTH: {
        const start = new Date(today.getFullYear(), today.getMonth(), 1);
        const priorStart = new Date(today.getFullYear(), today.getMonth() - 1, 1);
        const priorEnd = new Date(today.getFullYear(), today.getMonth(), 0);

        return {
          currentRange: {
            start: start.toISOString().slice(0, 10),
            end: todayStr,
          },
          priorRange: {
            start: priorStart.toISOString().slice(0, 10),
            end: priorEnd.toISOString().slice(0, 10),
          },
          label: 'This Month',
        };
      }
      case DashboardPeriod.CUSTOM: {
        if (!query.startDate || !query.endDate) {
          return this.resolveDateRanges({ period: DashboardPeriod.TODAY });
        }
        const start = new Date(query.startDate);
        const end = new Date(query.endDate);
        const durationDays = Math.max(
          1,
          Math.round((end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24)) + 1,
        );

        const priorEnd = new Date(start);
        priorEnd.setDate(start.getDate() - 1);
        const priorStart = new Date(priorEnd);
        priorStart.setDate(priorEnd.getDate() - durationDays + 1);

        return {
          currentRange: {
            start: query.startDate,
            end: query.endDate,
          },
          priorRange: {
            start: priorStart.toISOString().slice(0, 10),
            end: priorEnd.toISOString().slice(0, 10),
          },
          label: `${query.startDate} to ${query.endDate}`,
        };
      }
      case DashboardPeriod.TODAY:
      default: {
        const yesterday = new Date(today);
        yesterday.setDate(today.getDate() - 1);
        const yestStr = yesterday.toISOString().slice(0, 10);

        return {
          currentRange: { start: todayStr, end: todayStr },
          priorRange: { start: yestStr, end: yestStr },
          label: 'Today',
        };
      }
    }
  }
}
