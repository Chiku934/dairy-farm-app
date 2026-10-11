import { IsOptional, IsString, IsEnum, IsInt, Min } from 'class-validator';
import { Type } from 'class-transformer';
import { QualityTargetType, QualityDecision } from '@dairy-farm/api-contracts';

export class QualityQueryDto {
  @IsOptional()
  @IsEnum(QualityTargetType)
  targetType?: QualityTargetType;

  @IsOptional()
  @IsString()
  targetId?: string;

  @IsOptional()
  @IsEnum(QualityDecision)
  decision?: QualityDecision;

  @IsOptional()
  @IsString()
  startDate?: string;

  @IsOptional()
  @IsString()
  endDate?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  limit?: number = 20;
}
