import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  OneToMany,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { ProductionBatchIntake } from './production-batch-intake.entity';
import { StockItemEntity } from '../../feed/entities/stock-item.entity';

export enum ProductType {
  MILK = 'MILK',
  PANEER = 'PANEER',
  KHOYA = 'KHOYA',
  GHEE = 'GHEE',
  DAHI = 'DAHI',
  BUTTER = 'BUTTER',
  BIOGAS_FERTILISER = 'BIOGAS_FERTILISER',
}

export enum UnitOfMeasure {
  LITRE = 'LITRE',
  KG = 'KG',
}

export enum QualityReleaseStatus {
  HOLD = 'HOLD',
  APPROVED = 'APPROVED',
  REJECTED = 'REJECTED',
}

export enum BatchStatus {
  PLANNED = 'PLANNED',
  IN_PROGRESS = 'IN_PROGRESS',
  COMPLETED = 'COMPLETED',
  CANCELLED = 'CANCELLED',
}

export enum IntakeShift {
  AM = 'AM',
  PM = 'PM',
}

@Entity('production_batches')
export class ProductionBatch {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'batch_number', length: 50, unique: true })
  batchNumber: string;

  @Column({ name: 'record_date', type: 'date' })
  recordDate: string;

  @Column({
    type: 'enum',
    enum: IntakeShift,
    default: IntakeShift.AM,
  })
  shift: IntakeShift;

  @Column({
    name: 'product_type',
    type: 'enum',
    enum: ProductType,
  })
  productType: ProductType;

  @Column({
    type: 'enum',
    enum: BatchStatus,
    default: BatchStatus.COMPLETED,
  })
  status: BatchStatus;

  @Column({
    name: 'bmc_milk_consumed_l',
    type: 'decimal',
    precision: 8,
    scale: 2,
    transformer: {
      to: (v: number) => v,
      from: (v: string) => parseFloat(v),
    },
  })
  bmcMilkConsumedL: number;

  @Column({
    name: 'finished_quantity',
    type: 'decimal',
    precision: 8,
    scale: 2,
    transformer: {
      to: (v: number) => v,
      from: (v: string) => parseFloat(v),
    },
  })
  finishedQuantity: number;

  @Column({
    name: 'yield_percentage',
    type: 'decimal',
    precision: 6,
    scale: 2,
    nullable: true,
    transformer: {
      to: (v: number | null) => v,
      from: (v: string | null) => (v ? parseFloat(v) : null),
    },
  })
  yieldPercentage?: number;

  @Column({
    name: 'unit_of_measure',
    type: 'enum',
    enum: UnitOfMeasure,
  })
  unitOfMeasure: UnitOfMeasure;

  @Column({
    name: 'lpg_used_kg',
    type: 'decimal',
    precision: 6,
    scale: 2,
    default: 0,
    transformer: {
      to: (v: number) => v,
      from: (v: string) => parseFloat(v),
    },
  })
  lpgUsedKg: number;

  @Column({ name: 'lpg_stock_item_id', length: 36, nullable: true })
  lpgStockItemId?: string;

  @ManyToOne(() => StockItemEntity, { nullable: true })
  @JoinColumn({ name: 'lpg_stock_item_id' })
  lpgStockItem?: StockItemEntity;

  @Column({
    name: 'byproduct_quantity_kg',
    type: 'decimal',
    precision: 8,
    scale: 2,
    default: 0,
    transformer: {
      to: (v: number) => v,
      from: (v: string) => parseFloat(v),
    },
  })
  byproductQuantityKg: number;

  @Column({ name: 'expiry_date', type: 'date' })
  expiryDate: string;

  @Column({
    name: 'quality_release',
    type: 'enum',
    enum: QualityReleaseStatus,
    default: QualityReleaseStatus.HOLD,
  })
  qualityRelease: QualityReleaseStatus;

  @Column({ type: 'text', nullable: true })
  notes?: string;

  @Column({ name: 'operator_id', length: 36, nullable: true })
  operatorId?: string;

  @Column({ name: 'operator_name', length: 100, nullable: true })
  operatorName?: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @OneToMany(() => ProductionBatchIntake, (pbi) => pbi.productionBatch, {
    cascade: true,
  })
  intakeLinks: ProductionBatchIntake[];
}
