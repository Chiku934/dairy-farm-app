import { Entity, PrimaryColumn, Column, CreateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { ProductionBatchEntity } from '../../production/entities/production-batch.entity';
import { StockItemEntity } from '../../feed/entities/stock-item.entity';

@Entity({ name: 'packaging_runs' })
export class PackagingRunEntity {
  @PrimaryColumn({ type: 'varchar', length: 36 })
  id: string;

  @Column({ name: 'record_date', type: 'date' })
  record_date: string;

  @Column({ name: 'production_batch_id', type: 'varchar', length: 36 })
  production_batch_id: string;

  @ManyToOne(() => ProductionBatchEntity, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'production_batch_id' })
  production_batch?: ProductionBatchEntity;

  @Column({
    name: 'pack_size',
    type: 'decimal',
    precision: 6,
    scale: 2,
    transformer: {
      to: (val: number) => val,
      from: (val: string) => parseFloat(val),
    },
  })
  pack_size: number;

  @Column({ name: 'pack_unit', type: 'varchar', length: 20, default: 'LITRE' })
  pack_unit: string;

  @Column({ name: 'number_of_packs', type: 'int' })
  number_of_packs: number;

  @Column({
    name: 'total_packaged_quantity',
    type: 'decimal',
    precision: 8,
    scale: 2,
    default: 0.0,
    transformer: {
      to: (val: number) => val,
      from: (val: string) => parseFloat(val),
    },
  })
  total_packaged_quantity: number;

  @Column({ name: 'packaging_item_id', type: 'varchar', length: 36 })
  packaging_item_id: string;

  @ManyToOne(() => StockItemEntity, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'packaging_item_id' })
  packaging_item?: StockItemEntity;

  @Column({
    name: 'material_consumed',
    type: 'decimal',
    precision: 8,
    scale: 2,
    transformer: {
      to: (val: number) => val,
      from: (val: string) => parseFloat(val),
    },
  })
  material_consumed: number;

  @Column({ name: 'scrap_units', type: 'int', default: 0 })
  scrap_units: number;

  @Column({ type: 'text', nullable: true })
  notes: string | null;

  @Column({ name: 'created_by', type: 'varchar', length: 36, nullable: true })
  created_by: string | null;

  @CreateDateColumn({ name: 'created_at' })
  created_at: Date;
}
