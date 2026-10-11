import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { ProductionBatch } from './production-batch.entity';
import { BmcIntakeLog } from '../../bmc/entities/bmc-intake-log.entity';

@Entity('production_batch_intakes')
export class ProductionBatchIntake {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'production_batch_id', length: 36 })
  productionBatchId: string;

  @ManyToOne(() => ProductionBatch, (pb) => pb.intakeLinks, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'production_batch_id' })
  productionBatch: ProductionBatch;

  @Column({ name: 'intake_id', length: 36 })
  intakeId: string;

  @ManyToOne(() => BmcIntakeLog, (bi) => bi.batchLinks, {
    onDelete: 'RESTRICT',
  })
  @JoinColumn({ name: 'intake_id' })
  intake: BmcIntakeLog;

  @Column({
    name: 'litres_used',
    type: 'decimal',
    precision: 8,
    scale: 2,
    transformer: {
      to: (v: number) => v,
      from: (v: string) => parseFloat(v),
    },
  })
  litresUsed: number;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
