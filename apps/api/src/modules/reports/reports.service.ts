import {
  Injectable,
  ForbiddenException,
  Logger,
} from '@nestjs/common';
import { DataSource } from 'typeorm';
import { ReportQueryDto } from './dto/report-query.dto';
import { AuthenticatedUser } from '../../common/decorators/current-user.decorator';
import { generateSafeCsv, CsvColumn } from '../../common/utils/csv-sanitizer.util';

const SALARY_AUTHORIZED_ROLES = ['FARM_OWNER', 'SUPER_ADMIN', 'HR_ADMIN', 'ACCOUNTANT'];

@Injectable()
export class ReportsService {
  private readonly logger = new Logger(ReportsService.name);

  constructor(private readonly dataSource: DataSource) {}

  private checkSalaryClearance(user?: AuthenticatedUser): void {
    if (!user) {
      throw new ForbiddenException('Access denied: Staff wage and salary reports require authentication');
    }
    const hasRole = user.roles?.some((r) => SALARY_AUTHORIZED_ROLES.includes(r));
    if (!hasRole) {
      throw new ForbiddenException(
        'Access denied: Staff wage and salary reports require HR or Finance administrative clearance',
      );
    }
  }

  // --------------------------------------------------------------------------
  // 1. Milk Production & Shift Yield Report
  // --------------------------------------------------------------------------
  async getMilkProductionReport(query: ReportQueryDto): Promise<{
    summary: {
      totalYieldLitres: number;
      withheldLitres: number;
      recordCount: number;
    };
    items: any[];
    total: number;
    page: number;
    limit: number;
  }> {
    let whereClause = 'WHERE 1=1';
    const params: any[] = [];

    if (query.startDate) {
      whereClause += ' AND ml.record_date >= ?';
      params.push(query.startDate);
    }
    if (query.endDate) {
      whereClause += ' AND ml.record_date <= ?';
      params.push(query.endDate);
    }
    if (query.filterKey) {
      whereClause += ' AND (ml.session = ? OR ml.disposition = ?)';
      params.push(query.filterKey, query.filterKey);
    }
    if (query.search) {
      whereClause += ' AND (a.ear_tag LIKE ? OR a.name LIKE ?)';
      params.push(`%${query.search}%`, `%${query.search}%`);
    }

    const summaryQuery = `
      SELECT 
        COALESCE(SUM(ml.yield_litres), 0) AS total_yield,
        COALESCE(SUM(CASE WHEN ml.disposition = 'WITHHELD' THEN ml.yield_litres ELSE 0 END), 0) AS withheld_yield,
        COUNT(ml.id) AS record_count
      FROM milking_logs ml
      LEFT JOIN animals a ON ml.animal_id = a.id
      ${whereClause}
    `;

    const summaryRows = await this.dataSource.query(summaryQuery, params);
    const summary = {
      totalYieldLitres: Number(summaryRows[0]?.total_yield || 0),
      withheldLitres: Number(summaryRows[0]?.withheld_yield || 0),
      recordCount: Number(summaryRows[0]?.record_count || 0),
    };

    const page = query.page || 1;
    const limit = query.limit || 50;
    const offset = (page - 1) * limit;

    const dataQuery = `
      SELECT 
        ml.id,
        ml.record_date,
        ml.session,
        COALESCE(a.ear_tag, 'UNKNOWN') AS ear_tag,
        COALESCE(a.name, '') AS animal_name,
        ml.yield_litres,
        ml.disposition,
        COALESCE(ml.withheld_reason, '') AS withheld_reason,
        ml.notes
      FROM milking_logs ml
      LEFT JOIN animals a ON ml.animal_id = a.id
      ${whereClause}
      ORDER BY ml.record_date DESC, ml.created_at DESC
      LIMIT ? OFFSET ?
    `;

    const items = await this.dataSource.query(dataQuery, [...params, limit, offset]);

    return {
      summary,
      items,
      total: summary.recordCount,
      page,
      limit,
    };
  }

  async exportMilkProductionReport(query: ReportQueryDto): Promise<string> {
    const report = await this.getMilkProductionReport({ ...query, limit: 10000, page: 1 });
    const columns: CsvColumn[] = [
      { key: 'record_date', label: 'Date' },
      { key: 'session', label: 'Session' },
      { key: 'ear_tag', label: 'Ear Tag' },
      { key: 'animal_name', label: 'Animal Name' },
      { key: 'yield_litres', label: 'Yield (L)' },
      { key: 'disposition', label: 'Disposition' },
      { key: 'withheld_reason', label: 'Withheld Reason' },
      { key: 'notes', label: 'Notes' },
    ];
    return generateSafeCsv(columns, report.items);
  }

