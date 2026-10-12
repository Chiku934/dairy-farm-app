import { Entity, PrimaryColumn, Column, CreateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { CostCentre, ExpenseCategory, PaymentMethod } from '@dairy-farm/api-contracts';
import { ProductionBatchEntity } from '../../production/entities/production-batch.entity';

@Entity({ name: 'operating_expenses' })
export class OperatingExpenseEntity {
  @PrimaryColumn({ type: 'varchar', length: 36 })
  id: string;

  @Column({ name: 'expense_number', type: 'varchar', length: 50, unique: true, nullable: true })
  expense_number: string;

  @Column({ name: 'record_date', type: 'date' })
  record_date: string;

  @Column({
    name: 'cost_centre',
    type: 'enum',
    enum: CostCentre,
  })
  cost_centre: CostCentre;

  @Column({
    type: 'enum',
    enum: ExpenseCategory,
  })
  category: ExpenseCategory;

  @Column({
    name: 'amount',
    type: 'decimal',
    precision: 10,
    scale: 2,
    transformer: {
      to: (val: number) => val,
      from: (val: string) => parseFloat(val),
    },
  })
  amount: number;

  @Column({ name: 'production_batch_id', type: 'varchar', length: 36, nullable: true })
  production_batch_id: string | null;

  @ManyToOne(() => ProductionBatchEntity, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'production_batch_id' })
  production_batch?: ProductionBatchEntity;

  @Column({ type: 'varchar', length: 120, nullable: true })
  payee: string | null;

  @Column({ name: 'invoice_number', type: 'varchar', length: 80, nullable: true })
  invoice_number: string | null;

  @Column({
    name: 'payment_method',
    type: 'enum',
    enum: PaymentMethod,
    default: PaymentMethod.CASH,
  })
  payment_method: PaymentMethod;

  @Column({ type: 'text', nullable: true })
  notes: string | null;

  @Column({ name: 'created_by', type: 'varchar', length: 36, nullable: true })
  created_by: string | null;

  @CreateDateColumn({ name: 'created_at' })
  created_at: Date;
}
