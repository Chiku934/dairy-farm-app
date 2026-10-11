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
import { StockItemEntity } from './stock-item.entity';
import { RationDefinitionEntity } from './ration-definition.entity';

export enum FeedType {
  CONCENTRATE = 'CONCENTRATE',
  GREEN_FODDER = 'GREEN_FODDER',
  DRY_FODDER = 'DRY_FODDER',
  MINERAL_MIXTURE = 'MINERAL_MIXTURE',
  SALT = 'SALT',
  MAIZE = 'MAIZE',
  CALF_STARTER = 'CALF_STARTER',
}

export enum FeedShift {
  MORNING = 'MORNING',
  EVENING = 'EVENING',
  ALL_DAY = 'ALL_DAY',
}

@Entity({ name: 'feed_entries' })
@Index(['record_date'])
@Index(['animal_id'])
@Index(['stock_item_id'])
export class FeedEntryEntity {
  @PrimaryColumn({ type: 'varchar', length: 36 })
  id: string;

  @Column({ name: 'animal_id', type: 'varchar', length: 36, nullable: true })
  animal_id: string | null;

  @ManyToOne(() => AnimalEntity, { onDelete: 'RESTRICT', nullable: true })
  @JoinColumn({ name: 'animal_id' })
  animal?: AnimalEntity | null;

  @Column({ name: 'group_name', type: 'varchar', length: 100, nullable: true })
  group_name: string | null;

  @Column({ name: 'ration_id', type: 'varchar', length: 36, nullable: true })
  ration_id: string | null;

  @ManyToOne(() => RationDefinitionEntity, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'ration_id' })
  ration?: RationDefinitionEntity | null;

  @Column({ name: 'record_date', type: 'date' })
  record_date: string;

  @Column({ name: 'stock_item_id', type: 'varchar', length: 36 })
  stock_item_id: string;

  @ManyToOne(() => StockItemEntity, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'stock_item_id' })
  stock_item?: StockItemEntity;

  @Column({
    name: 'quantity_kg',
    type: 'decimal',
    precision: 8,
    scale: 2,
    transformer: {
      to: (value: number) => value,
      from: (value: string) => parseFloat(value),
    },
  })
  quantity_kg: number;

  @Column({
    name: 'unit_cost',
    type: 'decimal',
    precision: 10,
    scale: 2,
    transformer: {
      to: (value: number) => value,
      from: (value: string) => parseFloat(value),
    },
  })
  unit_cost: number;

  @Column({
    name: 'total_cost',
    type: 'decimal',
    precision: 10,
    scale: 2,
    transformer: {
      to: (value: number) => value,
      from: (value: string) => parseFloat(value),
    },
  })
  total_cost: number;

  @Column({
    type: 'enum',
    enum: FeedShift,
    default: FeedShift.ALL_DAY,
  })
  shift: FeedShift;

  @Column({
    name: 'feed_type',
    type: 'enum',
    enum: FeedType,
  })
  feed_type: FeedType;

  @Column({ type: 'text', nullable: true })
  notes: string | null;

  @Column({ name: 'created_by', type: 'varchar', length: 36, nullable: true })
  created_by: string | null;

  @CreateDateColumn({ name: 'created_at' })
  created_at: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updated_at: Date;
}
