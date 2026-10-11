import { IsString, IsNotEmpty, IsNumber, IsOptional, IsDateString, Min } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateStockReceiptDto {
  @ApiPropertyOptional({ description: 'Explicit receipt code. If omitted, generated automatically.' })
  @IsString()
  @IsOptional()
  receiptNumber?: string;

  @ApiProperty({ description: 'Receipt date in YYYY-MM-DD format' })
  @IsDateString()
  recordDate: string;

  @ApiProperty({ description: 'Target stock item UUID' })
  @IsString()
  @IsNotEmpty()
  stockItemId: string;

  @ApiPropertyOptional({ description: 'Registered supplier UUID' })
  @IsString()
  @IsOptional()
  supplierId?: string;

  @ApiPropertyOptional({ description: 'Supplier / vendor business name' })
  @IsString()
  @IsOptional()
  supplierName?: string;

  @ApiPropertyOptional({ description: 'Supplier lot or delivery challan / invoice number' })
  @IsString()
  @IsOptional()
  supplierLot?: string;

  @ApiProperty({ description: 'Inbound quantity received' })
  @IsNumber()
  @Min(0.01)
  quantity: number;

  @ApiProperty({ description: 'Unit purchase price in INR' })
  @IsNumber()
  @Min(0.01)
  unitPrice: number;

  @ApiPropertyOptional({ description: 'Item expiry date in YYYY-MM-DD format' })
  @IsDateString()
  @IsOptional()
  expiryDate?: string;

  @ApiPropertyOptional({ description: 'Delivery remarks or QC verification notes' })
  @IsString()
  @IsOptional()
  notes?: string;
}
