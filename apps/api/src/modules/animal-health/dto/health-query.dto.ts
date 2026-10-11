import { IsOptional, IsEnum, IsString, IsDateString, IsBoolean } from 'class-validator';
import { Transform } from 'class-transformer';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { PaginationQueryDto } from '../../../common/pagination/pagination.dto';
import { CareType } from '../entities/health-record.entity';

export class HealthQueryDto extends PaginationQueryDto {
  @ApiPropertyOptional({ description: 'Filter by animal UUID or earTag' })
  @IsOptional()
  @IsString()
  animalId?: string;

  @ApiPropertyOptional({ enum: CareType, description: 'Filter by care type (TREATMENT, VACCINATION, DEWORMING, EXAMINATION)' })
  @IsOptional()
  @IsEnum(CareType)
  careType?: CareType;

  @ApiPropertyOptional({ description: 'Filter from record date (ISO YYYY-MM-DD)' })
  @IsOptional()
  @IsDateString()
  fromDate?: string;

  @ApiPropertyOptional({ description: 'Filter to record date (ISO YYYY-MM-DD)' })
  @IsOptional()
  @IsDateString()
  toDate?: string;

  @ApiPropertyOptional({ description: 'Filter only records with active milk withdrawal' })
  @IsOptional()
  @Transform(({ value }) => value === true || value === 'true' || value === '1')
  @IsBoolean()
  activeWithdrawalOnly?: boolean;
}
