import {
  Entity,
  PrimaryColumn,
  Column,
  CreateDateColumn,
  OneToMany,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { OrderStatus } from '@dairy-farm/api-contracts';
import { CustomerEntity } from './customer.entity';
import { SalesOrderItemEntity } from './sales-order-item.entity';

@Entity({ name: 'sales_orders' })
export class SalesOrderEntity {
  @PrimaryColumn({ type: 'varchar', length: 36 })
  id: string;

  @Column({ name: 'order_number', type: 'varchar', length: 50, unique: true })
  orderNumber: string;

  @Column({ name: 'customer_id', type: 'varchar', length: 36 })
  customerId: string;

  @ManyToOne(() => CustomerEntity)
  @JoinColumn({ name: 'customer_id' })
  customer: CustomerEntity;

  @Column({ name: 'order_date', type: 'date' })
  orderDate: string;

  @Column({ name: 'delivery_date', type: 'date' })
  deliveryDate: string;

  @Column({
    type: 'enum',
    enum: OrderStatus,
    default: OrderStatus.PENDING,
  })
  status: OrderStatus;

  @Column({
    name: 'total_amount',
    type: 'decimal',
    precision: 10,
    scale: 2,
    default: 0.00,
    transformer: {
      to: (v: number) => v,
      from: (v: string) => parseFloat(v),
    },
  })
  totalAmount: number;

  @Column({ type: 'text', nullable: true })
  notes: string | null;

  @Column({ name: 'created_by', type: 'varchar', length: 36, nullable: true })
  createdBy: string | null;

  @CreateDateColumn({ name: 'created_at', type: 'datetime' })
  createdAt: Date;

  @OneToMany(() => SalesOrderItemEntity, (item) => item.order, { cascade: true })
  items: SalesOrderItemEntity[];
}
