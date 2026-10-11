import {
  IsString,
  IsOptional,
  IsEnum,
  IsNumber,
  IsDateString,
  Min,
  ValidateIf,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { FeedType, FeedShift } from '../entities/feed-entry.entity';

export class CreateFeedEntryDto {
  @ApiPropertyOptional({ description: 'Target cow animal ID. Optional if group feeding.' })
  @IsOptional()
  @IsString()
  animalId?: string;

  @ApiPropertyOptional({ description: 'Target cattle group designation (e.g. Lactating Herd A)' })
  @ValidateIf((o) => !o.animalId)
  @IsString()
  groupName?: string;

  @ApiPropertyOptional({ description: 'Linked ration definition ID' })
  @IsOptional()
  @IsString()
  rationId?: string;

  @ApiProperty({ description: 'Feeding record date (YYYY-MM-DD)', example: '2026-10-11' })
  @IsDateString()
  recordDate: string;

  @ApiProperty({ description: 'Feed stock item inventory ID', example: 'stk-conc' })
  @IsString()
  stockItemId: string;

  @ApiProperty({ description: 'Quantity issued in kilograms', example: 7.0 })
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0.01)
  quantityKg: number;

  @ApiProperty({ enum: FeedType, description: 'Feed nutritional classification', example: 'CONCENTRATE' })
  @IsEnum(FeedType)
  feedType: FeedType;

  @ApiPropertyOptional({ enum: FeedShift, description: 'Feeding shift', default: 'ALL_DAY' })
  @IsOptional()
  @IsEnum(FeedShift)
  shift?: FeedShift;

  @ApiPropertyOptional({ description: 'Operational notes' })
  @IsOptional()
  @IsString()
  notes?: string;
}
