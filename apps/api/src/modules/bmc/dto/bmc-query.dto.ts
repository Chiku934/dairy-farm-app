import {
  IsEnum,
  IsOptional,
  IsString,
  IsInt,
  Min,
  Max,
  IsDateString,
} from 'class-validator';
import { Type } from 'class-transformer';
import { MilkIntakeSource, IntakeShift, Decision } from '../entities/bmc-intake-log.entity';

export class BmcQueryDto {
  @IsOptional()
  @IsDateString()
  date?: string;

  @IsOptional()
  @IsDateString()
  startDate?: string;

  @IsOptional()
  @IsDateString()
  endDate?: string;

  @IsOptional()
  @IsEnum(IntakeShift)
  shift?: IntakeShift;

  @IsOptional()
  @IsEnum(MilkIntakeSource)
  source?: MilkIntakeSource;

  @IsOptional()
  @IsEnum(Decision)
  decision?: Decision;

  @IsOptional()
  @IsString()
  search?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number = 20;
}
