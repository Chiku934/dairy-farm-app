import {
  Entity,
  PrimaryColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { PaymentMethod } from '@dairy-farm/api-contracts';
import { CustomerEntity } from './customer.entity';

@Entity({ name: 'customer_payments' })
export class CustomerPaymentEntity {
  @PrimaryColumn({ type: 'varchar', length: 36 })
  id: string;

  @Column({ name: 'payment_number', type: 'varchar', length: 50, unique: true })
  paymentNumber: string;

  @Column({ name: 'customer_id', type: 'varchar', length: 36 })
  customerId: string;

  @ManyToOne(() => CustomerEntity)
  @JoinColumn({ name: 'customer_id' })
  customer: CustomerEntity;

  @Column({ name: 'dispatch_id', type: 'varchar', length: 36, nullable: true })
  dispatchId: string | null;

  @Column({ name: 'record_date', type: 'date' })
  recordDate: string;

  @Column({
    name: 'amount_received',
    type: 'decimal',
    precision: 10,
    scale: 2,
    transformer: {
      to: (v: number) => v,
      from: (v: string) => parseFloat(v),
    },
  })
  amountReceived: number;

  @Column({
    name: 'payment_method',
    type: 'enum',
    enum: PaymentMethod,
    default: PaymentMethod.CASH,
  })
  paymentMethod: PaymentMethod;

  @Column({ name: 'reference_code', type: 'varchar', length: 100, nullable: true })
  referenceCode: string | null;

  @Column({ type: 'text', nullable: true })
  notes: string | null;

  @Column({ name: 'created_by', type: 'varchar', length: 36, nullable: true })
  createdBy: string | null;

  @CreateDateColumn({ name: 'created_at', type: 'datetime' })
  createdAt: Date;
}
