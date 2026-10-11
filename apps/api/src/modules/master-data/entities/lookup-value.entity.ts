import {
  Entity,
  PrimaryColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { LookupCategoryEntity } from './lookup-category.entity';

@Entity('lookup_values')
export class LookupValueEntity {
  @PrimaryColumn({ type: 'varchar', length: 36 })
  id: string;

  @Column({ name: 'category_code', type: 'varchar', length: 50 })
  categoryCode: string;

  @Column({ type: 'varchar', length: 50 })
  code: string;

  @Column({ type: 'varchar', length: 100 })
  label: string;

  @Column({ name: 'sort_order', type: 'int', default: 0 })
  sortOrder: number;

  @Column({ name: 'is_active', type: 'tinyint', default: 1 })
  isActive: boolean;

  @Column({
    type: 'longtext',
    nullable: true,
    transformer: {
      to: (value: any) => (value ? JSON.stringify(value) : null),
      from: (value: string | null) => {
        if (!value) return null;
        try {
          return JSON.parse(value);
        } catch {
          return value;
        }
      },
    },
  })
  metadata: any;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @ManyToOne(() => LookupCategoryEntity, (cat) => cat.values)
  @JoinColumn({ name: 'category_code', referencedColumnName: 'code' })
  category: LookupCategoryEntity;
}
