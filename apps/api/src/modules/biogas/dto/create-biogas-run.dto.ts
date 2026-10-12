import {
  IsString,
  IsNotEmpty,
  IsDateString,
  IsNumber,
  Min,
  Max,
  IsOptional,
  IsEnum,
  IsInt,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { BiogasUsageType } from '@dairy-farm/api-contracts';

export class CreateBiogasRunDto {
  @ApiPropertyOptional({ description: 'Unique biogas run identifier code' })
  @IsString()
  @IsOptional()
  runNumber?: string;

  @ApiProperty({ description: 'Production date (YYYY-MM-DD)' })
  @IsDateString()
  @IsNotEmpty()
  recordDate: string;

  @ApiProperty({ description: 'Slurry intake in kg' })
  @IsNumber()
  @Min(0.01)
  slurryInputKg: number;

  @ApiProperty({ description: 'Dry bio-fertiliser output in kg' })
  @IsNumber()
  @Min(0.01)
  dryFertiliserOutputKg: number;

  @ApiPropertyOptional({ description: 'Moisture percentage of output' })
  @IsNumber()
  @Min(0)
  @Max(100)
  @IsOptional()
  moisturePct?: number;

  @ApiPropertyOptional({ description: 'Stock item UUID to credit inventory balance' })
  @IsString()
  @IsOptional()
  stockItemId?: string;

  @ApiPropertyOptional({ description: 'Count of 1kg bags packed', default: 0 })
  @IsInt()
  @Min(0)
  @IsOptional()
  bagsPacked1kg?: number;

  @ApiPropertyOptional({ description: 'Count of 5kg bags packed', default: 0 })
  @IsInt()
  @Min(0)
  @IsOptional()
  bagsPacked5kg?: number;

  @ApiPropertyOptional({ description: 'Count of 25kg bags packed', default: 0 })
  @IsInt()
  @Min(0)
  @IsOptional()
  bagsPacked25kg?: number;

  @ApiPropertyOptional({ description: 'Count of 50kg bags packed', default: 0 })
  @IsInt()
  @Min(0)
  @IsOptional()
  bagsPacked50kg?: number;

  @ApiPropertyOptional({ enum: BiogasUsageType, default: BiogasUsageType.STORE_STOCK })
  @IsEnum(BiogasUsageType)
  @IsOptional()
  usageType?: BiogasUsageType;

  @ApiPropertyOptional({ description: 'Quantity applied or sold in kg', default: 0 })
  @IsNumber()
  @Min(0)
  @IsOptional()
  usageQuantityKg?: number;

  @ApiPropertyOptional({ description: 'Direct sales revenue in INR', default: 0 })
  @IsNumber()
  @Min(0)
  @IsOptional()
  saleAmount?: number;

  @ApiPropertyOptional({ description: 'Buyer name or farm fodder plot reference' })
  @IsString()
  @IsOptional()
  buyerOrFarmPlot?: string;

  @ApiPropertyOptional({ description: 'Operational remarks' })
  @IsString()
  @IsOptional()
  notes?: string;
}
