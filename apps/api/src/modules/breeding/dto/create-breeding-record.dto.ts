import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsEnum,
  IsDateString,
  MaxLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { BreedingEventType } from '../entities/breeding-record.entity';

export class CreateBreedingRecordDto {
  @ApiProperty({ description: 'Referenced female animal UUID or earTag', example: 'c-03' })
  @IsString()
  @IsNotEmpty()
  animalId: string;

  @ApiProperty({ description: 'Date of breeding event (ISO YYYY-MM-DD)', example: '2026-10-11' })
  @IsDateString()
  @IsNotEmpty()
  recordDate: string;

  @ApiProperty({
    enum: BreedingEventType,
    description: 'Event type (HEAT, INSEMINATION, PREGNANCY_CONFIRMED, PREGNANCY_CHECK, CALVING, DRY_OFF)',
  })
  @IsEnum(BreedingEventType)
  @IsNotEmpty()
  eventType: BreedingEventType;

  @ApiPropertyOptional({
    description: 'Sire identifier or semen straw lot number (e.g. SIRE-GIR-PRIME-09)',
    example: 'SIRE-GIR-PRIME-09',
  })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  sireSemenId?: string;

  @ApiPropertyOptional({
    description: 'Expected calving date (auto-calculated ~280 days if INSEMINATION and omitted)',
    example: '2027-07-18',
  })
  @IsOptional()
  @IsDateString()
  expectedCalvingDate?: string;

  @ApiPropertyOptional({
    description: 'Next check reminder date (e.g. pregnancy check 45-60 days after AI)',
    example: '2026-11-25',
  })
  @IsOptional()
  @IsDateString()
  nextCheckDate?: string;

  @ApiPropertyOptional({
    description: 'Newborn calf ear tag (applicable when event is CALVING)',
    example: 'TAG-111',
  })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  calfTag?: string;

  @ApiPropertyOptional({
    description: 'Technician name, artificial insemination notes, or calving condition',
  })
  @IsOptional()
  @IsString()
  notes?: string;
}
