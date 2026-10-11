import { Entity, PrimaryColumn, Column, CreateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { Department } from '@dairy-farm/api-contracts';
import { StockItemEntity } from '../../feed/entities/stock-item.entity';
import { ProductionBatchEntity } from '../../production/entities/production-batch.entity';

@Entity({ name: 'material_issues' })
export class MaterialIssueEntity {
  @PrimaryColumn({ type: 'varchar', length: 36 })
  id: string;

  @Column({ name: 'record_date', type: 'date' })
  record_date: string;

  @Column({
    type: 'enum',
    enum: Department,
  })
  department: Department;

  @Column({ name: 'stock_item_id', type: 'varchar', length: 36 })
  stock_item_id: string;

  @ManyToOne(() => StockItemEntity, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'stock_item_id' })
  stock_item?: StockItemEntity;

  @Column({
    name: 'quantity',
    type: 'decimal',
    precision: 10,
    scale: 2,
    transformer: {
      to: (val: number) => val,
      from: (val: string) => parseFloat(val),
    },
  })
  quantity: number;

  @Column({
    name: 'unit_cost',
    type: 'decimal',
    precision: 10,
    scale: 2,
    nullable: true,
    transformer: {
      to: (val: number | null) => val,
      from: (val: string | null) => (val !== null ? parseFloat(val) : null),
    },
  })
  unit_cost: number | null;

  @Column({
    name: 'total_cost',
    type: 'decimal',
    precision: 10,
    scale: 2,
    nullable: true,
    transformer: {
      to: (val: number | null) => val,
      from: (val: string | null) => (val !== null ? parseFloat(val) : null),
    },
  })
  total_cost: number | null;

  @Column({ name: 'production_batch_id', type: 'varchar', length: 36, nullable: true })
  production_batch_id: string | null;

  @ManyToOne(() => ProductionBatchEntity, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'production_batch_id' })
  production_batch?: ProductionBatchEntity;

  @Column({ name: 'issued_to', type: 'varchar', length: 100, nullable: true })
  issued_to: string | null;

  @Column({ type: 'text', nullable: true })
  notes: string | null;

  @Column({ name: 'created_by', type: 'varchar', length: 36, nullable: true })
  created_by: string | null;

  @CreateDateColumn({ name: 'created_at' })
  created_at: Date;
}
