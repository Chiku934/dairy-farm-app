import {
  IsNotEmpty,
  IsString,
  IsDateString,
  IsEnum,
  IsNumber,
  IsOptional,
  Min,
} from 'class-validator';
import { Department } from '@dairy-farm/api-contracts';

export class CreateElectricityReadingDto {
  @IsNotEmpty()
  @IsDateString()
  recordDate: string;

  @IsNotEmpty()
  @IsEnum(Department)
  department: Department;

  @IsOptional()
  @IsNumber()
  @Min(0)
  openingReadingKwh?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  closingReadingKwh?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  unitsKwh?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  tariffRate?: number;

  @IsOptional()
  @IsString()
  notes?: string;
}
