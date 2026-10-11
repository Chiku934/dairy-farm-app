import { IsNumber, IsOptional, IsString, Min, Max } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class UpdateFarmSettingsDto {
  @ApiProperty({ example: 2000.0, description: 'Bulk Milk Cooler capacity in litres' })
  @IsNumber()
  @Min(100)
  bmcCapacityLitres: number;

  @ApiProperty({ example: 1.0, description: 'Base concentrate ration (kg/day)' })
  @IsNumber()
  @Min(0)
  feedBaseKg: number;

  @ApiProperty({ example: 0.4, description: 'Additional concentrate per litre of daily milk' })
  @IsNumber()
  @Min(0)
  feedRatePerLitre: number;

  @ApiProperty({ example: 8.0, description: 'Maximum concentrate ceiling (kg/day)' })
  @IsNumber()
  @Min(1)
  feedMaxCapKg: number;

  @ApiProperty({ example: 1.4, description: 'Electricity tariff rate in INR per unit' })
  @IsNumber()
  @Min(0)
  electricityTariff: number;

  @ApiProperty({ example: 50.0, description: 'Default farm power consumption units/day' })
  @IsNumber()
  @Min(0)
  farmDefaultKwh: number;

  @ApiProperty({ example: 200.0, description: 'Default production power consumption units/day' })
  @IsNumber()
  @Min(0)
  productionDefaultKwh: number;

  @ApiProperty({ example: 50.0, description: 'Management salary percentage allocated to farm' })
  @IsNumber()
  @Min(0)
  @Max(100)
  mgmtSalaryToFarmPct: number;

  @ApiProperty({ example: 'Kaivalya team', required: false })
  @IsOptional()
  @IsString()
  operatorName?: string;
}
