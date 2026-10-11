import { Entity, PrimaryColumn, Column, CreateDateColumn } from 'typeorm';
import { CustomerType } from '@dairy-farm/api-contracts';

@Entity({ name: 'customers' })
export class CustomerEntity {
  @PrimaryColumn({ type: 'varchar', length: 36 })
  id: string;

  @Column({ type: 'varchar', length: 120 })
  name: string;

  @Column({ type: 'varchar', length: 20, nullable: true })
  phone: string | null;

  @Column({ type: 'varchar', length: 120, nullable: true })
  email: string | null;

  @Column({ type: 'varchar', length: 255, nullable: true })
  address: string | null;

  @Column({
    name: 'customer_type',
    type: 'enum',
    enum: CustomerType,
    default: CustomerType.RETAIL,
  })
  customerType: CustomerType;

  @Column({
    name: 'credit_limit',
    type: 'decimal',
    precision: 10,
    scale: 2,
    default: 0.00,
    transformer: {
      to: (v: number) => v,
      from: (v: string) => parseFloat(v),
    },
  })
  creditLimit: number;

  @Column({
    name: 'current_balance',
    type: 'decimal',
    precision: 10,
    scale: 2,
    default: 0.00,
    transformer: {
      to: (v: number) => v,
      from: (v: string) => parseFloat(v),
    },
  })
  currentBalance: number;

  @Column({ name: 'is_active', type: 'boolean', default: true })
  isActive: boolean;

  @CreateDateColumn({ name: 'created_at', type: 'datetime' })
  createdAt: Date;
}
