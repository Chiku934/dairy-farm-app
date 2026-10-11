import { IsOptional, IsString, IsEnum, IsDateString } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { PaginationQueryDto } from '../../../common/pagination/pagination.dto';
import { MilkingSession, MilkDisposition } from '../entities/milking-log.entity';

export class MilkingQueryDto extends PaginationQueryDto {
  @ApiPropertyOptional({ description: 'Filter by exact date (YYYY-MM-DD)' })
  @IsOptional()
  @IsDateString()
  date?: string;

  @ApiPropertyOptional({ description: 'Filter start date (YYYY-MM-DD)' })
  @IsOptional()
  @IsDateString()
  startDate?: string;

  @ApiPropertyOptional({ description: 'Filter end date (YYYY-MM-DD)' })
  @IsOptional()
  @IsDateString()
  endDate?: string;

  @ApiPropertyOptional({ enum: MilkingSession, description: 'Filter by shift session' })
  @IsOptional()
  @IsEnum(MilkingSession)
  session?: MilkingSession;

  @ApiPropertyOptional({ description: 'Filter by cow animal ID' })
  @IsOptional()
  @IsString()
  animalId?: string;

  @ApiPropertyOptional({ description: 'Filter by group designation' })
  @IsOptional()
  @IsString()
  groupName?: string;

  @ApiPropertyOptional({ enum: MilkDisposition, description: 'Filter by disposition' })
  @IsOptional()
  @IsEnum(MilkDisposition)
  disposition?: MilkDisposition;
}
