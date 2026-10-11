import { IsEnum, IsNotEmpty, IsOptional, IsString } from 'class-validator';
import { QualityReleaseStatus, BatchStatus } from '../entities/production-batch.entity';

export class UpdateBatchStatusDto {
  @IsOptional()
  @IsEnum(QualityReleaseStatus)
  qualityRelease?: QualityReleaseStatus;

  @IsOptional()
  @IsEnum(BatchStatus)
  status?: BatchStatus;

  @IsOptional()
  @IsString()
  notes?: string;
}
