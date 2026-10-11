import { Entity, PrimaryColumn, Column, ManyToOne, JoinColumn } from 'typeorm';
import { ProductType } from '@dairy-farm/api-contracts';
import { SalesOrderEntity } from './sales-order.entity';

@Entity({ name: 'sales_order_items' })
export class SalesOrderItemEntity {
  @PrimaryColumn({ type: 'varchar', length: 36 })
  id: string;

  @Column({ name: 'order_id', type: 'varchar', length: 36 })
  orderId: string;

  @ManyToOne(() => SalesOrderEntity, (order) => order.items, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'order_id' })
  order: SalesOrderEntity;

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

  @Column({ name: 'quantity_ordered', type: 'int' })
  quantityOrdered: number;

  @Column({ name: 'quantity_dispatched', type: 'int', default: 0 })
  quantityDispatched: number;

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
