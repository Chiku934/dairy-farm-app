import {
  IsNotEmpty,
  IsString,
  IsDateString,
  IsEnum,
  IsOptional,
  IsNumber,
  Min,
  Max,
} from 'class-validator';
import { QualityTargetType, QualityDecision } from '@dairy-farm/api-contracts';

export class CreateQualityRecordDto {
  @IsNotEmpty()
  @IsDateString()
  recordDate: string;

  @IsNotEmpty()
  @IsEnum(QualityTargetType)
  targetType: QualityTargetType;

  @IsNotEmpty()
  @IsString()
  targetId: string;

  @IsOptional()
  @IsNumber()
  @Min(0.0)
  @Max(100.0)
  fatPercentage?: number;

  @IsOptional()
  @IsNumber()
  @Min(0.0)
  @Max(100.0)
  snfPercentage?: number;

  @IsOptional()
  @IsNumber()
  @Min(10.0)
  @Max(45.0)
  clr?: number;

  @IsOptional()
  @IsNumber()
  @Min(0.0)
  @Max(14.0)
  ph?: number;

  @IsOptional()
  @IsNumber()
  @Min(-10.0)
  @Max(100.0)
  temperatureC?: number;

  @IsNotEmpty()
  @IsEnum(QualityDecision)
  decision: QualityDecision;

  @IsOptional()
  @IsString()
  testedBy?: string;

  @IsOptional()
  @IsString()
  notes?: string;
}
