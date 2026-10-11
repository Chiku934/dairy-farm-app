import {
  Entity,
  PrimaryColumn,
  Column,
  ManyToOne,
  JoinColumn,
  Index,
} from 'typeorm';
import { RationDefinitionEntity } from './ration-definition.entity';
import { StockItemEntity } from './stock-item.entity';

@Entity({ name: 'ration_items' })
@Index(['ration_id', 'stock_item_id'], { unique: true })
export class RationItemEntity {
  @PrimaryColumn({ type: 'varchar', length: 36 })
  id: string;

  @Column({ name: 'ration_id', type: 'varchar', length: 36 })
  ration_id: string;

  @ManyToOne(() => RationDefinitionEntity, (ration) => ration.items, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'ration_id' })
  ration?: RationDefinitionEntity;

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

  @Column({ type: 'varchar', length: 255, nullable: true })
  notes: string | null;

  // Virtual computed cost helper
  itemCost?: number;
}
