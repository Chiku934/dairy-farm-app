import {
  IsString,
  IsEnum,
  IsDateString,
  IsOptional,
  IsInt,
  Min,
} from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  LicenceType,
  LicenceStatus,
  ReminderStatus,
} from '@dairy-farm/api-contracts';

export class UpdateLicenceDto {
  @ApiPropertyOptional({ example: 'FSSAI Food Safety Licence' })
  @IsOptional()
  @IsString()
  licenceName?: string;

  @ApiPropertyOptional({ enum: LicenceType })
  @IsOptional()
  @IsEnum(LicenceType)
  licenceType?: LicenceType;

  @ApiPropertyOptional({ example: '10020031000123' })
  @IsOptional()
  @IsString()
  licenceNumber?: string;

  @ApiPropertyOptional({ example: 'Food Safety and Standards Authority of India' })
  @IsOptional()
  @IsString()
  issuingAuthority?: string;

  @ApiPropertyOptional({ example: 'Green Pastures Organic Dairy Ltd' })
  @IsOptional()
  @IsString()
  licenceHolder?: string;

  @ApiPropertyOptional({ example: '2024-01-01' })
  @IsOptional()
  @IsDateString()
  issueDate?: string;

  @ApiPropertyOptional({ example: '2027-01-01' })
  @IsOptional()
  @IsDateString()
  expiryDate?: string;

  @ApiPropertyOptional({ example: 30 })
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
