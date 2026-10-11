import {
  IsString,
  IsNotEmpty,
  IsDateString,
  IsOptional,
  IsEnum,
  IsNumber,
  Min,
  IsArray,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ProductType, PaymentMethod } from '@dairy-farm/api-contracts';

export class CreateSalesDispatchItemDto {
  @ApiPropertyOptional({ description: 'Referenced sales order line item UUID' })
  @IsString()
  @IsOptional()
  orderItemId?: string;

  @ApiPropertyOptional({ description: 'Packaging run UUID for traceability' })
  @IsString()
  @IsOptional()
  packagingRunId?: string;

  @ApiProperty({ enum: ProductType, description: 'Product type' })
  @IsEnum(ProductType)
  productType: ProductType;

  @ApiPropertyOptional({ description: 'Pack size', default: 1.0 })
  @IsNumber()
  @Min(0.01)
  @IsOptional()
  packSize?: number;

  @ApiPropertyOptional({ description: 'Pack unit', default: 'LITRE' })
  @IsString()
  @IsOptional()
  packUnit?: string;

  @ApiProperty({ description: 'Packs dispatched' })
  @IsNumber()
  @Min(1)
  quantity: number;

  @ApiProperty({ description: 'Unit selling price' })
  @IsNumber()
  @Min(0.01)
  unitPrice: number;
}

export class CreateSalesDispatchDto {
  @ApiPropertyOptional({ description: 'Dispatch note number. Generated automatically if omitted.' })
  @IsString()
  @IsOptional()
  dispatchNumber?: string;

  @ApiPropertyOptional({ description: 'Referenced Sales Order UUID for fulfillment' })
  @IsString()
  @IsOptional()
  orderId?: string;

  @ApiProperty({ description: 'Customer UUID' })
  @IsString()
  @IsNotEmpty()
  customerId: string;

  @ApiProperty({ description: 'Dispatch date in YYYY-MM-DD' })
  @IsDateString()
  recordDate: string;

  @ApiPropertyOptional({ description: 'Packaging run UUID for single-line dispatch' })
  @IsString()
  @IsOptional()
  packagingRunId?: string;

  @ApiPropertyOptional({ enum: ProductType, description: 'Primary product type' })
  @IsEnum(ProductType)
  @IsOptional()
  productType?: ProductType;

  @ApiPropertyOptional({ description: 'Primary packs sold' })
  @IsNumber()
  @Min(1)
  @IsOptional()
  packsSold?: number;

  @ApiPropertyOptional({ description: 'Price per pack' })
  @IsNumber()
  @Min(0.01)
  @IsOptional()
  pricePerPack?: number;

  @ApiPropertyOptional({ description: 'Immediate cash/advance amount received at dispatch time' })
  @IsNumber()
  @Min(0)
  @IsOptional()
  amountReceived?: number;

  @ApiPropertyOptional({ enum: PaymentMethod, default: PaymentMethod.CASH })
  @IsEnum(PaymentMethod)
  @IsOptional()
  paymentMethod?: PaymentMethod;

  @ApiPropertyOptional({ type: [CreateSalesDispatchItemDto], description: 'Optional multi-line dispatch items' })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateSalesDispatchItemDto)
  @IsOptional()
  items?: CreateSalesDispatchItemDto[];

  @ApiPropertyOptional({ description: 'Dispatch remarks' })
  @IsString()
  @IsOptional()
  notes?: string;
}
