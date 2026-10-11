import {
  Entity,
  PrimaryColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { AnimalEntity } from '../../herd/entities/animal.entity';

export enum BreedingEventType {
  HEAT = 'HEAT',
  INSEMINATION = 'INSEMINATION',
  PREGNANCY_CONFIRMED = 'PREGNANCY_CONFIRMED',
  PREGNANCY_CHECK = 'PREGNANCY_CHECK',
  CALVING = 'CALVING',
  DRY_OFF = 'DRY_OFF',
}

@Entity('breeding_records')
export class BreedingRecordEntity {
  @ApiProperty({ description: 'Unique breeding record UUID identifier' })
  @PrimaryColumn({ type: 'varchar', length: 36 })
  id: string;

  @ApiProperty({ description: 'Referenced animal UUID identifier' })
  @Column({ name: 'animal_id', type: 'varchar', length: 36 })
  animalId: string;

  @ManyToOne(() => AnimalEntity, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'animal_id' })
  animal: AnimalEntity;

  @ApiProperty({ description: 'Date breeding event occurred (ISO YYYY-MM-DD)' })
  @Column({ name: 'record_date', type: 'date' })
  recordDate: string;

  @ApiProperty({ enum: BreedingEventType, description: 'Breeding event category' })
  @Column({ name: 'event_type', type: 'enum', enum: BreedingEventType })
  eventType: BreedingEventType;

  @ApiPropertyOptional({ description: 'Sire identifier or Semen Straw Batch number' })
  @Column({ name: 'sire_semen_id', type: 'varchar', length: 100, nullable: true })
  sireSemenId: string | null;

  @ApiPropertyOptional({ description: 'Expected calving date (~280 days after insemination)' })
  @Column({ name: 'expected_calving_date', type: 'date', nullable: true })
  expectedCalvingDate: string | null;

  @ApiPropertyOptional({ description: 'Next scheduled check date (e.g. 45-day pregnancy check, 21-day heat check)' })
  @Column({ name: 'next_check_date', type: 'date', nullable: true })
  nextCheckDate: string | null;

  @ApiPropertyOptional({ description: 'Newborn calf ear tag (for CALVING event)' })
  @Column({ name: 'calf_tag', type: 'varchar', length: 50, nullable: true })
  calfTag: string | null;

  @ApiPropertyOptional({ description: 'Artificial insemination details, technician, or birth notes' })
  @Column({ type: 'text', nullable: true })
  notes: string | null;

  @ApiPropertyOptional({ description: 'User ID of staff recording the entry' })
  @Column({ name: 'created_by', type: 'varchar', length: 36, nullable: true })
  createdBy: string | null;

  @ApiProperty({ description: 'System creation timestamp' })
  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @ApiProperty({ description: 'System update timestamp' })
  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
