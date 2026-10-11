import { IsOptional, IsEnum, IsString, IsBoolean } from 'class-validator';
import { Type, Transform } from 'class-transformer';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { PaginationQueryDto } from '../../../common/pagination/pagination.dto';
import { AnimalSex, AnimalStatus } from '../entities/animal.entity';

export class AnimalQueryDto extends PaginationQueryDto {
  @ApiPropertyOptional({
    enum: AnimalStatus,
    description: 'Filter by lifecycle status (LACTATING, DRY, PREGNANT, HEIFER, CALF, BULL, SOLD, DECEASED)',
  })
  @IsOptional()
  @IsEnum(AnimalStatus)
  status?: AnimalStatus;

  @ApiPropertyOptional({
    description: 'Filter by breed (e.g. GIR, SAHIWAL, HOLSTEIN_FRIESIAN, JERSEY, MURRAH)',
  })
  @IsOptional()
  @IsString()
  breed?: string;

  @ApiPropertyOptional({
    enum: AnimalSex,
    description: 'Filter by sex (FEMALE, MALE)',
  })
  @IsOptional()
  @IsEnum(AnimalSex)
  sex?: AnimalSex;

  @ApiPropertyOptional({
    description: 'Include archived/retired animals (default false)',
    default: false,
  })
  @IsOptional()
  @Transform(({ value }) => value === true || value === 'true' || value === '1')
  @IsBoolean()
  includeArchived?: boolean = false;
}
