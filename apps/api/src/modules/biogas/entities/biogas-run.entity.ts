import { Entity, PrimaryColumn, Column, CreateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { BiogasUsageType } from '@dairy-farm/api-contracts';
import { StockItemEntity } from '../../feed/entities/stock-item.entity';

@Entity({ name: 'biogas_runs' })
export class BiogasRunEntity {
  @PrimaryColumn({ type: 'varchar', length: 36 })
  id: string;

  @Column({ name: 'run_number', type: 'varchar', length: 50, unique: true, nullable: true })
  run_number: string;

  @Column({ name: 'record_date', type: 'date' })
  record_date: string;

  @Column({
    name: 'slurry_input_kg',
    type: 'decimal',
    precision: 10,
    scale: 2,
    transformer: {
      to: (val: number) => val,
      from: (val: string) => parseFloat(val),
    },
  })
  slurry_input_kg: number;

  @Column({
    name: 'dry_fertiliser_output_kg',
    type: 'decimal',
    precision: 10,
    scale: 2,
    transformer: {
      to: (val: number) => val,
      from: (val: string) => parseFloat(val),
    },
  })
  dry_fertiliser_output_kg: number;

  @Column({
    name: 'moisture_pct',
    type: 'decimal',
    precision: 5,
    scale: 2,
    nullable: true,
    transformer: {
      to: (val: number | null) => val,
      from: (val: string | null) => (val !== null ? parseFloat(val) : null),
    },
  })
  moisture_pct: number | null;

  @Column({ name: 'stock_item_id', type: 'varchar', length: 36, nullable: true })
  stock_item_id: string | null;

  @ManyToOne(() => StockItemEntity, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'stock_item_id' })
  stock_item?: StockItemEntity;

  @Column({ name: 'bags_packed_1kg', type: 'int', default: 0 })
  bags_packed_1kg: number;

  @Column({ name: 'bags_packed_5kg', type: 'int', default: 0 })
  bags_packed_5kg: number;

  @Column({ name: 'bags_packed_25kg', type: 'int', default: 0 })
  bags_packed_25kg: number;

  @Column({ name: 'bags_packed_50kg', type: 'int', default: 0 })
  bags_packed_50kg: number;

  @Column({
    name: 'usage_type',
    type: 'enum',
    enum: BiogasUsageType,
    default: BiogasUsageType.STORE_STOCK,
  })
  usage_type: BiogasUsageType;

  @Column({
    name: 'usage_quantity_kg',
    type: 'decimal',
    precision: 10,
    scale: 2,
    default: 0.0,
    transformer: {
      to: (val: number) => val,
      from: (val: string) => parseFloat(val),
    },
  })
  usage_quantity_kg: number;

  @Column({
    name: 'sale_amount',
    type: 'decimal',
    precision: 10,
    scale: 2,
    default: 0.0,
    transformer: {
      to: (val: number) => val,
      from: (val: string) => parseFloat(val),
    },
  })
  sale_amount: number;

  @Column({ name: 'buyer_or_farm_plot', type: 'varchar', length: 120, nullable: true })
  buyer_or_farm_plot: string | null;

  @Column({ type: 'text', nullable: true })
  notes: string | null;

  @Column({ name: 'created_by', type: 'varchar', length: 36, nullable: true })
  created_by: string | null;

  @CreateDateColumn({ name: 'created_at' })
  created_at: Date;
}
