import { IsNotEmpty, IsOptional, IsString } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateLookupCategoryDto {
  @ApiProperty({ example: 'VACCINE_TYPE', description: 'Unique category identifier code' })
  @IsString()
  @IsNotEmpty()
  code: string;

  @ApiProperty({ example: 'Vaccine Types' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiPropertyOptional({ example: 'Classifications of veterinary vaccines administered' })
  @IsOptional()
  @IsString()
  description?: string;
}

export class CreateLookupValueDto {
  @ApiProperty({ example: 'ANIMAL_BREED', description: 'Category code this value belongs to' })
  @IsString()
  @IsNotEmpty()
  categoryCode: string;

  @ApiProperty({ example: 'SAHIWAL', description: 'Unique code within the category' })
  @IsString()
  @IsNotEmpty()
  code: string;

  @ApiProperty({ example: 'Sahiwal Indigenous' })
  @IsString()
  @IsNotEmpty()
  label: string;

  @ApiPropertyOptional({ example: 1, default: 0 })
  @IsOptional()
  sortOrder?: number;

  @ApiPropertyOptional({ example: { origin: 'India' } })
  @IsOptional()
  metadata?: any;
}
