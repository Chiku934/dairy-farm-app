export interface KpiMetric<T = number> {
  value: T;
  unit?: string;
  currency?: string;
  label: string;
  priorValue?: T;
  deltaPercent?: number | null;
  amYield?: number;
  pmYield?: number;
  isRestricted?: boolean;
}

export interface CostPerLitreMetric {
  value: number | null;
  currency: string;
  label: string;
  status: 'CALCULATED' | 'INCOMPLETE' | 'RESTRICTED';
  formulaExplanation: string;
}

export interface HerdSummary {
  totalActive: number;
  lactating: number;
  dry: number;
  pregnant: number;
  heifersCalves: number;
  bulls: number;
}

export interface BmcStatus {
  capacityLitres: number;
  currentBalanceLitres: number;
  utilizationPercent: number;
  status: 'NORMAL' | 'WARNING' | 'CRITICAL';
}

export interface DashboardAlert {
  id: string;
  type: 'EXPIRING_LICENCE' | 'LOW_INVENTORY' | 'WITHDRAWAL_WARNING' | 'UPCOMING_CALVING';
  severity: 'INFO' | 'WARNING' | 'CRITICAL';
  title: string;
  description: string;
  daysRemaining?: number;
}

export interface DailyYieldTrend {
  date: string;
  morningYield: number;
  eveningYield: number;
  totalYield: number;
}

export interface DailyRevenueTrend {
  date: string;
  amount: number;
}

export interface RecentActivityItem {
  id: string;
  timestamp: string;
  category: 'MILKING' | 'BMC' | 'SALES' | 'HEALTH' | 'QUALITY' | 'AUDIT';
  title: string;
  description: string;
  badge?: string;
}

export interface DashboardOverviewResponse {
  period: {
    type: string;
    startDate: string;
    endDate: string;
    label: string;
  };
  kpis: {
    milkRecorded: KpiMetric<number>;
    dryFertiliser: KpiMetric<number>;
    salesRevenue: KpiMetric<number> | null;
    operatingCost: KpiMetric<number> | null;
    costPerLitre: CostPerLitreMetric;
  };
  herd: HerdSummary;
  bmcTank: BmcStatus;
  alerts: {
    totalCount: number;
    items: DashboardAlert[];
  };
  trends: {
    dailyYields: DailyYieldTrend[];
    dailyRevenue?: DailyRevenueTrend[];
  };
  recentActivity: RecentActivityItem[];
}
