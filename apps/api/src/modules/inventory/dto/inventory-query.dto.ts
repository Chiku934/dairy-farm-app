import { IsOptional, IsString, IsEnum, IsBoolean } from 'class-validator';
import { Type, Transform } from 'class-transformer';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { PaginationQueryDto } from '../../../common/pagination/pagination.dto';
import { StockCategory } from '@dairy-farm/api-contracts';
import { StockUsedBy } from '../../feed/entities/stock-item.entity';

export class InventoryQueryDto extends PaginationQueryDto {
  @ApiPropertyOptional({ enum: StockCategory })
  @IsEnum(StockCategory)
  @IsOptional()
  category?: StockCategory;

  @ApiPropertyOptional({ enum: StockUsedBy })
  @IsEnum(StockUsedBy)
  @IsOptional()
  usedBy?: StockUsedBy;

  @ApiPropertyOptional({ description: 'Filter only items where current_stock <= reorder_level' })
  @Transform(({ value }) => value === 'true' || value === true)
  @IsBoolean()
  @IsOptional()
  lowStockOnly?: boolean;

  @ApiPropertyOptional({ description: 'Search query for item name' })
  @IsString()
  @IsOptional()
  search?: string;
}
