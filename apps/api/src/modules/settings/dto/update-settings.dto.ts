import { IsNumber, IsOptional, IsString, Min, Max } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class UpdateFarmSettingsDto {
  @ApiPropertyOptional({ example: 'Kaivalya Dairy', description: 'Display name of the dairy farm enterprise' })
  @IsOptional()
  @IsString()
  farmName?: string;

  @ApiPropertyOptional({ example: 'Dandiri', description: 'Registered address' })
  @IsOptional()
  @IsString()
  address?: string;

  @ApiPropertyOptional({ example: 'Koraput', description: 'District' })
  @IsOptional()
  @IsString()
  district?: string;

  @ApiPropertyOptional({ example: 'Odisha', description: 'State' })
  @IsOptional()
  @IsString()
  state?: string;

  @ApiPropertyOptional({ example: '764036', description: 'Postal PIN code' })
  @IsOptional()
  @IsString()
  pincode?: string;

  @ApiPropertyOptional({ example: '+91 9876543210', description: 'Contact phone' })
  @IsOptional()
  @IsString()
  contactPhone?: string;

  @ApiPropertyOptional({ example: 'contact@kaivalyadairy.com', description: 'Official contact email' })
  @IsOptional()
  @IsString()
  contactEmail?: string;

  @ApiPropertyOptional({ example: 'INR', description: 'ISO 4217 Currency code' })
  @IsOptional()
  @IsString()
  currencyCode?: string;

  @ApiPropertyOptional({ example: '₹', description: 'Currency symbol' })
  @IsOptional()
  @IsString()
  currencySymbol?: string;

  @ApiPropertyOptional({ example: 2000.0, description: 'Bulk Milk Cooler capacity in litres' })
  @IsOptional()
  @IsNumber()
  @Min(100)
  bmcCapacityLitres?: number;

  @ApiPropertyOptional({ example: 1.0, description: 'Base concentrate ration (kg/day)' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  feedBaseKg?: number;

  @ApiPropertyOptional({ example: 0.4, description: 'Additional concentrate per litre of daily milk' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  feedRatePerLitre?: number;

  @ApiPropertyOptional({ example: 8.0, description: 'Maximum concentrate ceiling (kg/day)' })
  @IsOptional()
  @IsNumber()
  @Min(1)
  feedMaxCapKg?: number;

  @ApiPropertyOptional({ example: 1.4, description: 'Electricity tariff rate in INR per unit' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  electricityTariff?: number;

  @ApiPropertyOptional({ example: 50.0, description: 'Default farm power consumption units/day' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  farmDefaultKwh?: number;

  @ApiPropertyOptional({ example: 200.0, description: 'Default production power consumption units/day' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  productionDefaultKwh?: number;

  @ApiPropertyOptional({ example: 50.0, description: 'Management salary percentage allocated to farm' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(100)
  mgmtSalaryToFarmPct?: number;

  @ApiPropertyOptional({ example: 'Kaivalya team' })
  @IsOptional()
  @IsString()
  operatorName?: string;

  @ApiPropertyOptional({ example: 'Asia/Kolkata' })
  @IsOptional()
  @IsString()
  timezone?: string;
}
