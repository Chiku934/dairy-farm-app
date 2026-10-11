import { Entity, PrimaryColumn, Column, CreateDateColumn } from 'typeorm';
import { StockTransactionType } from '@dairy-farm/api-contracts';

@Entity({ name: 'stock_ledger_entries' })
export class StockLedgerEntryEntity {
  @PrimaryColumn({ type: 'varchar', length: 36 })
  id: string;

  @Column({ name: 'stock_item_id', type: 'varchar', length: 36 })
  stockItemId: string;

  @Column({ name: 'record_date', type: 'date' })
  recordDate: string;

  @Column({
    name: 'transaction_type',
    type: 'enum',
    enum: StockTransactionType,
  })
  transactionType: StockTransactionType;

  @Column({ name: 'reference_id', type: 'varchar', length: 50, nullable: true })
  referenceId: string | null;

  @Column({
    name: 'quantity_change',
    type: 'decimal',
    precision: 10,
    scale: 2,
    transformer: {
      to: (v: number) => v,
      from: (v: string) => parseFloat(v),
    },
  })
  quantityChange: number;

  @Column({
    name: 'balance_after',
    type: 'decimal',
    precision: 10,
    scale: 2,
    transformer: {
      to: (v: number) => v,
      from: (v: string) => parseFloat(v),
    },
  })
  balanceAfter: number;

  @Column({
    name: 'unit_cost',
    type: 'decimal',
    precision: 10,
    scale: 2,
    transformer: {
      to: (v: number) => v,
      from: (v: string) => parseFloat(v),
    },
  })
  unitCost: number;

  @Column({ type: 'text', nullable: true })
  notes: string | null;

  @CreateDateColumn({ name: 'created_at', type: 'datetime' })
  createdAt: Date;
}
