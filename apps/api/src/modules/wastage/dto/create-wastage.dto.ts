import {
  IsString,
  IsNotEmpty,
  IsDateString,
  IsNumber,
  Min,
  IsOptional,
  IsEnum,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { StockType, WastageReason } from '@dairy-farm/api-contracts';

export class CreateWastageDto {
  @ApiPropertyOptional({ description: 'Unique wastage identifier number' })
  @IsString()
  @IsOptional()
  wastageNumber?: string;

  @ApiProperty({ description: 'Date of incident (YYYY-MM-DD)' })
  @IsDateString()
  @IsNotEmpty()
  recordDate: string;

  @ApiProperty({ enum: StockType, description: 'Source stock classification' })
  @IsEnum(StockType)
  stockType: StockType;

  @ApiPropertyOptional({ description: 'Referenced stock item UUID when stockType is SUPPLY' })
  @IsString()
  @IsOptional()
  stockItemId?: string;

  @ApiPropertyOptional({ description: 'Referenced production batch UUID when loss is batch-related' })
  @IsString()
  @IsOptional()
  productionBatchId?: string;

  @ApiProperty({ description: 'Tracking reference identifier (e.g. intake batch, lot number, or item tag)' })
  @IsString()
  @IsNotEmpty()
  referenceId: string;

  @ApiProperty({ description: 'Quantity of stock lost or discarded' })
  @IsNumber()
  @Min(0.01)
  quantityLost: number;

  @ApiProperty({ description: 'Unit of measure (e.g. LITRE, KG, PCS)' })
  @IsString()
  @IsNotEmpty()
  unit: string;

  @ApiProperty({ enum: WastageReason, description: 'Root cause for loss' })
  @IsEnum(WastageReason)
  reason: WastageReason;

  @ApiPropertyOptional({ description: 'Explicit or override loss valuation in INR' })
  @IsNumber()
  @Min(0)
  @IsOptional()
  estimatedLossCost?: number;

  @ApiPropertyOptional({ description: 'Incident explanation and corrective action notes' })
  @IsString()
  @IsOptional()
  notes?: string;
}