  // --------------------------------------------------------------------------
  // 2. Sales & Customer Revenue Report
  // --------------------------------------------------------------------------
  async getSalesReport(query: ReportQueryDto): Promise<{
    summary: {
      totalSales: number;
      totalPaid: number;
      totalBalance: number;
      orderCount: number;
    };
    items: any[];
    total: number;
    page: number;
    limit: number;
  }> {
    let whereClause = 'WHERE 1=1';
    const params: any[] = [];

    if (query.startDate) {
      whereClause += ' AND s.order_date >= ?';
      params.push(query.startDate);
    }
    if (query.endDate) {
      whereClause += ' AND s.order_date <= ?';
      params.push(query.endDate);
    }
    if (query.filterKey) {
      whereClause += ' AND (s.status = ? OR s.payment_method = ?)';
      params.push(query.filterKey, query.filterKey);
    }
    if (query.search) {
      whereClause += ' AND (s.sales_number LIKE ? OR c.name LIKE ?)';
      params.push(`%${query.search}%`, `%${query.search}%`);
    }

    const summaryQuery = `
      SELECT 
        COALESCE(SUM(s.total_amount), 0) AS total_sales,
        COALESCE(SUM(s.paid_amount), 0) AS total_paid,
        COALESCE(SUM(s.balance_amount), 0) AS total_balance,
        COUNT(s.id) AS order_count
      FROM sales_records s
      LEFT JOIN customers c ON s.customer_id = c.id
      ${whereClause}
    `;

    const summaryRows = await this.dataSource.query(summaryQuery, params);
    const summary = {
      totalSales: Number(summaryRows[0]?.total_sales || 0),
      totalPaid: Number(summaryRows[0]?.total_paid || 0),
      totalBalance: Number(summaryRows[0]?.total_balance || 0),
      orderCount: Number(summaryRows[0]?.order_count || 0),
    };

    const page = query.page || 1;
    const limit = query.limit || 50;
    const offset = (page - 1) * limit;

    const dataQuery = `
      SELECT 
        s.id,
        s.sales_number,
        s.order_date,
        COALESCE(c.name, 'Direct Retail') AS customer_name,
        COALESCE(c.customer_type, 'RETAIL') AS customer_type,
        s.total_amount,
        s.paid_amount,
        s.balance_amount,
        s.payment_method,
        s.status
      FROM sales_records s
      LEFT JOIN customers c ON s.customer_id = c.id
      ${whereClause}
      ORDER BY s.order_date DESC, s.created_at DESC
      LIMIT ? OFFSET ?
    `;

    const items = await this.dataSource.query(dataQuery, [...params, limit, offset]);

    return {
      summary,
      items,
      total: summary.orderCount,
      page,
      limit,
    };
  }

  async exportSalesReport(query: ReportQueryDto): Promise<string> {
    const report = await this.getSalesReport({ ...query, limit: 10000, page: 1 });
    const columns: CsvColumn[] = [
      { key: 'sales_number', label: 'Invoice #' },
      { key: 'order_date', label: 'Order Date' },
      { key: 'customer_name', label: 'Customer Name' },
      { key: 'customer_type', label: 'Customer Type' },
      { key: 'total_amount', label: 'Total Amount (₹)' },
      { key: 'paid_amount', label: 'Paid Amount (₹)' },
      { key: 'balance_amount', label: 'Outstanding Balance (₹)' },
      { key: 'payment_method', label: 'Payment Method' },
      { key: 'status', label: 'Order Status' },
    ];
    return generateSafeCsv(columns, report.items);
  }

