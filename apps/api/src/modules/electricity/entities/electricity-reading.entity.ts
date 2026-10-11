import { Entity, PrimaryColumn, Column, CreateDateColumn } from 'typeorm';
import { Department } from '@dairy-farm/api-contracts';

@Entity({ name: 'electricity_readings' })
export class ElectricityReadingEntity {
  @PrimaryColumn({ type: 'varchar', length: 36 })
  id: string;

  @Column({ name: 'record_date', type: 'date' })
  record_date: string;

  @Column({
    type: 'enum',
    enum: Department,
  })
  department: Department;

  @Column({
    name: 'opening_reading_kwh',
    type: 'decimal',
    precision: 10,
    scale: 2,
    nullable: true,
    transformer: {
      to: (val: number | null) => val,
      from: (val: string | null) => (val !== null ? parseFloat(val) : null),
    },
  })
  opening_reading_kwh: number | null;

  @Column({
    name: 'closing_reading_kwh',
    type: 'decimal',
    precision: 10,
    scale: 2,
    nullable: true,
    transformer: {
      to: (val: number | null) => val,
      from: (val: string | null) => (val !== null ? parseFloat(val) : null),
    },
  })
  closing_reading_kwh: number | null;

  @Column({
    name: 'units_kwh',
    type: 'decimal',
    precision: 8,
    scale: 2,
    transformer: {
      to: (val: number) => val,
      from: (val: string) => parseFloat(val),
    },
  })
  units_kwh: number;

  @Column({
    name: 'tariff_rate',
    type: 'decimal',
    precision: 6,
    scale: 2,
    transformer: {
      to: (val: number) => val,
      from: (val: string) => parseFloat(val),
    },
  })
  tariff_rate: number;

  @Column({
    name: 'total_cost',
    type: 'decimal',
    precision: 10,
    scale: 2,
    transformer: {
      to: (val: number) => val,
      from: (val: string) => parseFloat(val),
    },
  })
  total_cost: number;

  @Column({ type: 'text', nullable: true })
  notes: string | null;

  @Column({ name: 'created_by', type: 'varchar', length: 36, nullable: true })
  created_by: string | null;

  @CreateDateColumn({ name: 'created_at' })
  created_at: Date;
}
