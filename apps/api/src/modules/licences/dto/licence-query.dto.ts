import { IsOptional, IsEnum, IsInt, Min, IsString } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  LicenceType,
  LicenceStatus,
  ReminderStatus,
} from '@dairy-farm/api-contracts';

export class LicenceQueryDto {
  @ApiPropertyOptional({ default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @ApiPropertyOptional({ default: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  limit?: number = 20;

  @ApiPropertyOptional({ enum: LicenceType })
  @IsOptional()
  @IsEnum(LicenceType)
  licenceType?: LicenceType;

  @ApiPropertyOptional({ enum: LicenceStatus })
  @IsOptional()
  @IsEnum(LicenceStatus)
  status?: LicenceStatus;

  @ApiPropertyOptional({ enum: ReminderStatus })
  @IsOptional()
  @IsEnum(ReminderStatus)
  reminderStatus?: ReminderStatus;

  @ApiPropertyOptional({ description: 'Search by licence name, number, issuing authority, or holder' })
  @IsOptional()
  @IsString()
  search?: string;
}
