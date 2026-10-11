import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsEnum,
  IsNumber,
  IsDateString,
  Min,
  Max,
  Length,
  MaxLength,
  Matches,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { AnimalSex, AnimalStatus } from '../entities/animal.entity';

export class CreateAnimalDto {
  @ApiProperty({ description: 'Ear tag / RFID identifier (strictly unique)', example: 'TAG-110' })
  @IsString()
  @IsNotEmpty()
  @Length(2, 50)
  @Matches(/^[a-zA-Z0-9-_]+$/, {
    message: 'earTag must contain only alphanumeric characters, dashes, or underscores',
  })
  earTag: string;

  @ApiPropertyOptional({ description: 'Display name or nickname', example: 'Gauri 2' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  name?: string;

  @ApiProperty({ description: 'Cattle breed', example: 'GIR' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(50)
  breed: string;

  @ApiPropertyOptional({ enum: AnimalSex, default: AnimalSex.FEMALE })
  @IsOptional()
  @IsEnum(AnimalSex)
  sex?: AnimalSex;

  @ApiPropertyOptional({ description: 'Date of birth (ISO YYYY-MM-DD)', example: '2023-04-15' })
  @IsOptional()
  @IsDateString()
  dateOfBirth?: string;

  @ApiPropertyOptional({ enum: AnimalStatus, default: AnimalStatus.LACTATING })
  @IsOptional()
  @IsEnum(AnimalStatus)
  status?: AnimalStatus;

  @ApiPropertyOptional({ description: 'Body weight in kg', example: 450.5 })
  @IsOptional()
  @IsNumber()
  @Min(10)
  @Max(1500)
  bodyWeightKg?: number;

  @ApiPropertyOptional({ description: 'Dam (mother) ear tag', example: 'TAG-101' })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  damTag?: string;

  @ApiPropertyOptional({ description: 'Date of last calving (ISO YYYY-MM-DD)', example: '2026-05-10' })
  @IsOptional()
  @IsDateString()
  lastCalvingDate?: string;

  @ApiPropertyOptional({ description: 'Body condition score (1.0 to 5.0)', example: 3.5 })
  @IsOptional()
  @IsNumber()
  @Min(1.0)
  @Max(5.0)
  bodyConditionScore?: number;

  @ApiPropertyOptional({ description: 'Observations, lineage notes or special diet' })
  @IsOptional()
  @IsString()
  notes?: string;
}
