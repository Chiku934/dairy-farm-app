import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { DailyCostingQueryDto } from './dto/daily-costing-query.dto';

export interface CostingBreakdown {
  feedCost: number;
  medicineCost: number;
  materialsCost: number;
  dailySalaries: number;
  electricityCost: number;
  otherExpenses: number;
  isElectricityDefaulted: boolean;
}

export interface DailyMilkCostingResponse {
  date: string;
  totalDailyFarmCost: number;
  eligibleMilkLitres: number;
  totalMilkRecordedLitres: number;
  withheldMilkLitres: number;
  costPerLitre: number | null;
  status: 'COMPLETE' | 'INCOMPLETE';
  warningMessage: string | null;
  breakdown: CostingBreakdown;
  currency: string;
}

@Injectable()
export class CostingService {
  constructor(private readonly dataSource: DataSource) {}

  async getDailyMilkCosting(query: DailyCostingQueryDto): Promise<DailyMilkCostingResponse> {
    const targetDate = query.date || new Date().toISOString().split('T')[0];

    // 1. Fetch Farm Settings (utility defaults, management split, currency)
    const settingsRows = await this.dataSource.query(
      `SELECT electricity_tariff, farm_default_kwh, mgmt_salary_to_farm_pct, currency_symbol
       FROM farm_settings WHERE id = 1 LIMIT 1`,
    );
    const tariff = settingsRows.length > 0 ? parseFloat(settingsRows[0].electricity_tariff || '1.40') : 1.4;
    const defaultKwh = settingsRows.length > 0 ? parseFloat(settingsRows[0].farm_default_kwh || '50.00') : 50.0;
    const mgmtSplitPct = settingsRows.length > 0 ? parseFloat(settingsRows[0].mgmt_salary_to_farm_pct || '50.00') : 50.0;
    const currency = settingsRows.length > 0 ? (settingsRows[0].currency_symbol || '₹') : '₹';

    // 2. Feed Consumed Cost for Target Date
    const feedRows = await this.dataSource.query(
      `SELECT COALESCE(SUM(
         CASE 
           WHEN total_cost > 0 THEN total_cost
           ELSE (quantity_kg * COALESCE(s.weighted_avg_price, 0))
         END
       ), 0) as feedCost
       FROM feed_entries f
       LEFT JOIN stock_items s ON f.stock_item_id = s.id
       WHERE f.record_date = ?`,
      [targetDate],
    );
    const feedCost = parseFloat(parseFloat(feedRows[0]?.feedCost || '0').toFixed(2));

    // 3. Medicines & Vet Care Costs
    const vetRows = await this.dataSource.query(
      `SELECT COALESCE(SUM(amount), 0) as vetExpenses
       FROM operating_expenses
       WHERE cost_centre = 'FARM' AND category = 'VET' AND record_date = ?`,
      [targetDate],
    );
    const medicineCost = parseFloat(parseFloat(vetRows[0]?.vetExpenses || '0').toFixed(2));

    // 4. Other Farm Materials
    const materialRows = await this.dataSource.query(
      `SELECT COALESCE(SUM(quantity * COALESCE(s.weighted_avg_price, 0)), 0) as materialCost
       FROM material_issues m
       LEFT JOIN stock_items s ON m.stock_item_id = s.id
       WHERE m.department = 'FARM' AND m.record_date = ?`,
      [targetDate],
    );
    const materialsCost = parseFloat(parseFloat(materialRows[0]?.materialCost || '0').toFixed(2));

    // 5. Daily Farm Salaries (Farm staff + mgmt split)
    // Daily individual salary rate = monthly_salary / 30
    const salaryRows = await this.dataSource.query(
      `SELECT 
         COALESCE(SUM(CASE WHEN department = 'FARM' THEN COALESCE(daily_salary_rate, monthly_salary / 30) ELSE 0 END), 0) as farmSalaries,
         COALESCE(SUM(CASE WHEN department = 'MANAGEMENT' THEN COALESCE(daily_salary_rate, monthly_salary / 30) ELSE 0 END), 0) as mgmtSalaries
       FROM employees
       WHERE is_active = 1
         AND (leaving_date IS NULL OR leaving_date >= ?)
         AND joining_date <= ?`,
      [targetDate, targetDate],
    );
    const farmSalaries = parseFloat(salaryRows[0]?.farmSalaries || '0');
    const mgmtSalaries = parseFloat(salaryRows[0]?.mgmtSalaries || '0');
    const allocatedMgmtSalaries = (mgmtSalaries * mgmtSplitPct) / 100;
    const dailySalaries = parseFloat((farmSalaries + allocatedMgmtSalaries).toFixed(2));

    // 6. Electricity Cost (Actual reading or default fallback)
    const elecRows = await this.dataSource.query(
      `SELECT total_cost, units_kwh, tariff_rate
       FROM electricity_readings
       WHERE record_date = ? AND department = 'FARM'
       LIMIT 1`,
      [targetDate],
    );
    let electricityCost = 0;
    let isElectricityDefaulted = false;

    if (elecRows.length > 0 && elecRows[0].total_cost !== null) {
      electricityCost = parseFloat(parseFloat(elecRows[0].total_cost).toFixed(2));
    } else if (elecRows.length > 0 && elecRows[0].units_kwh !== null) {
      const units = parseFloat(elecRows[0].units_kwh);
      const appliedTariff = parseFloat(elecRows[0].tariff_rate || tariff.toString());
      electricityCost = parseFloat((units * appliedTariff).toFixed(2));
    } else {
      // Fallback to configured defaults: 50 kWh * ₹1.40 = ₹70.00
      electricityCost = parseFloat((defaultKwh * tariff).toFixed(2));
      isElectricityDefaulted = true;
    }

    // 7. Other Farm Expenses (Operating expenses excluding VET already counted above)
    const otherExpRows = await this.dataSource.query(
      `SELECT COALESCE(SUM(amount), 0) as otherExpenses
       FROM operating_expenses
       WHERE cost_centre = 'FARM' AND category != 'VET' AND record_date = ?`,
      [targetDate],
    );
    const otherExpenses = parseFloat(parseFloat(otherExpRows[0]?.otherExpenses || '0').toFixed(2));

    // Total Daily Farm Operating Cost
    const totalDailyFarmCost = parseFloat(
      (
        feedCost +
        medicineCost +
        materialsCost +
        dailySalaries +
        electricityCost +
        otherExpenses
      ).toFixed(2),
    );

    // 8. Milking Production Yields for Target Date
    const milkRows = await this.dataSource.query(
      `SELECT 
         COALESCE(SUM(yield_litres), 0) as totalMilk,
         COALESCE(SUM(CASE WHEN disposition = 'ELIGIBLE' THEN yield_litres ELSE 0 END), 0) as eligibleMilk,
         COALESCE(SUM(CASE WHEN disposition = 'WITHHELD' THEN yield_litres ELSE 0 END), 0) as withheldMilk
       FROM milking_logs
       WHERE record_date = ?`,
      [targetDate],
    );

    const totalMilkRecordedLitres = parseFloat(parseFloat(milkRows[0]?.totalMilk || '0').toFixed(2));
    const eligibleMilkLitres = parseFloat(parseFloat(milkRows[0]?.eligibleMilk || '0').toFixed(2));
    const withheldMilkLitres = parseFloat(parseFloat(milkRows[0]?.withheldMilk || '0').toFixed(2));

    // 9. Cost per Litre Calculation & Zero Milk Handling
    let costPerLitre: number | null = null;
    let status: 'COMPLETE' | 'INCOMPLETE' = 'COMPLETE';
    let warningMessage: string | null = null;

    if (eligibleMilkLitres === 0) {
      status = 'INCOMPLETE';
      costPerLitre = null;
      warningMessage = 'No eligible milk recorded for this date. Cost per litre cannot be computed.';
    } else {
      costPerLitre = parseFloat((totalDailyFarmCost / eligibleMilkLitres).toFixed(2));
    }

    return {
      date: targetDate,
      totalDailyFarmCost,
      eligibleMilkLitres,
      totalMilkRecordedLitres,
      withheldMilkLitres,
      costPerLitre,
      status,
      warningMessage,
      breakdown: {
        feedCost,
        medicineCost,
        materialsCost,
        dailySalaries,
        electricityCost,
        otherExpenses,
        isElectricityDefaulted,
      },
      currency,
    };
  }
}