  // --------------------------------------------------------------------------
  // 3. Operating Expenses & P&L Cost Allocation Report
  // --------------------------------------------------------------------------
  async getExpensesReport(query: ReportQueryDto): Promise<{
    summary: {
      totalExpenses: number;
      farmExpenses: number;
      productionExpenses: number;
      biogasExpenses: number;
      expenseCount: number;
    };
    items: any[];
    total: number;
    page: number;
    limit: number;
  }> {
    let whereClause = 'WHERE 1=1';
    const params: any[] = [];

    if (query.startDate) {
      whereClause += ' AND e.record_date >= ?';
      params.push(query.startDate);
    }
    if (query.endDate) {
      whereClause += ' AND e.record_date <= ?';
      params.push(query.endDate);
    }
    if (query.filterKey) {
      whereClause += ' AND (e.cost_centre = ? OR e.category = ?)';
      params.push(query.filterKey, query.filterKey);
    }
    if (query.search) {
      whereClause += ' AND (e.expense_number LIKE ? OR e.payee LIKE ? OR e.invoice_number LIKE ?)';
      params.push(`%${query.search}%`, `%${query.search}%`, `%${query.search}%`);
    }

    const summaryQuery = `
      SELECT 
        COALESCE(SUM(e.amount), 0) AS total_expenses,
        COALESCE(SUM(CASE WHEN e.cost_centre = 'FARM' THEN e.amount ELSE 0 END), 0) AS farm_expenses,
        COALESCE(SUM(CASE WHEN e.cost_centre = 'PRODUCTION' THEN e.amount ELSE 0 END), 0) AS production_expenses,
        COALESCE(SUM(CASE WHEN e.cost_centre = 'BIOGAS' THEN e.amount ELSE 0 END), 0) AS biogas_expenses,
        COUNT(e.id) AS expense_count
      FROM operating_expenses e
      ${whereClause}
    `;

    const summaryRows = await this.dataSource.query(summaryQuery, params);
    const summary = {
      totalExpenses: Number(summaryRows[0]?.total_expenses || 0),
      farmExpenses: Number(summaryRows[0]?.farm_expenses || 0),
      productionExpenses: Number(summaryRows[0]?.production_expenses || 0),
      biogasExpenses: Number(summaryRows[0]?.biogas_expenses || 0),
      expenseCount: Number(summaryRows[0]?.expense_count || 0),
    };

    const page = query.page || 1;
    const limit = query.limit || 50;
    const offset = (page - 1) * limit;

    const dataQuery = `
      SELECT 
        e.id,
        COALESCE(e.expense_number, e.id) AS expense_number,
        e.record_date,
        e.cost_centre,
        e.category,
        e.amount,
        COALESCE(e.payee, '') AS payee,
        COALESCE(e.invoice_number, '') AS invoice_number,
        e.payment_method,
        e.notes
      FROM operating_expenses e
      ${whereClause}
      ORDER BY e.record_date DESC, e.created_at DESC
      LIMIT ? OFFSET ?
    `;

    const items = await this.dataSource.query(dataQuery, [...params, limit, offset]);

    return {
      summary,
      items,
      total: summary.expenseCount,
      page,
      limit,
    };
  }

  async exportExpensesReport(query: ReportQueryDto): Promise<string> {
    const report = await this.getExpensesReport({ ...query, limit: 10000, page: 1 });
    const columns: CsvColumn[] = [
      { key: 'expense_number', label: 'Voucher #' },
      { key: 'record_date', label: 'Date' },
      { key: 'cost_centre', label: 'Cost Centre' },
      { key: 'category', label: 'Category' },
      { key: 'amount', label: 'Amount (₹)' },
      { key: 'payee', label: 'Payee' },
      { key: 'invoice_number', label: 'Invoice #' },
      { key: 'payment_method', label: 'Payment Method' },
      { key: 'notes', label: 'Notes' },
    ];
    return generateSafeCsv(columns, report.items);
  }

