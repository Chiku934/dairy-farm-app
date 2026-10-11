import {
  Entity,
  PrimaryColumn,
  Column,
  CreateDateColumn,
} from 'typeorm';

export enum UomDimension {
  VOLUME = 'VOLUME',
  MASS = 'MASS',
  COUNT = 'COUNT',
  ENERGY = 'ENERGY',
  TIME = 'TIME',
  OTHER = 'OTHER',
}

@Entity('units_of_measurement')
export class UnitOfMeasurementEntity {
  @PrimaryColumn({ type: 'varchar', length: 36 })
  id: string;

  @Column({ type: 'varchar', length: 20, unique: true })
  code: string;

  @Column({ type: 'varchar', length: 60 })
  name: string;

  @Column({
    type: 'enum',
    enum: UomDimension,
    default: UomDimension.COUNT,
  })
  dimension: UomDimension;

  @Column({
    name: 'conversion_factor',
    type: 'decimal',
    precision: 12,
    scale: 6,
    default: 1.0,
    transformer: {
      to: (value: number) => value,
      from: (value: string | number) => Number(value),
    },
  })
  conversionFactor: number;

  @Column({ name: 'base_unit_code', type: 'varchar', length: 20, nullable: true })
  baseUnitCode: string;

  @Column({ name: 'is_active', type: 'tinyint', default: 1 })
  isActive: boolean;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
