import {
  Entity,
  PrimaryColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
  Index,
} from 'typeorm';
import { RationItemEntity } from './ration-item.entity';

export enum TargetAnimalStage {
  LACTATING = 'LACTATING',
  DRY = 'DRY',
  PREGNANT = 'PREGNANT',
  HEIFER = 'HEIFER',
  CALF = 'CALF',
  BULL = 'BULL',
  ALL = 'ALL',
}

@Entity({ name: 'ration_definitions' })
@Index(['target_stage'])
@Index(['is_active'])
export class RationDefinitionEntity {
  @PrimaryColumn({ type: 'varchar', length: 36 })
  id: string;

  @Column({ type: 'varchar', length: 120 })
  name: string;

  @Column({ type: 'varchar', length: 50, unique: true })
  code: string;

  @Column({
    name: 'target_stage',
    type: 'enum',
    enum: TargetAnimalStage,
    default: TargetAnimalStage.LACTATING,
  })
  target_stage: TargetAnimalStage;

  @Column({ type: 'text', nullable: true })
  description: string | null;

  @Column({ name: 'is_active', type: 'tinyint', default: 1 })
  is_active: boolean;

  @Column({ name: 'created_by', type: 'varchar', length: 36, nullable: true })
  created_by: string | null;

  @CreateDateColumn({ name: 'created_at' })
  created_at: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updated_at: Date;

  @OneToMany(() => RationItemEntity, (item) => item.ration, { cascade: true })
  items?: RationItemEntity[];

  // Virtual computed getters / response helpers
  totalQuantityKg?: number;
  totalCost?: number;
  unitCostPerKg?: number;
}
