import { Entity, PrimaryColumn, Column } from 'typeorm';

export enum StockUsedBy {
  FARM = 'FARM',
  PRODUCTION = 'PRODUCTION',
  BIOGAS = 'BIOGAS',
  BOTH = 'BOTH',
}

export enum StockCategory {
  FEED = 'FEED',
  MEDICINE = 'MEDICINE',
  PACKAGING = 'PACKAGING',
  LPG = 'LPG',
  CLEANING = 'CLEANING',
  PROCESSING_INGREDIENT = 'PROCESSING_INGREDIENT',
  CONSUMABLE = 'CONSUMABLE',
  SPARE_PART = 'SPARE_PART',
  OTHER = 'OTHER',
}

@Entity({ name: 'stock_items' })
export class StockItemEntity {
  @PrimaryColumn({ type: 'varchar', length: 36 })
  id: string;

  @Column({ type: 'varchar', length: 120, unique: true })
  name: string;

  @Column({
    type: 'enum',
    enum: StockUsedBy,
  })
  used_by: StockUsedBy;

  @Column({
    type: 'enum',
    enum: StockCategory,
  })
  category: StockCategory;

  @Column({ type: 'varchar', length: 20 })
  unit: string;

  @Column({
    name: 'current_stock',
    type: 'decimal',
    precision: 10,
    scale: 2,
    transformer: {
      to: (value: number) => value,
      from: (value: string) => parseFloat(value),
    },
  })
  current_stock: number;

  @Column({
    name: 'weighted_avg_price',
    type: 'decimal',
    precision: 10,
    scale: 2,
    transformer: {
      to: (value: number) => value,
      from: (value: string) => parseFloat(value),
    },
  })
  weighted_avg_price: number;

  @Column({
    name: 'reorder_level',
    type: 'decimal',
    precision: 10,
    scale: 2,
    transformer: {
      to: (value: number) => value,
      from: (value: string) => parseFloat(value),
    },
  })
  reorder_level: number;

  @Column({ type: 'text', nullable: true })
  notes: string | null;
}
