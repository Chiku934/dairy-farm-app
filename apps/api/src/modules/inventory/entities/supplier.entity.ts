import { Entity, PrimaryColumn, Column, CreateDateColumn } from 'typeorm';
import { SupplierCategory } from '@dairy-farm/api-contracts';

@Entity({ name: 'suppliers' })
export class SupplierEntity {
  @PrimaryColumn({ type: 'varchar', length: 36 })
  id: string;

  @Column({ type: 'varchar', length: 120, unique: true })
  name: string;

  @Column({ name: 'contact_person', type: 'varchar', length: 100, nullable: true })
  contactPerson: string | null;

  @Column({ type: 'varchar', length: 20, nullable: true })
  phone: string | null;

  @Column({ type: 'varchar', length: 120, nullable: true })
  email: string | null;

  @Column({ type: 'varchar', length: 255, nullable: true })
  address: string | null;

  @Column({
    type: 'enum',
    enum: SupplierCategory,
    default: SupplierCategory.GENERAL,
  })
  category: SupplierCategory;

  @Column({ name: 'is_active', type: 'boolean', default: true })
  isActive: boolean;

  @CreateDateColumn({ name: 'created_at', type: 'datetime' })
  createdAt: Date;
}
