import { IsNotEmpty, IsString, IsNumber, IsDateString, IsOptional, Min, IsInt } from 'class-validator';

export class CreatePackagingRunDto {
  @IsNotEmpty()
  @IsDateString()
  recordDate: string;

  @IsNotEmpty()
  @IsString()
  productionBatchId: string;

  @IsNotEmpty()
  @IsNumber()
  @Min(0.01)
  packSize: number;

  @IsNotEmpty()
  @IsString()
  packUnit: string;

  @IsNotEmpty()
  @IsInt()
  @Min(1)
  numberOfPacks: number;

  @IsNotEmpty()
  @IsString()
  packagingItemId: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  materialConsumed?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  scrapUnits?: number;

  @IsOptional()
  @IsString()
  notes?: string;
}
