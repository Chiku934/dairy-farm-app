import { Entity, PrimaryColumn, Column, CreateDateColumn } from 'typeorm';

@Entity({ name: 'stock_receipts' })
export class StockReceiptEntity {
  @PrimaryColumn({ type: 'varchar', length: 36 })
  id: string;

  @Column({ name: 'receipt_number', type: 'varchar', length: 50, unique: true })
  receiptNumber: string;

  @Column({ name: 'record_date', type: 'date' })
  recordDate: string;

  @Column({ name: 'stock_item_id', type: 'varchar', length: 36 })
  stockItemId: string;

  @Column({ name: 'supplier_id', type: 'varchar', length: 36, nullable: true })
  supplierId: string | null;

  @Column({ name: 'supplier_name', type: 'varchar', length: 120, nullable: true })
  supplierName: string | null;

  @Column({ name: 'supplier_lot', type: 'varchar', length: 80, nullable: true })
  supplierLot: string | null;

  @Column({
    type: 'decimal',
    precision: 10,
    scale: 2,
    transformer: {
      to: (v: number) => v,
      from: (v: string) => parseFloat(v),
    },
  })
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
    name: 'total_cost',
    type: 'decimal',
    precision: 10,
    scale: 2,
    transformer: {
      to: (v: number) => v,
      from: (v: string) => parseFloat(v),
    },
  })
  totalCost: number;

  @Column({ name: 'expiry_date', type: 'date', nullable: true })
  expiryDate: string | null;

  @Column({ type: 'text', nullable: true })
  notes: string | null;

  @Column({ name: 'created_by', type: 'varchar', length: 36, nullable: true })
  createdBy: string | null;

  @CreateDateColumn({ name: 'created_at', type: 'datetime' })
  createdAt: Date;
}
