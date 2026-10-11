import {
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Min,
  Max,
  IsDateString,
  IsArray,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';
import {
  ProductType,
  UnitOfMeasure,
  QualityReleaseStatus,
  BatchStatus,
  IntakeShift,
} from '../entities/production-batch.entity';

export class LinkedIntakeDto {
  @IsNotEmpty()
  @IsString()
  intakeId: string;

  @IsNotEmpty()
  @Type(() => Number)
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0.01)
  litresUsed: number;
}

export class CreateProductionBatchDto {
  @IsNotEmpty()
  @IsDateString()
  recordDate: string;

  @IsOptional()
  @IsEnum(IntakeShift)
  shift?: IntakeShift = IntakeShift.AM;

  @IsNotEmpty()
  @IsEnum(ProductType)
  productType: ProductType;

  @IsNotEmpty()
  @Type(() => Number)
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0.01, { message: 'Milk consumed must be at least 0.01 litres' })
  @Max(5000, { message: 'Milk consumed cannot exceed 5000 litres per batch' })
  bmcMilkConsumedL: number;

  @IsNotEmpty()
  @Type(() => Number)
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0.01, { message: 'Finished quantity must be at least 0.01' })
  finishedQuantity: number;

  @IsNotEmpty()
  @IsEnum(UnitOfMeasure)
  unitOfMeasure: UnitOfMeasure;

  @IsOptional()
  @Type(() => Number)
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  lpgUsedKg?: number = 0;

  @IsOptional()
  @IsString()
  lpgStockItemId?: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  byproductQuantityKg?: number = 0;

  @IsNotEmpty()
  @IsDateString()
  expiryDate: string;

  @IsOptional()
  @IsEnum(QualityReleaseStatus)
  qualityRelease?: QualityReleaseStatus = QualityReleaseStatus.HOLD;

  @IsOptional()
  @IsEnum(BatchStatus)
  status?: BatchStatus = BatchStatus.COMPLETED;

  @IsOptional()
  @IsString()
  notes?: string;

  @IsOptional()
  @IsString()
  operatorName?: string;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => LinkedIntakeDto)
  linkedIntakes?: LinkedIntakeDto[];
}
