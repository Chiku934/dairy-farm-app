import { IsOptional, IsString, IsEnum, IsDateString } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { PaginationQueryDto } from '../../../common/pagination/pagination.dto';
import { OrderStatus, ProductType } from '@dairy-farm/api-contracts';

export class SalesOrderQueryDto extends PaginationQueryDto {
  @ApiPropertyOptional({ enum: OrderStatus })
  @IsEnum(OrderStatus)
  @IsOptional()
  status?: OrderStatus;

  @ApiPropertyOptional({ description: 'Filter by customer UUID' })
  @IsString()
  @IsOptional()
  customerId?: string;

  @ApiPropertyOptional({ description: 'Filter from order date' })
  @IsDateString()
  @IsOptional()
  startDate?: string;

  @ApiPropertyOptional({ description: 'Filter to order date' })
  @IsDateString()
  @IsOptional()
  endDate?: string;
}

export class SalesDispatchQueryDto extends PaginationQueryDto {
  @ApiPropertyOptional({ enum: ProductType })
  @IsEnum(ProductType)
  @IsOptional()
  productType?: ProductType;

  @ApiPropertyOptional({ description: 'Filter by customer UUID' })
  @IsString()
  @IsOptional()
  customerId?: string;

  @ApiPropertyOptional({ description: 'Filter by order UUID' })
  @IsString()
  @IsOptional()
  orderId?: string;

  @ApiPropertyOptional({ description: 'Filter from dispatch date' })
  @IsDateString()
  @IsOptional()
  startDate?: string;

  @ApiPropertyOptional({ description: 'Filter to dispatch date' })
  @IsDateString()
  @IsOptional()
  endDate?: string;
}

export class CustomerPaymentQueryDto extends PaginationQueryDto {
  @ApiPropertyOptional({ description: 'Filter by customer UUID' })
  @IsString()
  @IsOptional()
  customerId?: string;

  @ApiPropertyOptional({ description: 'Filter by dispatch UUID' })
  @IsString()
  @IsOptional()
  dispatchId?: string;

  @ApiPropertyOptional({ description: 'Filter from payment date' })
  @IsDateString()
  @IsOptional()
  startDate?: string;

  @ApiPropertyOptional({ description: 'Filter to payment date' })
  @IsDateString()
  @IsOptional()
  endDate?: string;
}
