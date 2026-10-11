import { IsString, IsNotEmpty, IsDateString, IsEnum, IsNumber, Min, IsOptional } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { PaymentMethod } from '@dairy-farm/api-contracts';

export class CreateCustomerPaymentDto {
  @ApiPropertyOptional({ description: 'Payment receipt number. Generated automatically if omitted.' })
  @IsString()
  @IsOptional()
  paymentNumber?: string;

  @ApiProperty({ description: 'Customer UUID' })
  @IsString()
  @IsNotEmpty()
  customerId: string;

  @ApiPropertyOptional({ description: 'Specific Sales Dispatch UUID to settle balance' })
  @IsString()
  @IsOptional()
  dispatchId?: string;

  @ApiProperty({ description: 'Payment date in YYYY-MM-DD' })
  @IsDateString()
  recordDate: string;

  @ApiProperty({ description: 'Amount collected in INR' })
  @IsNumber()
  @Min(0.01)
  amountReceived: number;

  @ApiProperty({ enum: PaymentMethod, default: PaymentMethod.CASH })
  @IsEnum(PaymentMethod)
  paymentMethod: PaymentMethod;

  @ApiPropertyOptional({ description: 'UPI Transaction ID, cheque number, or bank reference' })
  @IsString()
  @IsOptional()
  referenceCode?: string;

  @ApiPropertyOptional({ description: 'Payment notes' })
  @IsString()
  @IsOptional()
  notes?: string;
}
