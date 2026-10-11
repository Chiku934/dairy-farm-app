import {
  IsString,
  IsOptional,
  IsEnum,
  IsNumber,
  IsArray,
  ValidateNested,
  Min,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { TargetAnimalStage } from '../entities/ration-definition.entity';

export class CreateRationItemDto {
  @ApiProperty({ description: 'Stock item inventory ID', example: 'stk-conc' })
  @IsString()
  stockItemId: string;

  @ApiProperty({ description: 'Ingredient quantity per animal/day in kg', example: 6.0 })
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0.01)
  quantityKg: number;

  @ApiPropertyOptional({ description: 'Ingredient formulation notes' })
  @IsOptional()
  @IsString()
  notes?: string;
}

export class CreateRationDto {
  @ApiProperty({ description: 'Ration diet title', example: 'High-Yielding Lactating TMR' })
  @IsString()
  name: string;

  @ApiProperty({ description: 'Unique ration code', example: 'RATION-LACT-HIGH' })
  @IsString()
  code: string;

  @ApiProperty({ enum: TargetAnimalStage, description: 'Target lifecycle stage', example: 'LACTATING' })
  @IsEnum(TargetAnimalStage)
  targetStage: TargetAnimalStage;

  @ApiPropertyOptional({ description: 'Detailed diet explanation or feeding instructions' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({ type: [CreateRationItemDto], description: 'List of feed ingredient components' })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateRationItemDto)
  items: CreateRationItemDto[];
}
