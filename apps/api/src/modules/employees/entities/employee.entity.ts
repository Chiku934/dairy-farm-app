import {
  Entity,
  PrimaryColumn,
  Column,
  CreateDateColumn,
} from 'typeorm';
import { Department, EmploymentStatus } from '@dairy-farm/api-contracts';

@Entity('employees')
export class EmployeeEntity {
  @PrimaryColumn({ type: 'varchar', length: 36 })
  id: string;

  @Column({ name: 'employee_code', type: 'varchar', length: 20, unique: true })
  employeeCode: string;

  @Column({ name: 'full_name', type: 'varchar', length: 120 })
  fullName: string;

  @Column({
    type: 'enum',
    enum: Department,
  })
  department: Department;

  @Column({ name: 'job_title', type: 'varchar', length: 100 })
  jobTitle: string;

  @Column({ name: 'joining_date', type: 'date' })
  joiningDate: string;

  @Column({ name: 'leaving_date', type: 'date', nullable: true })
  leavingDate: string | null;

  @Column({
    name: 'monthly_salary',
    type: 'decimal',
    precision: 10,
    scale: 2,
    transformer: {
      to: (val: number | null) => val,
      from: (val: string | null) => (val !== null && val !== undefined ? parseFloat(val) : null),
    },
  })
  monthlySalary: number | null;

  @Column({
    name: 'daily_salary_rate',
    type: 'decimal',
    precision: 8,
    scale: 2,
    nullable: true,
    insert: false,
    update: false,
    transformer: {
      to: (val: number | null) => val,
      from: (val: string | null) => (val !== null && val !== undefined ? parseFloat(val) : null),
    },
  })
  dailySalaryRate: number | null;

  @Column({ name: 'is_active', type: 'boolean', default: true })
  isActive: boolean;

  @Column({
    type: 'enum',
    enum: EmploymentStatus,
    default: EmploymentStatus.ACTIVE,
  })
  status: EmploymentStatus;

  @Column({ type: 'varchar', length: 20, nullable: true })
  phone: string | null;

  @Column({ type: 'varchar', length: 120, nullable: true })
  email: string | null;

  @Column({ type: 'text', nullable: true })
  notes: string | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
