import { Entity, PrimaryColumn, Column, CreateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { StockType, WastageReason } from '@dairy-farm/api-contracts';
import { StockItemEntity } from '../../feed/entities/stock-item.entity';
import { ProductionBatchEntity } from '../../production/entities/production-batch.entity';

@Entity({ name: 'wastage_records' })
export class WastageRecordEntity {
  @PrimaryColumn({ type: 'varchar', length: 36 })
  id: string;

  @Column({ name: 'wastage_number', type: 'varchar', length: 50, unique: true, nullable: true })
  wastage_number: string;

  @Column({ name: 'record_date', type: 'date' })
  record_date: string;

  @Column({
    name: 'stock_type',
    type: 'enum',
    enum: StockType,
  })
  stock_type: StockType;

  @Column({ name: 'stock_item_id', type: 'varchar', length: 36, nullable: true })
  stock_item_id: string | null;

  @ManyToOne(() => StockItemEntity, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'stock_item_id' })
  stock_item?: StockItemEntity;

  @Column({ name: 'production_batch_id', type: 'varchar', length: 36, nullable: true })
  production_batch_id: string | null;

  @ManyToOne(() => ProductionBatchEntity, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'production_batch_id' })
  production_batch?: ProductionBatchEntity;

  @Column({ name: 'reference_id', type: 'varchar', length: 50 })
  reference_id: string;

  @Column({
    name: 'quantity_lost',
    type: 'decimal',
    precision: 10,
    scale: 2,
    transformer: {
      to: (val: number) => val,
      from: (val: string) => parseFloat(val),
    },
  })
  quantity_lost: number;

  @Column({ type: 'varchar', length: 20 })
  unit: string;

  @Column({
    type: 'enum',
    enum: WastageReason,
  })
  reason: WastageReason;

  @Column({
    name: 'estimated_loss_cost',
    type: 'decimal',
    precision: 10,
    scale: 2,
    default: 0.0,
    transformer: {
      to: (val: number) => val,
      from: (val: string) => parseFloat(val),
    },
  })
  estimated_loss_cost: number;

  @Column({ type: 'text', nullable: true })
  notes: string | null;

  @Column({ name: 'created_by', type: 'varchar', length: 36, nullable: true })
  created_by: string | null;

  @CreateDateColumn({ name: 'created_at' })
  created_at: Date;
}
