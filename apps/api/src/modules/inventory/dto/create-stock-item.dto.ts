import { IsString, IsNotEmpty, IsEnum, IsNumber, IsOptional, Min } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { StockCategory } from '@dairy-farm/api-contracts';
import { StockUsedBy } from '../../feed/entities/stock-item.entity';

export class CreateStockItemDto {
  @ApiProperty({ description: 'Unique name of the stock item' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ enum: StockUsedBy, description: 'Cost centre/department that utilizes this item' })
  @IsEnum(StockUsedBy)
  usedBy: StockUsedBy;

  @ApiProperty({ enum: StockCategory, description: 'Inventory category' })
  @IsEnum(StockCategory)
  category: StockCategory;

  @ApiProperty({ description: 'Unit of measure (e.g., kg, L, units, bags, rolls)' })
  @IsString()
  @IsNotEmpty()
  unit: string;

  @ApiPropertyOptional({ description: 'Initial stock balance on hand' })
  @IsNumber()
  @Min(0)
  @IsOptional()
  initialStock?: number;

  @ApiPropertyOptional({ description: 'Initial or standard purchase price' })
  @IsNumber()
  @Min(0)
  @IsOptional()
  initialPrice?: number;

  @ApiPropertyOptional({ description: 'Reorder trigger threshold level' })
  @IsNumber()
  @Min(0)
  @IsOptional()
  reorderLevel?: number;

  @ApiPropertyOptional({ description: 'Additional item specifications or storage notes' })
  @IsString()
  @IsOptional()
  notes?: string;
}
