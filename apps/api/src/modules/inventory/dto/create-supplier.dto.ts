import { IsString, IsNotEmpty, IsEnum, IsOptional } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { SupplierCategory } from '@dairy-farm/api-contracts';

export class CreateSupplierDto {
  @ApiProperty({ description: 'Supplier / vendor legal or trading name' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiPropertyOptional({ description: 'Primary contact person name' })
  @IsString()
  @IsOptional()
  contactPerson?: string;

  @ApiPropertyOptional({ description: 'Phone number' })
  @IsString()
  @IsOptional()
  phone?: string;

  @ApiPropertyOptional({ description: 'Email address' })
  @IsString()
  @IsOptional()
  email?: string;

  @ApiPropertyOptional({ description: 'Business address' })
  @IsString()
  @IsOptional()
  address?: string;

  @ApiProperty({ enum: SupplierCategory, description: 'Supplier product category' })
  @IsEnum(SupplierCategory)
  category: SupplierCategory;
}
