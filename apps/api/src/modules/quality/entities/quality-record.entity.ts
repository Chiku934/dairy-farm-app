import { Entity, PrimaryColumn, Column, CreateDateColumn } from 'typeorm';
import { QualityTargetType, QualityDecision } from '@dairy-farm/api-contracts';

@Entity({ name: 'quality_records' })
export class QualityRecordEntity {
  @PrimaryColumn({ type: 'varchar', length: 36 })
  id: string;

  @Column({ name: 'record_date', type: 'date' })
  record_date: string;

  @Column({
    name: 'target_type',
    type: 'enum',
    enum: QualityTargetType,
  })
  target_type: QualityTargetType;

  @Column({ name: 'target_id', type: 'varchar', length: 50 })
  target_id: string;

  @Column({
    name: 'fat_percentage',
    type: 'decimal',
    precision: 4,
    scale: 2,
    nullable: true,
    transformer: {
      to: (val: number | null) => val,
      from: (val: string | null) => (val !== null ? parseFloat(val) : null),
    },
  })
  fat_percentage: number | null;

  @Column({
    name: 'snf_percentage',
    type: 'decimal',
    precision: 4,
    scale: 2,
    nullable: true,
    transformer: {
      to: (val: number | null) => val,
      from: (val: string | null) => (val !== null ? parseFloat(val) : null),
    },
  })
  snf_percentage: number | null;

  @Column({
    name: 'clr',
    type: 'decimal',
    precision: 5,
    scale: 2,
    nullable: true,
    transformer: {
      to: (val: number | null) => val,
      from: (val: string | null) => (val !== null ? parseFloat(val) : null),
    },
  })
  clr: number | null;

  @Column({
    name: 'ph',
    type: 'decimal',
    precision: 3,
    scale: 2,
    nullable: true,
    transformer: {
      to: (val: number | null) => val,
      from: (val: string | null) => (val !== null ? parseFloat(val) : null),
    },
  })
  ph: number | null;

  @Column({
    name: 'temperature_c',
    type: 'decimal',
    precision: 4,
    scale: 1,
    nullable: true,
    transformer: {
      to: (val: number | null) => val,
      from: (val: string | null) => (val !== null ? parseFloat(val) : null),
    },
  })
  temperature_c: number | null;

  @Column({
    name: 'decision',
    type: 'enum',
    enum: QualityDecision,
    default: QualityDecision.PENDING,
  })
  decision: QualityDecision;

  @Column({ name: 'tested_by', type: 'varchar', length: 100, nullable: true })
  tested_by: string | null;

  @Column({ type: 'text', nullable: true })
  notes: string | null;

  @CreateDateColumn({ name: 'created_at' })
  created_at: Date;
}
