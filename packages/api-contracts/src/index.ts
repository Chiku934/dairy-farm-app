export * from './enums';

export interface ApiResponse<T = any> {
  success: boolean;
  statusCode: number;
  message: string;
  data: T;
  timestamp: string;
}

export interface ApiErrorResponse {
  success: false;
  statusCode: number;
  error: string;
  message: string | string[];
  path: string;
  timestamp: string;
}

export interface OverviewKpis {
  milkRecordedLitres: number;
  salesRevenue: number;
  operatingCost: number;
  dryFertiliserOutputKg: number;
}

export interface OperatingValues {
  farmCost: number;
  productionAndBiogasCost: number;
  acceptedBmcIntakeLitres: number;
  currentBmcBalanceLitres: number;
  openSalesOrders: number;
}

export interface AlertItem {
  id: string;
  type: string;
  message: string;
  severity: 'INFO' | 'WARNING' | 'ERROR';
}

export interface FarmOverviewData {
  period: string;
  comparisonPeriod: string;
  kpis: OverviewKpis;
  operatingValues: OperatingValues;
  alerts: AlertItem[];
}

export interface FarmSettingsDto {
  bmcCapacityLitres: number;
  feedBaseKg: number;
  feedRatePerLitre: number;
  feedMaxCapKg: number;
  electricityTariff: number;
  farmDefaultKwh: number;
  productionDefaultKwh: number;
  mgmtSalaryToFarmPct: number;
  operatorName?: string;
}
