import {
  IsString,
  IsNotEmpty,
  IsDateString,
  IsOptional,
  IsArray,
  ValidateNested,
  IsEnum,
  IsNumber,
  Min,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ProductType } from '@dairy-farm/api-contracts';

export class CreateSalesOrderItemDto {
  @ApiProperty({ enum: ProductType, description: 'Dairy product type' })
  @IsEnum(ProductType)
  productType: ProductType;

  @ApiPropertyOptional({ description: 'Pack size (e.g. 0.5, 1.0)', default: 1.0 })
  @IsNumber()
  @Min(0.01)
  @IsOptional()
  packSize?: number;

  @ApiPropertyOptional({ description: 'Pack unit (e.g. LITRE, KG)', default: 'LITRE' })
  @IsString()
  @IsOptional()
  packUnit?: string;

  @ApiProperty({ description: 'Number of packs ordered' })
  @IsNumber()
  @Min(1)
  quantityOrdered: number;

  @ApiProperty({ description: 'Agreed unit price per pack in INR' })
  @IsNumber()
  @Min(0.01)
  unitPrice: number;
}

export class CreateSalesOrderDto {
  @ApiPropertyOptional({ description: 'Order reference number. Generated automatically if omitted.' })
  @IsString()
  @IsOptional()
  orderNumber?: string;

  @ApiProperty({ description: 'Customer UUID' })
  @IsString()
  @IsNotEmpty()
  customerId: string;

  @ApiProperty({ description: 'Order booking date in YYYY-MM-DD' })
  @IsDateString()
  orderDate: string;

  @ApiProperty({ description: 'Target delivery date in YYYY-MM-DD' })
  @IsDateString()
  deliveryDate: string;

  @ApiProperty({ type: [CreateSalesOrderItemDto], description: 'List of order lines' })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateSalesOrderItemDto)
  items: CreateSalesOrderItemDto[];

  @ApiPropertyOptional({ description: 'Special delivery or handling instructions' })
  @IsString()
  @IsOptional()
  notes?: string;
}