  // --------------------------------------------------------------------------
  // 4. Herd Inventory & Biological Status Report
  // --------------------------------------------------------------------------
  async getHerdReport(query: ReportQueryDto): Promise<{
    summary: {
      totalHeadCount: number;
      lactatingCount: number;
      dryCount: number;
      pregnantCount: number;
      withheldCount: number;
    };
    items: any[];
    total: number;
    page: number;
    limit: number;
  }> {
    let whereClause = 'WHERE 1=1';
    const params: any[] = [];

    if (query.filterKey) {
      whereClause += ' AND (a.status = ? OR a.breed = ?)';
      params.push(query.filterKey, query.filterKey);
    }
    if (query.search) {
      whereClause += ' AND (a.ear_tag LIKE ? OR a.name LIKE ? OR a.breed LIKE ?)';
      params.push(`%${query.search}%`, `%${query.search}%`, `%${query.search}%`);
    }

    const today = new Date().toISOString().slice(0, 10);

    const summaryQuery = `
      SELECT 
        COUNT(a.id) AS total_count,
        COALESCE(SUM(CASE WHEN a.status = 'LACTATING' THEN 1 ELSE 0 END), 0) AS lactating_count,
        COALESCE(SUM(CASE WHEN a.status = 'DRY' THEN 1 ELSE 0 END), 0) AS dry_count,
        COALESCE(SUM(CASE WHEN a.status = 'PREGNANT' THEN 1 ELSE 0 END), 0) AS pregnant_count,
        COALESCE(SUM(CASE WHEN EXISTS (
          SELECT 1 FROM health_records hr 
          WHERE hr.animal_id = a.id AND hr.withdrawal_until >= ?
        ) THEN 1 ELSE 0 END), 0) AS withheld_count
      FROM animals a
      ${whereClause}
    `;

    const summaryRows = await this.dataSource.query(summaryQuery, [today, ...params]);
    const summary = {
      totalHeadCount: Number(summaryRows[0]?.total_count || 0),
      lactatingCount: Number(summaryRows[0]?.lactating_count || 0),
      dryCount: Number(summaryRows[0]?.dry_count || 0),
      pregnantCount: Number(summaryRows[0]?.pregnant_count || 0),
      withheldCount: Number(summaryRows[0]?.withheld_count || 0),
    };

    const page = query.page || 1;
    const limit = query.limit || 50;
    const offset = (page - 1) * limit;

    const dataQuery = `
      SELECT 
        a.id,
        a.ear_tag,
        COALESCE(a.name, '') AS name,
        a.breed,
        a.sex,
        a.status,
        a.date_of_birth,
        (SELECT MAX(hr.withdrawal_until) FROM health_records hr WHERE hr.animal_id = a.id) AS withdrawal_end_date,
        CASE WHEN EXISTS (
          SELECT 1 FROM health_records hr 
          WHERE hr.animal_id = a.id AND hr.withdrawal_until >= ?
        ) THEN 'YES' ELSE 'NO' END AS active_withdrawal
      FROM animals a
      ${whereClause}
      ORDER BY a.ear_tag ASC
      LIMIT ? OFFSET ?
    `;

    const items = await this.dataSource.query(dataQuery, [today, ...params, limit, offset]);

    return {
      summary,
      items,
      total: summary.totalHeadCount,
      page,
      limit,
    };
  }

  async exportHerdReport(query: ReportQueryDto): Promise<string> {
    const report = await this.getHerdReport({ ...query, limit: 10000, page: 1 });
    const columns: CsvColumn[] = [
      { key: 'ear_tag', label: 'Ear Tag' },
      { key: 'name', label: 'Name' },
      { key: 'breed', label: 'Breed' },
      { key: 'sex', label: 'Sex' },
      { key: 'status', label: 'Status' },
      { key: 'date_of_birth', label: 'Birth Date' },
      { key: 'active_withdrawal', label: 'Medical Withdrawal' },
      { key: 'withdrawal_end_date', label: 'Withdrawal End Date' },
    ];
    return generateSafeCsv(columns, report.items);
  }

  // --------------------------------------------------------------------------
  // 5. Feed & Inventory Valuation Report
  // --------------------------------------------------------------------------
  async getInventoryReport(query: ReportQueryDto): Promise<{
    summary: {
      totalValuation: number;
      totalItems: number;
      lowStockCount: number;
    };
    items: any[];
    total: number;
    page: number;
    limit: number;
  }> {
    let whereClause = 'WHERE 1=1';
    const params: any[] = [];

    if (query.filterKey) {
      whereClause += ' AND (si.category = ? OR si.used_by = ?)';
      params.push(query.filterKey, query.filterKey);
    }
    if (query.search) {
      whereClause += ' AND (si.name LIKE ? OR si.category LIKE ?)';
      params.push(`%${query.search}%`, `%${query.search}%`);
    }

    const summaryQuery = `
      SELECT 
        COALESCE(SUM(si.current_stock * si.weighted_avg_price), 0) AS total_valuation,
        COUNT(si.id) AS total_items,
        COALESCE(SUM(CASE WHEN si.current_stock <= si.reorder_level THEN 1 ELSE 0 END), 0) AS low_stock_count
      FROM stock_items si
      ${whereClause}
    `;

    const summaryRows = await this.dataSource.query(summaryQuery, params);
    const summary = {
      totalValuation: Number(Number(summaryRows[0]?.total_valuation || 0).toFixed(2)),
      totalItems: Number(summaryRows[0]?.total_items || 0),
      lowStockCount: Number(summaryRows[0]?.low_stock_count || 0),
    };

    const page = query.page || 1;
    const limit = query.limit || 50;
    const offset = (page - 1) * limit;

    const dataQuery = `
      SELECT 
        si.id,
        si.name AS item_name,
        si.category,
        si.used_by,
        si.unit,
        si.current_stock,
        si.reorder_level,
        si.weighted_avg_price,
        ROUND(si.current_stock * si.weighted_avg_price, 2) AS stock_valuation,
        CASE WHEN si.current_stock <= si.reorder_level THEN 'YES' ELSE 'NO' END AS is_low_stock
      FROM stock_items si
      ${whereClause}
      ORDER BY si.name ASC
      LIMIT ? OFFSET ?
    `;

    const items = await this.dataSource.query(dataQuery, [...params, limit, offset]);

    return {
      summary,
      items,
      total: summary.totalItems,
      page,
      limit,
    };
  }

