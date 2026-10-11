import {
  Entity,
  PrimaryColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
} from 'typeorm';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export enum AnimalSex {
  FEMALE = 'FEMALE',
  MALE = 'MALE',
}

export enum AnimalStatus {
  LACTATING = 'LACTATING',
  DRY = 'DRY',
  PREGNANT = 'PREGNANT',
  HEIFER = 'HEIFER',
  CALF = 'CALF',
  BULL = 'BULL',
  SOLD = 'SOLD',
  DECEASED = 'DECEASED',
}

@Entity('animals')
export class AnimalEntity {
  @ApiProperty({ description: 'Unique animal UUID identifier' })
  @PrimaryColumn({ type: 'varchar', length: 36 })
  id: string;

  @ApiProperty({ description: 'Ear Tag / Microchip number (strictly unique)' })
  @Column({ name: 'ear_tag', type: 'varchar', length: 50, unique: true })
  earTag: string;

  @ApiPropertyOptional({ description: 'Animal display name or nickname' })
  @Column({ type: 'varchar', length: 100, nullable: true })
  name: string | null;

  @ApiProperty({ description: 'Animal breed (e.g. GIR, SAHIWAL, HOLSTEIN_FRIESIAN, JERSEY, MURRAH)' })
  @Column({ type: 'varchar', length: 50 })
  breed: string;

  @ApiProperty({ enum: AnimalSex, default: AnimalSex.FEMALE })
  @Column({ type: 'enum', enum: AnimalSex, default: AnimalSex.FEMALE })
  sex: AnimalSex;

  @ApiPropertyOptional({ description: 'Date of birth (ISO YYYY-MM-DD)' })
  @Column({ name: 'date_of_birth', type: 'date', nullable: true })
  dateOfBirth: string | null;

  @ApiProperty({ enum: AnimalStatus, default: AnimalStatus.LACTATING })
  @Column({ type: 'enum', enum: AnimalStatus, default: AnimalStatus.LACTATING })
  status: AnimalStatus;

  @ApiPropertyOptional({ description: 'Body weight in kilograms' })
  @Column({
    name: 'body_weight_kg',
    type: 'decimal',
    precision: 6,
    scale: 2,
    nullable: true,
    transformer: {
      to: (value?: number | null) => value,
      from: (value?: string | null) => (value !== null && value !== undefined ? parseFloat(value) : null),
    },
  })
  bodyWeightKg: number | null;

  @ApiPropertyOptional({ description: 'Dam (mother) ear tag reference' })
  @Column({ name: 'dam_tag', type: 'varchar', length: 50, nullable: true })
  damTag: string | null;

  @ApiPropertyOptional({ description: 'Most recent calving date' })
  @Column({ name: 'last_calving_date', type: 'date', nullable: true })
  lastCalvingDate: string | null;

  @ApiPropertyOptional({ description: 'Body condition score (1.0 - 5.0 scale)' })
  @Column({
    name: 'body_condition_score',
    type: 'decimal',
    precision: 3,
    scale: 1,
    nullable: true,
    transformer: {
      to: (value?: number | null) => value,
      from: (value?: string | null) => (value !== null && value !== undefined ? parseFloat(value) : null),
    },
  })
  bodyConditionScore: number | null;

  @ApiPropertyOptional({ description: 'General notes, lineage, or markings' })
  @Column({ type: 'text', nullable: true })
  notes: string | null;

  @ApiProperty({ description: 'Archive status flag' })
  @Column({ name: 'is_archived', type: 'boolean', default: false })
  isArchived: boolean;

  @ApiPropertyOptional({ description: 'Date and time animal was archived' })
  @Column({ name: 'archived_at', type: 'datetime', nullable: true })
  archivedAt: Date | null;

  @ApiPropertyOptional({ description: 'Reason for archiving (e.g. Sold, Culled, Deceased)' })
  @Column({ name: 'archive_reason', type: 'varchar', length: 255, nullable: true })
  archiveReason: string | null;

  @ApiProperty({ description: 'System creation timestamp' })
  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @ApiProperty({ description: 'System update timestamp' })
  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
