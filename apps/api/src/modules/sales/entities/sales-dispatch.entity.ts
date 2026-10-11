import {
  Entity,
  PrimaryColumn,
  Column,
  CreateDateColumn,
  OneToMany,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { ProductType, PaymentMethod } from '@dairy-farm/api-contracts';
import { CustomerEntity } from './customer.entity';
import { SalesDispatchItemEntity } from './sales-dispatch-item.entity';

@Entity({ name: 'sales_dispatches' })
export class SalesDispatchEntity {
  @PrimaryColumn({ type: 'varchar', length: 36 })
  id: string;

  @Column({ name: 'dispatch_number', type: 'varchar', length: 50, unique: true })
  dispatchNumber: string;

  @Column({ name: 'order_id', type: 'varchar', length: 36, nullable: true })
  orderId: string | null;

  @Column({ name: 'customer_id', type: 'varchar', length: 36 })
  customerId: string;

  @ManyToOne(() => CustomerEntity)
  @JoinColumn({ name: 'customer_id' })
  customer: CustomerEntity;

  @Column({ name: 'record_date', type: 'date' })
  recordDate: string;

  @Column({ name: 'packaging_run_id', type: 'varchar', length: 36, nullable: true })
  packagingRunId: string | null;

  @Column({
    name: 'product_type',
    type: 'enum',
    enum: ProductType,
  })
  productType: ProductType;

  @Column({ name: 'packs_sold', type: 'int' })
  packsSold: number;

  @Column({
    name: 'price_per_pack',
    type: 'decimal',
    precision: 8,
    scale: 2,
    transformer: {
      to: (v: number) => v,
      from: (v: string) => parseFloat(v),
    },
  })
  pricePerPack: number;

  @Column({
    name: 'total_amount',
    type: 'decimal',
    precision: 10,
    scale: 2,
    transformer: {
      to: (v: number) => v,
      from: (v: string) => parseFloat(v),
    },
  })
  totalAmount: number;

  @Column({
    name: 'amount_received',
    type: 'decimal',
    precision: 10,
    scale: 2,
    default: 0.00,
    transformer: {
      to: (v: number) => v,
      from: (v: string) => parseFloat(v),
    },
  })
  amountReceived: number;

  @Column({
    name: 'balance_due',
    type: 'decimal',
    precision: 10,
    scale: 2,
    default: 0.00,
    transformer: {
      to: (v: number) => v,
      from: (v: string) => parseFloat(v),
    },
  })
  balanceDue: number;

  @Column({
    name: 'payment_method',
    type: 'enum',
    enum: PaymentMethod,
    default: PaymentMethod.CASH,
  })
  paymentMethod: PaymentMethod;

  @Column({ type: 'text', nullable: true })
  notes: string | null;

  @Column({ name: 'created_by', type: 'varchar', length: 36, nullable: true })
  createdBy: string | null;

  @CreateDateColumn({ name: 'created_at', type: 'datetime' })
  createdAt: Date;

  @OneToMany(() => SalesDispatchItemEntity, (item) => item.dispatch, { cascade: true })
  items: SalesDispatchItemEntity[];
}
