import {
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Min,
  Max,
  IsDateString,
  ValidateIf,
} from 'class-validator';
import { Type } from 'class-transformer';
import { MilkIntakeSource, IntakeShift, Decision } from '../entities/bmc-intake-log.entity';

export class CreateBmcIntakeDto {
  @IsNotEmpty()
  @IsDateString()
  recordDate: string;

  @IsNotEmpty()
  @IsEnum(IntakeShift)
  shift: IntakeShift;

  @IsNotEmpty()
  @IsEnum(MilkIntakeSource)
  source: MilkIntakeSource;

  @IsOptional()
  @IsString()
  supplierRoute?: string;

  @IsNotEmpty()
  @Type(() => Number)
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0.01, { message: 'Quantity must be at least 0.01 litres' })
  @Max(10000, { message: 'Quantity cannot exceed 10000 litres per session' })
  quantityLitres: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  externalTotalCost?: number;

  @IsNotEmpty()
  @IsEnum(Decision)
  decision: Decision;

  @ValidateIf((o) => o.decision === Decision.REJECTED)
  @IsNotEmpty({ message: 'Rejection reason is required when milk intake is rejected' })
  @IsString()
  rejectionReason?: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber({ maxDecimalPlaces: 1 })
  @Min(-5)
  @Max(50)
  temperatureC?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  @Max(15)
  fatPercentage?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  @Max(20)
  snfPercentage?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(10)
  @Max(45)
  clr?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(4)
  @Max(9)
  ph?: number;

  @IsOptional()
  @IsString()
  notes?: string;

  @IsOptional()
  @IsString()
  operatorName?: string;
}
