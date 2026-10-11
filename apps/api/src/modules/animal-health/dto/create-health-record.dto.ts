import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsEnum,
  IsDateString,
  MaxLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { CareType } from '../entities/health-record.entity';

export class CreateHealthRecordDto {
  @ApiProperty({ description: 'Referenced animal UUID identifier or earTag', example: 'c-01' })
  @IsString()
  @IsNotEmpty()
  animalId: string;

  @ApiProperty({ description: 'Date of administration or examination (ISO YYYY-MM-DD)', example: '2026-10-11' })
  @IsDateString()
  @IsNotEmpty()
  recordDate: string;

  @ApiProperty({ enum: CareType, description: 'Care type (TREATMENT, VACCINATION, DEWORMING, EXAMINATION)' })
  @IsEnum(CareType)
  @IsNotEmpty()
  careType: CareType;

  @ApiPropertyOptional({
    description: 'Veterinary diagnosis distinct from treatment (e.g. Acute Mastitis, Ketosis, Foot Rot, Routine Check)',
    example: 'Acute Mastitis in right front quarter',
  })
  @IsOptional()
  @IsString()
  @MaxLength(150)
  diagnosis?: string;

  @ApiProperty({
    description: 'Medicine or vaccine compound administered',
    example: 'Ceftiofur Sodium Injection',
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  medicineVaccine: string;

  @ApiProperty({
    description: 'Prescribed dosage, route and frequency',
    example: '10ml IM daily for 3 days',
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  prescribedDose: string;

  @ApiPropertyOptional({
    description: 'Attending veterinarian name',
    example: 'Dr. B. K. Panda',
  })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  veterinarian?: string;

  @ApiPropertyOptional({
    description: 'Next scheduled booster or re-examination date (ISO YYYY-MM-DD)',
    example: '2026-10-18',
  })
  @IsOptional()
  @IsDateString()
  nextDueDate?: string;

  @ApiPropertyOptional({
    description: 'Milk withdrawal expiration date (ISO YYYY-MM-DD)',
    example: '2026-10-14',
  })
  @IsOptional()
  @IsDateString()
  withdrawalUntil?: string;

  @ApiPropertyOptional({
    description: 'Clinical findings, temperature, or response observations',
  })
  @IsOptional()
  @IsString()
  notes?: string;
}
