import {
  Entity,
  PrimaryColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
} from 'typeorm';
import { AnimalEntity } from '../../herd/entities/animal.entity';

export enum MilkingSession {
  MORNING = 'MORNING',
  EVENING = 'EVENING',
}

export enum MilkDisposition {
  ELIGIBLE = 'ELIGIBLE',
  WITHHELD = 'WITHHELD',
  CALF_FEEDING = 'CALF_FEEDING',
}

@Entity({ name: 'milking_logs' })
@Index(['record_date'])
@Index(['animal_id', 'record_date', 'session'], { unique: true })
export class MilkingLogEntity {
  @PrimaryColumn({ type: 'varchar', length: 36 })
  id: string;

  @Column({ name: 'animal_id', type: 'varchar', length: 36, nullable: true })
  animal_id: string | null;

  @ManyToOne(() => AnimalEntity, { onDelete: 'RESTRICT', nullable: true })
  @JoinColumn({ name: 'animal_id' })
  animal?: AnimalEntity | null;

  @Column({ name: 'group_name', type: 'varchar', length: 100, nullable: true })
  group_name: string | null;

  @Column({ name: 'record_date', type: 'date' })
  record_date: string;

  @Column({
    type: 'enum',
    enum: MilkingSession,
  })
  session: MilkingSession;

  @Column({
    name: 'yield_litres',
    type: 'decimal',
    precision: 6,
    scale: 2,
    transformer: {
      to: (value: number) => value,
      from: (value: string) => parseFloat(value),
    },
  })
  yield_litres: number;

  @Column({
    type: 'enum',
    enum: MilkDisposition,
    default: MilkDisposition.ELIGIBLE,
  })
  disposition: MilkDisposition;

  @Column({ name: 'withheld_reason', type: 'varchar', length: 255, nullable: true })
  withheld_reason: string | null;

  @Column({ name: 'operator_id', type: 'varchar', length: 36, nullable: true })
  operator_id: string | null;

  @Column({ name: 'operator_name', type: 'varchar', length: 100, nullable: true })
  operator_name: string | null;

  @Column({ type: 'text', nullable: true })
  notes: string | null;

  @CreateDateColumn({ name: 'created_at' })
  created_at: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updated_at: Date;
}
