import { IsEnum, IsOptional, IsDateString } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export enum DashboardPeriod {
  TODAY = 'today',
  WEEK = 'week',
  MONTH = 'month',
  CUSTOM = 'custom',
}

export class DashboardQueryDto {
  @ApiPropertyOptional({ enum: DashboardPeriod, default: DashboardPeriod.TODAY })
  @IsOptional()
  @IsEnum(DashboardPeriod)
  period?: DashboardPeriod = DashboardPeriod.TODAY;

  @ApiPropertyOptional({ description: 'Start date in YYYY-MM-DD format (required if period=custom)' })
  @IsOptional()
  @IsDateString()
  startDate?: string;

  @ApiPropertyOptional({ description: 'End date in YYYY-MM-DD format (required if period=custom)' })
  @IsOptional()
  @IsDateString()
  endDate?: string;
}
