import {
  IsString,
  IsNotEmpty,
  IsEnum,
  IsDateString,
  IsOptional,
  IsInt,
  Min,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  LicenceType,
  LicenceStatus,
  ReminderStatus,
} from '@dairy-farm/api-contracts';

export class CreateLicenceDto {
  @ApiProperty({ example: 'FSSAI Food Safety Licence', description: 'Display name of licence' })
  @IsString()
  @IsNotEmpty()
  licenceName: string;

  @ApiPropertyOptional({ enum: LicenceType, default: LicenceType.OTHER })
  @IsOptional()
  @IsEnum(LicenceType)
  licenceType?: LicenceType;

  @ApiProperty({ example: '10020031000123', description: 'Unique regulatory licence registration number' })
  @IsString()
  @IsNotEmpty()
  licenceNumber: string;

  @ApiProperty({ example: 'Food Safety and Standards Authority of India' })
  @IsString()
  @IsNotEmpty()
  issuingAuthority: string;

  @ApiProperty({ example: 'Green Pastures Organic Dairy Ltd' })
  @IsString()
  @IsNotEmpty()
  licenceHolder: string;

  @ApiProperty({ example: '2024-01-01', description: 'Date of issuance (YYYY-MM-DD)' })
  @IsDateString()
  issueDate: string;

  @ApiProperty({ example: '2027-01-01', description: 'Expiration date (YYYY-MM-DD)' })
  @IsDateString()
  expiryDate: string;

  @ApiPropertyOptional({ example: 30, default: 30, description: 'Lead time in days for expiry reminder' })
  @IsOptional()
  @IsInt()
  @Min(1)
  reminderDaysBefore?: number;

  @ApiPropertyOptional({ enum: LicenceStatus })
  @IsOptional()
  @IsEnum(LicenceStatus)
  status?: LicenceStatus;

  @ApiPropertyOptional({ enum: ReminderStatus })
  @IsOptional()
  @IsEnum(ReminderStatus)
  reminderStatus?: ReminderStatus;

  @ApiPropertyOptional({ example: 'https://storage.dairyfarm.local/docs/fssai-2024.pdf' })
  @IsOptional()
  @IsString()
  documentUrl?: string;

  @ApiPropertyOptional({ example: 'Registered for processing 2000L milk daily' })
  @IsOptional()
  @IsString()
  notes?: string;
}
