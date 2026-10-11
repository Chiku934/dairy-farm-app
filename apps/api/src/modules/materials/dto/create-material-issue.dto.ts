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

export class CreateMaterialIssueDto {
  @IsNotEmpty()
  @IsDateString()
  recordDate: string;

  @IsNotEmpty()
  @IsEnum(Department)
  department: Department;

  @IsNotEmpty()
  @IsString()
  stockItemId: string;

  @IsNotEmpty()
  @IsNumber()
  @Min(0.01)
  quantity: number;

  @IsOptional()
  @IsString()
  productionBatchId?: string;

  @IsOptional()
  @IsString()
  issuedTo?: string;

  @IsOptional()
  @IsString()
  notes?: string;
}
