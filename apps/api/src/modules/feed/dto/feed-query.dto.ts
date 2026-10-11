import { IsOptional, IsString, IsEnum, IsDateString } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { PaginationQueryDto } from '../../../common/pagination/pagination.dto';
import { FeedType } from '../entities/feed-entry.entity';

export class FeedQueryDto extends PaginationQueryDto {
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

  @ApiPropertyOptional({ description: 'Filter by animal ID' })
  @IsOptional()
  @IsString()
  animalId?: string;

  @ApiPropertyOptional({ description: 'Filter by cattle group name' })
  @IsOptional()
  @IsString()
  groupName?: string;

  @ApiPropertyOptional({ enum: FeedType, description: 'Filter by feed classification' })
  @IsOptional()
  @IsEnum(FeedType)
  feedType?: FeedType;

  @ApiPropertyOptional({ description: 'Filter by inventory stock item ID' })
  @IsOptional()
  @IsString()
  stockItemId?: string;

  @ApiPropertyOptional({ description: 'Filter by ration definition ID' })
  @IsOptional()
  @IsString()
  rationId?: string;
}
