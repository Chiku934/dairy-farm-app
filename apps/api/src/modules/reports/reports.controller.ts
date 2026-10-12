import {
  Controller,
  Get,
  Query,
  UseGuards,
  Res,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { Response } from 'express';
import { ReportsService } from './reports.service';
import { ReportQueryDto } from './dto/report-query.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '../../common/guards/permissions.guard';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { CurrentUser, AuthenticatedUser } from '../../common/decorators/current-user.decorator';

@ApiTags('Reports & Exports')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('reports')
export class ReportsController {
  constructor(private readonly reportsService: ReportsService) {}

  // 1. Milk Production
  @Get('milk-production')
  @RequirePermissions('milking:read')
  @ApiOperation({ summary: 'Milk production and shift yield report' })
  async getMilkProduction(@Query() query: ReportQueryDto) {
    return this.reportsService.getMilkProductionReport(query);
  }

  @Get('milk-production/export')
  @RequirePermissions('milking:read')
  @ApiOperation({ summary: 'Export milk production report as injection-safe CSV' })
  async exportMilkProduction(
    @Query() query: ReportQueryDto,
    @Res({ passthrough: true }) res: Response,
  ) {
    const csv = await this.reportsService.exportMilkProductionReport(query);
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename="milk_production_report.csv"');
    return csv;
  }

  // 2. Sales
  @Get('sales')
  @RequirePermissions('sales:read')
  @ApiOperation({ summary: 'Sales and customer revenue report' })
  async getSales(@Query() query: ReportQueryDto) {
    return this.reportsService.getSalesReport(query);
  }

  @Get('sales/export')
  @RequirePermissions('sales:read')
  @ApiOperation({ summary: 'Export sales report as injection-safe CSV' })
  async exportSales(
    @Query() query: ReportQueryDto,
    @Res({ passthrough: true }) res: Response,
  ) {
    const csv = await this.reportsService.exportSalesReport(query);
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename="sales_revenue_report.csv"');
    return csv;
  }

  // 3. Expenses
  @Get('expenses')
  @RequirePermissions('finance:read')
  @ApiOperation({ summary: 'Operating expenses and P&L cost centre allocation report' })
  async getExpenses(@Query() query: ReportQueryDto) {
    return this.reportsService.getExpensesReport(query);
  }

  @Get('expenses/export')
  @RequirePermissions('finance:read')
  @ApiOperation({ summary: 'Export expenses report as injection-safe CSV' })
  async exportExpenses(
    @Query() query: ReportQueryDto,
    @Res({ passthrough: true }) res: Response,
  ) {
    const csv = await this.reportsService.exportExpensesReport(query);
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename="operating_expenses_report.csv"');
    return csv;
  }

  // 4. Herd
  @Get('herd')
  @RequirePermissions('animals:read')
  @ApiOperation({ summary: 'Herd inventory and biological status report' })
  async getHerd(@Query() query: ReportQueryDto) {
    return this.reportsService.getHerdReport(query);
  }

  @Get('herd/export')
  @RequirePermissions('animals:read')
  @ApiOperation({ summary: 'Export herd inventory report as injection-safe CSV' })
  async exportHerd(
    @Query() query: ReportQueryDto,
    @Res({ passthrough: true }) res: Response,
  ) {
    const csv = await this.reportsService.exportHerdReport(query);
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename="herd_inventory_report.csv"');
    return csv;
  }

  // 5. Inventory
  @Get('inventory')
  @RequirePermissions('inventory:read')
  @ApiOperation({ summary: 'Feed and inventory valuation report' })
  async getInventory(@Query() query: ReportQueryDto) {
    return this.reportsService.getInventoryReport(query);
  }

  @Get('inventory/export')
  @RequirePermissions('inventory:read')
  @ApiOperation({ summary: 'Export inventory valuation report as injection-safe CSV' })
  async exportInventory(
    @Query() query: ReportQueryDto,
    @Res({ passthrough: true }) res: Response,
  ) {
    const csv = await this.reportsService.exportInventoryReport(query);
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename="inventory_valuation_report.csv"');
    return csv;
  }

  // 6. Staff Payroll (Sensitive)
  @Get('staff-payroll')
  @RequirePermissions('hr:read')
  @ApiOperation({ summary: 'Staff directory and approved wage report (HR & Finance restricted)' })
  async getStaffPayroll(
    @Query() query: ReportQueryDto,
    @CurrentUser() user?: AuthenticatedUser,
  ) {
    return this.reportsService.getStaffPayrollReport(query, user);
  }

  @Get('staff-payroll/export')
  @RequirePermissions('hr:read')
  @ApiOperation({ summary: 'Export staff wage rate report as injection-safe CSV' })
  async exportStaffPayroll(
    @Query() query: ReportQueryDto,
    @Res({ passthrough: true }) res: Response,
    @CurrentUser() user?: AuthenticatedUser,
  ) {
    const csv = await this.reportsService.exportStaffPayrollReport(query, user);
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename="staff_payroll_report.csv"');
    return csv;
  }

  // 7. Licences
  @Get('licences')
  @RequirePermissions('farm:settings:read')
  @ApiOperation({ summary: 'Regulatory licences compliance report' })
  async getLicences(@Query() query: ReportQueryDto) {
    return this.reportsService.getLicencesReport(query);
  }

  @Get('licences/export')
  @RequirePermissions('farm:settings:read')
  @ApiOperation({ summary: 'Export regulatory licences report as injection-safe CSV' })
  async exportLicences(
    @Query() query: ReportQueryDto,
    @Res({ passthrough: true }) res: Response,
  ) {
    const csv = await this.reportsService.exportLicencesReport(query);
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename="regulatory_licences_report.csv"');
    return csv;
  }
}
