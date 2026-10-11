import {
  Entity,
  PrimaryColumn,
  Column,
  UpdateDateColumn,
} from 'typeorm';

@Entity('farm_settings')
export class FarmSettingsEntity {
  @PrimaryColumn({ type: 'int', default: 1 })
  id: number;

  @Column({ name: 'farm_name', type: 'varchar', length: 120, default: 'Kaivalya Dairy' })
  farmName: string;

  @Column({ name: 'address', type: 'varchar', length: 255, default: 'Dandiri' })
  address: string;

  @Column({ name: 'district', type: 'varchar', length: 80, default: 'Koraput' })
  district: string;

  @Column({ name: 'state', type: 'varchar', length: 80, default: 'Odisha' })
  state: string;

  @Column({ name: 'pincode', type: 'varchar', length: 10, default: '764036' })
  pincode: string;

  @Column({ name: 'contact_phone', type: 'varchar', length: 20, default: '+91 9876543210' })
  contactPhone: string;

  @Column({ name: 'contact_email', type: 'varchar', length: 100, default: 'contact@kaivalyadairy.com' })
  contactEmail: string;

  @Column({ name: 'currency_code', type: 'varchar', length: 10, default: 'INR' })
  currencyCode: string;

  @Column({ name: 'currency_symbol', type: 'varchar', length: 5, default: '₹' })
  currencySymbol: string;

  @Column({
    name: 'bmc_capacity_litres',
    type: 'decimal',
    precision: 8,
    scale: 2,
    default: 2000.0,
    transformer: {
      to: (value: number) => value,
      from: (value: string | number) => Number(value),
    },
  })
  bmcCapacityLitres: number;

  @Column({
    name: 'feed_base_kg',
    type: 'decimal',
    precision: 4,
    scale: 2,
    default: 1.0,
    transformer: {
      to: (value: number) => value,
      from: (value: string | number) => Number(value),
    },
  })
  feedBaseKg: number;

  @Column({
    name: 'feed_rate_per_litre',
    type: 'decimal',
    precision: 4,
    scale: 2,
    default: 0.4,
    transformer: {
      to: (value: number) => value,
      from: (value: string | number) => Number(value),
    },
  })
  feedRatePerLitre: number;

  @Column({
    name: 'feed_max_cap_kg',
    type: 'decimal',
    precision: 4,
    scale: 2,
    default: 8.0,
    transformer: {
      to: (value: number) => value,
      from: (value: string | number) => Number(value),
    },
  })
  feedMaxCapKg: number;

  @Column({
    name: 'electricity_tariff',
    type: 'decimal',
    precision: 6,
    scale: 2,
    default: 1.4,
    transformer: {
      to: (value: number) => value,
      from: (value: string | number) => Number(value),
    },
  })
  electricityTariff: number;

  @Column({
    name: 'farm_default_kwh',
    type: 'decimal',
    precision: 6,
    scale: 2,
    default: 50.0,
    transformer: {
      to: (value: number) => value,
      from: (value: string | number) => Number(value),
    },
  })
  farmDefaultKwh: number;

  @Column({
    name: 'production_default_kwh',
    type: 'decimal',
    precision: 6,
    scale: 2,
    default: 200.0,
    transformer: {
      to: (value: number) => value,
      from: (value: string | number) => Number(value),
    },
  })
  productionDefaultKwh: number;

  @Column({
    name: 'mgmt_salary_to_farm_pct',
    type: 'decimal',
    precision: 5,
    scale: 2,
    default: 50.0,
    transformer: {
      to: (value: number) => value,
      from: (value: string | number) => Number(value),
    },
  })
  mgmtSalaryToFarmPct: number;

  @Column({ name: 'operator_name', type: 'varchar', length: 100, default: 'Kaivalya team' })
  operatorName: string;

  @Column({ name: 'timezone', type: 'varchar', length: 50, default: 'Asia/Kolkata' })
  timezone: string;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