  async exportInventoryReport(query: ReportQueryDto): Promise<string> {
    const report = await this.getInventoryReport({ ...query, limit: 10000, page: 1 });
    const columns: CsvColumn[] = [
      { key: 'item_name', label: 'Item Name' },
      { key: 'category', label: 'Category' },
      { key: 'used_by', label: 'Used By' },
      { key: 'unit', label: 'UOM' },
      { key: 'current_stock', label: 'Current Stock' },
      { key: 'reorder_level', label: 'Reorder Level' },
      { key: 'weighted_avg_price', label: 'Avg Unit Cost (₹)' },
      { key: 'stock_valuation', label: 'Valuation (₹)' },
      { key: 'is_low_stock', label: 'Low Stock Flag' },
    ];
    return generateSafeCsv(columns, report.items);
  }

  // --------------------------------------------------------------------------
  // 6. Staff Directory & Wage Rate Report (SENSITIVE / HR & Finance Only)
  // --------------------------------------------------------------------------
  async getStaffPayrollReport(
    query: ReportQueryDto,
    user?: AuthenticatedUser,
  ): Promise<{
    summary: {
      totalEmployees: number;
      activeEmployees: number;
      totalMonthlySalary: number;
      totalDailyRate: number;
    };
    items: any[];
    total: number;
    page: number;
    limit: number;
  }> {
    this.checkSalaryClearance(user);

    let whereClause = 'WHERE 1=1';
    const params: any[] = [];

    if (query.filterKey) {
      whereClause += ' AND (emp.department = ? OR emp.status = ?)';
      params.push(query.filterKey, query.filterKey);
    }
    if (query.search) {
      whereClause += ' AND (emp.employee_code LIKE ? OR emp.full_name LIKE ? OR emp.job_title LIKE ?)';
      params.push(`%${query.search}%`, `%${query.search}%`, `%${query.search}%`);
    }

    const summaryQuery = `
      SELECT 
        COUNT(emp.id) AS total_employees,
        COALESCE(SUM(CASE WHEN emp.status = 'ACTIVE' THEN 1 ELSE 0 END), 0) AS active_employees,
        COALESCE(SUM(emp.monthly_salary), 0) AS total_monthly_salary,
        COALESCE(SUM(emp.daily_salary_rate), 0) AS total_daily_rate
      FROM employees emp
      ${whereClause}
    `;

    const summaryRows = await this.dataSource.query(summaryQuery, params);
    const summary = {
      totalEmployees: Number(summaryRows[0]?.total_employees || 0),
      activeEmployees: Number(summaryRows[0]?.active_employees || 0),
      totalMonthlySalary: Number(Number(summaryRows[0]?.total_monthly_salary || 0).toFixed(2)),
      totalDailyRate: Number(Number(summaryRows[0]?.total_daily_rate || 0).toFixed(2)),
    };

    const page = query.page || 1;
    const limit = query.limit || 50;
    const offset = (page - 1) * limit;

    const dataQuery = `
      SELECT 
        emp.id,
        emp.employee_code,
        emp.full_name,
        emp.department,
        emp.job_title,
        emp.joining_date,
        emp.status,
        emp.monthly_salary,
        emp.daily_salary_rate,
        COALESCE(emp.phone, '') AS phone,
        COALESCE(emp.email, '') AS email
      FROM employees emp
      ${whereClause}
      ORDER BY emp.employee_code ASC
      LIMIT ? OFFSET ?
    `;

    const items = await this.dataSource.query(dataQuery, [...params, limit, offset]);

    return {
      summary,
      items,
      total: summary.totalEmployees,
      page,
      limit,
    };
  }

