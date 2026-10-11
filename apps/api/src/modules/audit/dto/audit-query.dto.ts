import { IsOptional, IsString } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { PaginationQueryDto } from '../../../common/pagination/pagination.dto';

export class AuditQueryDto extends PaginationQueryDto {
  @ApiPropertyOptional({ description: 'Filter by entity type (e.g. USER, SETTINGS, STOCK)' })
  @IsOptional()
  @IsString()
  entityType?: string;

  @ApiPropertyOptional({ description: 'Filter by action code (e.g. CREATE, UPDATE, DELETE)' })
  @IsOptional()
  @IsString()
  action?: string;

  @ApiPropertyOptional({ description: 'Filter by actor User ID' })
  @IsOptional()
  @IsString()
  userId?: string;
}
