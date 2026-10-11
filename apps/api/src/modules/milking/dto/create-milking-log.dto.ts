import {
  IsString,
  IsOptional,
  IsEnum,
  IsNumber,
  IsDateString,
  Min,
  Max,
  ValidateIf,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { MilkingSession, MilkDisposition } from '../entities/milking-log.entity';

export class CreateMilkingLogDto {
  @ApiPropertyOptional({ description: 'Target cow animal ID. Optional if recording for group.' })
  @IsOptional()
  @IsString()
  animalId?: string;

  @ApiPropertyOptional({ description: 'Group or bulk herd designation (e.g. Group 1 - High Yielders)' })
  @ValidateIf((o) => !o.animalId)
  @IsString()
  groupName?: string;

  @ApiProperty({ description: 'Milking session date (YYYY-MM-DD)', example: '2026-10-11' })
  @IsDateString()
  recordDate: string;

  @ApiProperty({ enum: MilkingSession, description: 'Milking shift / session', example: 'MORNING' })
  @IsEnum(MilkingSession)
  session: MilkingSession;

  @ApiProperty({ description: 'Measured milk yield in litres', example: 14.5 })
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0.01)
  @Max(100.0)
  yieldLitres: number;

  @ApiPropertyOptional({ enum: MilkDisposition, description: 'Milk disposition category', default: 'ELIGIBLE' })
  @IsOptional()
  @IsEnum(MilkDisposition)
  disposition?: MilkDisposition;

  @ApiPropertyOptional({ description: 'Reason if milk is withheld from collection pool' })
  @IsOptional()
  @IsString()
  withheldReason?: string;

  @ApiPropertyOptional({ description: 'Authorized operator user ID' })
  @IsOptional()
  @IsString()
  operatorId?: string;

  @ApiPropertyOptional({ description: 'Authorized operator display name' })
  @IsOptional()
  @IsString()
  operatorName?: string;

  @ApiPropertyOptional({ description: 'Observations or comments' })
  @IsOptional()
  @IsString()
  notes?: string;
}
