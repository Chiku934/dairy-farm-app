import { Entity, PrimaryColumn, Column, ManyToOne, JoinColumn } from 'typeorm';
import { ProductType } from '@dairy-farm/api-contracts';
import { SalesDispatchEntity } from './sales-dispatch.entity';

@Entity({ name: 'sales_dispatch_items' })
export class SalesDispatchItemEntity {
  @PrimaryColumn({ type: 'varchar', length: 36 })
  id: string;

  @Column({ name: 'dispatch_id', type: 'varchar', length: 36 })
  dispatchId: string;

  @ManyToOne(() => SalesDispatchEntity, (d) => d.items, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'dispatch_id' })
  dispatch: SalesDispatchEntity;

  @Column({ name: 'order_item_id', type: 'varchar', length: 36, nullable: true })
  orderItemId: string | null;

  @Column({ name: 'packaging_run_id', type: 'varchar', length: 36, nullable: true })
  packagingRunId: string | null;

  @Column({
    name: 'product_type',
    type: 'enum',
    enum: ProductType,
  })
  productType: ProductType;

  @Column({
    name: 'pack_size',
    type: 'decimal',
    precision: 6,
    scale: 2,
    default: 1.00,
    transformer: {
      to: (v: number) => v,
      from: (v: string) => parseFloat(v),
    },
  })
  packSize: number;

  @Column({ name: 'pack_unit', type: 'varchar', length: 20, default: 'LITRE' })
  packUnit: string;

  @Column({ type: 'int' })
  quantity: number;

  @Column({
    name: 'unit_price',
    type: 'decimal',
    precision: 10,
    scale: 2,
    transformer: {
      to: (v: number) => v,
      from: (v: string) => parseFloat(v),
    },
  })
  unitPrice: number;

  @Column({
    name: 'total_price',
    type: 'decimal',
    precision: 10,
    scale: 2,
    transformer: {
      to: (v: number) => v,
      from: (v: string) => parseFloat(v),
    },
  })
  totalPrice: number;
}
