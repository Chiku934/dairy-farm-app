import { IsString, IsNotEmpty, IsEnum, IsOptional, IsNumber, Min } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { CustomerType } from '@dairy-farm/api-contracts';

export class CreateCustomerDto {
  @ApiProperty({ description: 'Customer legal or shop name' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiPropertyOptional({ description: 'Phone number' })
  @IsString()
  @IsOptional()
  phone?: string;

  @ApiPropertyOptional({ description: 'Email address' })
  @IsString()
  @IsOptional()
  email?: string;

  @ApiPropertyOptional({ description: 'Delivery address' })
  @IsString()
  @IsOptional()
  address?: string;

  @ApiProperty({ enum: CustomerType, description: 'Customer category (RETAIL or WHOLESALE)' })
  @IsEnum(CustomerType)
  customerType: CustomerType;

  @ApiPropertyOptional({ description: 'Authorized credit balance limit in INR' })
  @IsNumber()
  @Min(0)
  @IsOptional()
  creditLimit?: number;
}
