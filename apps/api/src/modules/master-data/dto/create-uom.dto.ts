import {
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Min,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { UomDimension } from '../entities/unit-of-measurement.entity';

export class CreateUomDto {
  @ApiProperty({ example: 'LTR', description: 'Unique UOM code' })
  @IsString()
  @IsNotEmpty()
  code: string;

  @ApiProperty({ example: 'Litre', description: 'Full unit name' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ enum: UomDimension, default: UomDimension.COUNT })
  @IsEnum(UomDimension)
  dimension: UomDimension;

  @ApiPropertyOptional({ example: 1.0, description: 'Conversion multiplier to base unit' })
  @IsOptional()
  @IsNumber()
  @Min(0.000001)
  conversionFactor?: number;

  @ApiPropertyOptional({ example: 'LTR', description: 'Base unit code within the dimension' })
  @IsOptional()
  @IsString()
  baseUnitCode?: string;
}
