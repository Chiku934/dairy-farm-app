import {
  IsString,
  IsNotEmpty,
  IsDateString,
  IsNumber,
  Min,
  IsOptional,
  IsEnum,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { CostCentre, ExpenseCategory, PaymentMethod } from '@dairy-farm/api-contracts';

export class CreateExpenseDto {
  @ApiPropertyOptional({ description: 'Unique internal expense reference code' })
  @IsString()
  @IsOptional()
  expenseNumber?: string;

  @ApiProperty({ description: 'Expense date (YYYY-MM-DD)' })
  @IsDateString()
  @IsNotEmpty()
  recordDate: string;

  @ApiProperty({ enum: CostCentre, description: 'Allocated cost centre department' })
  @IsEnum(CostCentre)
  costCentre: CostCentre;

  @ApiProperty({ enum: ExpenseCategory, description: 'Operating expense category' })
  @IsEnum(ExpenseCategory)
  category: ExpenseCategory;

  @ApiProperty({ description: 'Disbursed expense amount in INR' })
  @IsNumber()
  @Min(0.01)
  amount: number;

  @ApiPropertyOptional({ description: 'Optional production batch UUID to assign direct batch overhead' })
  @IsString()
  @IsOptional()
  productionBatchId?: string;

  @ApiPropertyOptional({ description: 'Payee or vendor name' })
  @IsString()
  @IsOptional()
  payee?: string;

  @ApiPropertyOptional({ description: 'Vendor invoice or voucher number to avoid duplicate entries' })
  @IsString()
  @IsOptional()
  invoiceNumber?: string;

  @ApiPropertyOptional({ enum: PaymentMethod, default: PaymentMethod.CASH })
  @IsEnum(PaymentMethod)
  @IsOptional()
  paymentMethod?: PaymentMethod;

  @ApiPropertyOptional({ description: 'Expense notes and remarks' })
  @IsString()
  @IsOptional()
  notes?: string;
}
