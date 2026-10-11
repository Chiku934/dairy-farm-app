import { IsOptional, IsEnum, IsString, IsDateString } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { PaginationQueryDto } from '../../../common/pagination/pagination.dto';
import { BreedingEventType } from '../entities/breeding-record.entity';

export class BreedingQueryDto extends PaginationQueryDto {
  @ApiPropertyOptional({ description: 'Filter by animal UUID or earTag' })
  @IsOptional()
  @IsString()
  animalId?: string;

  @ApiPropertyOptional({
    enum: BreedingEventType,
    description: 'Filter by event type (HEAT, INSEMINATION, PREGNANCY_CONFIRMED, PREGNANCY_CHECK, CALVING, DRY_OFF)',
  })
  @IsOptional()
  @IsEnum(BreedingEventType)
  eventType?: BreedingEventType;

  @ApiPropertyOptional({ description: 'Filter from record date (ISO YYYY-MM-DD)' })
  @IsOptional()
  @IsDateString()
  fromDate?: string;

  @ApiPropertyOptional({ description: 'Filter to record date (ISO YYYY-MM-DD)' })
  @IsOptional()
  @IsDateString()
  toDate?: string;
}
