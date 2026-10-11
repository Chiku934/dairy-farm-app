import { IsString, IsNotEmpty, IsOptional, IsEnum, MaxLength } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { AnimalStatus } from '../entities/animal.entity';

export class ArchiveAnimalDto {
  @ApiPropertyOptional({
    enum: [AnimalStatus.SOLD, AnimalStatus.DECEASED],
    description: 'Updated lifecycle status upon archiving (defaults to SOLD if omitted)',
    default: AnimalStatus.SOLD,
  })
  @IsOptional()
  @IsEnum(AnimalStatus)
  status?: AnimalStatus;

  @ApiProperty({
    description: 'Reason for archiving / retiring the animal (e.g. Sold to local dairy, Culled due to age, Died from illness)',
    example: 'Sold to neighbouring dairy farm at market rate',
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  archiveReason: string;
}