  async exportStaffPayrollReport(query: ReportQueryDto, user?: AuthenticatedUser): Promise<string> {
    this.checkSalaryClearance(user);

    const report = await this.getStaffPayrollReport({ ...query, limit: 10000, page: 1 }, user);
    const columns: CsvColumn[] = [
      { key: 'employee_code', label: 'Employee Code' },
      { key: 'full_name', label: 'Full Name' },
      { key: 'department', label: 'Department' },
      { key: 'job_title', label: 'Designation' },
      { key: 'joining_date', label: 'Joining Date' },
      { key: 'status', label: 'Status' },
      { key: 'monthly_salary', label: 'Approved Monthly Salary (₹)' },
      { key: 'daily_salary_rate', label: 'Daily Wage Rate (₹)' },
      { key: 'phone', label: 'Contact Phone' },
      { key: 'email', label: 'Email' },
    ];
    return generateSafeCsv(columns, report.items);
  }

  // --------------------------------------------------------------------------
  // 7. Regulatory Licences Compliance Report
  // --------------------------------------------------------------------------
  async getLicencesReport(query: ReportQueryDto): Promise<{
    summary: {
      totalLicences: number;
      activeLicences: number;
      expiringSoonLicences: number;
      expiredLicences: number;
    };
    items: any[];
    total: number;
    page: number;
    limit: number;
  }> {
    let whereClause = 'WHERE 1=1';
    const params: any[] = [];

    if (query.filterKey) {
      whereClause += ' AND (l.licence_type = ? OR l.status = ?)';
      params.push(query.filterKey, query.filterKey);
    }
    if (query.search) {
      whereClause += ' AND (l.licence_name LIKE ? OR l.licence_number LIKE ? OR l.issuing_authority LIKE ?)';
      params.push(`%${query.search}%`, `%${query.search}%`, `%${query.search}%`);
    }

    const summaryQuery = `
      SELECT 
        COUNT(l.id) AS total_licences,
        COALESCE(SUM(CASE WHEN l.status = 'ACTIVE' THEN 1 ELSE 0 END), 0) AS active_licences,
        COALESCE(SUM(CASE WHEN l.status = 'EXPIRING_SOON' THEN 1 ELSE 0 END), 0) AS expiring_soon_licences,
        COALESCE(SUM(CASE WHEN l.status = 'EXPIRED' THEN 1 ELSE 0 END), 0) AS expired_licences
      FROM regulatory_licences l
      ${whereClause}
    `;

    const summaryRows = await this.dataSource.query(summaryQuery, params);
    const summary = {
      totalLicences: Number(summaryRows[0]?.total_licences || 0),
      activeLicences: Number(summaryRows[0]?.active_licences || 0),
      expiringSoonLicences: Number(summaryRows[0]?.expiring_soon_licences || 0),
      expiredLicences: Number(summaryRows[0]?.expired_licences || 0),
    };

    const page = query.page || 1;
    const limit = query.limit || 50;
    const offset = (page - 1) * limit;

    const dataQuery = `
      SELECT 
        l.id,
        l.licence_name,
        l.licence_type,
        l.licence_number,
        l.issuing_authority,
        l.licence_holder,
        l.issue_date,
        l.expiry_date,
        l.status,
        l.reminder_status
      FROM regulatory_licences l
      ${whereClause}
      ORDER BY l.expiry_date ASC
      LIMIT ? OFFSET ?
    `;

    const items = await this.dataSource.query(dataQuery, [...params, limit, offset]);

    return {
      summary,
      items,
      total: summary.totalLicences,
      page,
      limit,
    };
  }

  async exportLicencesReport(query: ReportQueryDto): Promise<string> {
    const report = await this.getLicencesReport({ ...query, limit: 10000, page: 1 });
    const columns: CsvColumn[] = [
      { key: 'licence_name', label: 'Licence Title' },
      { key: 'licence_type', label: 'Compliance Type' },
      { key: 'licence_number', label: 'Registration #' },
      { key: 'issuing_authority', label: 'Issuing Authority' },
      { key: 'licence_holder', label: 'Entity Holder' },
      { key: 'issue_date', label: 'Issue Date' },
      { key: 'expiry_date', label: 'Expiry Date' },
      { key: 'status', label: 'Status' },
      { key: 'reminder_status', label: 'Reminder Status' },
    ];
    return generateSafeCsv(columns, report.items);
  }
}
