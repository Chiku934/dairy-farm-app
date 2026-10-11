import { IsOptional, IsDateString } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class DailyCostingQueryDto {
  @ApiPropertyOptional({ description: 'Target date (YYYY-MM-DD). Defaults to current date if omitted.', example: '2026-10-11' })
  @IsOptional()
  @IsDateString()
  date?: string;
}
