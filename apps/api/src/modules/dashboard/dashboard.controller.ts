import {
  Controller,
  Get,
  Post,
  Query,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiQuery,
} from '@nestjs/swagger';
import { DashboardService } from './dashboard.service';
import { DashboardPeriod, DashboardQueryDto } from './dto/dashboard-query.dto';
import { DashboardOverviewResponse } from './dto/dashboard-overview.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import {
  CurrentUser,
  AuthenticatedUser,
} from '../../common/decorators/current-user.decorator';
import { RateLimit } from '../../common/decorators/rate-limit.decorator';
import { RateLimitGuard } from '../../common/guards/rate-limit.guard';

@ApiTags('Dashboard')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RateLimitGuard)
@Controller('dashboard')
export class DashboardController {
  constructor(private readonly dashboardService: DashboardService) {}

  @Get('overview')
  @RateLimit({ maxRequests: 60, ttlSeconds: 60 })
  @ApiOperation({
    summary: 'Retrieve live farm dashboard KPIs, alerts, trends, and recent activity',
    description:
      'Provides database-backed operational and financial KPIs with period filtering and automatic role-based data redaction for unauthorized callers.',
  })
  @ApiQuery({ name: 'period', enum: DashboardPeriod, required: false })
  @ApiQuery({ name: 'startDate', type: String, required: false })
  @ApiQuery({ name: 'endDate', type: String, required: false })
  @ApiResponse({
    status: 200,
    description: 'Dashboard overview metrics retrieved successfully',
  })
  async getOverview(
    @Query() query: DashboardQueryDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<DashboardOverviewResponse> {
    return this.dashboardService.getOverview(query, user);
  }

  @Post('invalidate-cache')
  @HttpCode(HttpStatus.OK)
  @UseGuards(RolesGuard)
  @Roles('FARM_OWNER', 'FARM_MANAGER')
  @ApiOperation({
    summary: 'Manually invalidate dashboard cache',
    description: 'Purges in-memory aggregation cache. Restricted to Farm Owner and Manager.',
  })
  @ApiResponse({
    status: 200,
    description: 'Dashboard cache invalidated successfully',
  })
  async invalidateCache(): Promise<{ message: string; timestamp: string }> {
    this.dashboardService.invalidateCache();
    return {
      message: 'Dashboard cache invalidated successfully',
      timestamp: new Date().toISOString(),
    };
  }
}
