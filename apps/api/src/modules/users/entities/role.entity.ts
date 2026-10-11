import {
  Entity,
  PrimaryColumn,
  Column,
  ManyToMany,
  JoinTable,
} from 'typeorm';
import { PermissionEntity } from './permission.entity';

@Entity('roles')
export class RoleEntity {
  @PrimaryColumn({ type: 'varchar', length: 36 })
  id: string;

  @Column({ type: 'varchar', length: 50, unique: true })
  code: string;

  @Column({ type: 'varchar', length: 100 })
  name: string;

  @Column({ type: 'text', nullable: true })
  description: string;

  @ManyToMany(() => PermissionEntity, { eager: false })
  @JoinTable({
    name: 'role_permissions',
    joinColumn: { name: 'role_id', referencedColumnName: 'id' },
    inverseJoinColumn: { name: 'permission_id', referencedColumnName: 'id' },
  })
  permissions: PermissionEntity[];
}
