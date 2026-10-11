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

export enum CareType {
  TREATMENT = 'TREATMENT',
  VACCINATION = 'VACCINATION',
  DEWORMING = 'DEWORMING',
  EXAMINATION = 'EXAMINATION',
}

@Entity('health_records')
export class HealthRecordEntity {
  @ApiProperty({ description: 'Unique health record UUID identifier' })
  @PrimaryColumn({ type: 'varchar', length: 36 })
  id: string;

  @ApiProperty({ description: 'Referenced animal UUID identifier' })
  @Column({ name: 'animal_id', type: 'varchar', length: 36 })
  animalId: string;

  @ManyToOne(() => AnimalEntity, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'animal_id' })
  animal: AnimalEntity;

  @ApiProperty({ description: 'Date event took place (ISO YYYY-MM-DD)' })
  @Column({ name: 'record_date', type: 'date' })
  recordDate: string;

  @ApiProperty({ enum: CareType, description: 'Type of veterinary care administered' })
  @Column({ name: 'care_type', type: 'enum', enum: CareType })
  careType: CareType;

  @ApiPropertyOptional({
    description: 'Veterinary diagnosis distinct from treatment (e.g. Mastitis, Ketosis, Tick Infestation, Routine Check)',
  })
  @Column({ type: 'varchar', length: 150, nullable: true })
  diagnosis: string | null;

  @ApiProperty({ description: 'Medicine or vaccine brand/compound administered' })
  @Column({ name: 'medicine_vaccine', type: 'varchar', length: 120 })
  medicineVaccine: string;

  @ApiProperty({ description: 'Prescribed dosage, route and frequency (e.g. 10ml IM, 1 bolus orally)' })
  @Column({ name: 'prescribed_dose', type: 'varchar', length: 100 })
  prescribedDose: string;

  @ApiPropertyOptional({ description: 'Attending veterinarian or specialist name' })
  @Column({ type: 'varchar', length: 100, nullable: true })
  veterinarian: string | null;

  @ApiPropertyOptional({ description: 'Next scheduled due date for booster/check (ISO YYYY-MM-DD)' })
  @Column({ name: 'next_due_date', type: 'date', nullable: true })
  nextDueDate: string | null;

  @ApiPropertyOptional({ description: 'Milk withdrawal expiration date (ISO YYYY-MM-DD)' })
  @Column({ name: 'withdrawal_until', type: 'date', nullable: true })
  withdrawalUntil: string | null;

  @ApiPropertyOptional({ description: 'Clinical observations, treatment instructions or recovery notes' })
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
