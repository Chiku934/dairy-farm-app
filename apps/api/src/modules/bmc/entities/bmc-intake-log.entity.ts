import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  OneToMany,
} from 'typeorm';
import { ProductionBatchIntake } from '../../production/entities/production-batch-intake.entity';

export enum MilkIntakeSource {
  FARM = 'FARM',
  EXTERNAL = 'EXTERNAL',
}

export enum IntakeShift {
  AM = 'AM',
  PM = 'PM',
}

export enum Decision {
  ACCEPTED = 'ACCEPTED',
  REJECTED = 'REJECTED',
}

@Entity('bmc_intake_logs')
export class BmcIntakeLog {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'batch_number', length: 50, unique: true })
  batchNumber: string;

  @Column({ name: 'record_date', type: 'date' })
  recordDate: string;

  @Column({
    type: 'enum',
    enum: IntakeShift,
    default: IntakeShift.AM,
  })
  shift: IntakeShift;

  @Column({
    type: 'enum',
    enum: MilkIntakeSource,
  })
  source: MilkIntakeSource;

  @Column({ name: 'supplier_route', length: 120, nullable: true })
  supplierRoute?: string;

  @Column({
    name: 'quantity_litres',
    type: 'decimal',
    precision: 8,
    scale: 2,
    transformer: {
      to: (v: number) => v,
      from: (v: string) => parseFloat(v),
    },
  })
  quantityLitres: number;

  @Column({
    name: 'external_total_cost',
    type: 'decimal',
    precision: 10,
    scale: 2,
    default: 0,
    transformer: {
      to: (v: number) => v,
      from: (v: string) => parseFloat(v),
    },
  })
  externalTotalCost: number;

  @Column({
    type: 'enum',
    enum: Decision,
  })
  decision: Decision;

  @Column({ name: 'rejection_reason', length: 255, nullable: true })
  rejectionReason?: string;

  @Column({
    name: 'temperature_c',
    type: 'decimal',
    precision: 4,
    scale: 1,
    nullable: true,
    transformer: {
      to: (v: number | null) => v,
      from: (v: string | null) => (v ? parseFloat(v) : null),
    },
  })
  temperatureC?: number;

  @Column({
    name: 'fat_percentage',
    type: 'decimal',
    precision: 4,
    scale: 2,
    nullable: true,
    transformer: {
      to: (v: number | null) => v,
      from: (v: string | null) => (v ? parseFloat(v) : null),
    },
  })
  fatPercentage?: number;

  @Column({
    name: 'snf_percentage',
    type: 'decimal',
    precision: 4,
    scale: 2,
    nullable: true,
    transformer: {
      to: (v: number | null) => v,
      from: (v: string | null) => (v ? parseFloat(v) : null),
    },
  })
  snfPercentage?: number;

  @Column({
    name: 'clr',
    type: 'decimal',
    precision: 5,
    scale: 2,
    nullable: true,
    transformer: {
      to: (v: number | null) => v,
      from: (v: string | null) => (v ? parseFloat(v) : null),
    },
  })
  clr?: number;

  @Column({
    name: 'ph',
    type: 'decimal',
    precision: 3,
    scale: 2,
    nullable: true,
    transformer: {
      to: (v: number | null) => v,
      from: (v: string | null) => (v ? parseFloat(v) : null),
    },
  })
  ph?: number;

  @Column({ type: 'text', nullable: true })
  notes?: string;

  @Column({ name: 'operator_id', length: 36, nullable: true })
  operatorId?: string;

  @Column({ name: 'operator_name', length: 100, nullable: true })
  operatorName?: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @OneToMany(() => ProductionBatchIntake, (pbi) => pbi.intake)
  batchLinks?: ProductionBatchIntake[];
}
