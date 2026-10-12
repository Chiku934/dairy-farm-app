import {
  Entity,
  PrimaryColumn,
  Column,
  CreateDateColumn,
} from 'typeorm';
import {
  LicenceType,
  LicenceStatus,
  ReminderStatus,
} from '@dairy-farm/api-contracts';

@Entity('regulatory_licences')
export class RegulatoryLicenceEntity {
  @PrimaryColumn({ type: 'varchar', length: 36 })
  id: string;

  @Column({ name: 'licence_name', type: 'varchar', length: 120 })
  licenceName: string;

  @Column({
    name: 'licence_type',
    type: 'enum',
    enum: LicenceType,
    default: LicenceType.OTHER,
  })
  licenceType: LicenceType;

  @Column({ name: 'licence_number', type: 'varchar', length: 80, unique: true })
  licenceNumber: string;

  @Column({ name: 'issuing_authority', type: 'varchar', length: 120 })
  issuingAuthority: string;

  @Column({ name: 'licence_holder', type: 'varchar', length: 120 })
  licenceHolder: string;

  @Column({ name: 'issue_date', type: 'date' })
  issueDate: string;

  @Column({ name: 'expiry_date', type: 'date' })
  expiryDate: string;

  @Column({ name: 'reminder_days_before', type: 'int', default: 30 })
  reminderDaysBefore: number;

  @Column({
    type: 'enum',
    enum: LicenceStatus,
    default: LicenceStatus.ACTIVE,
  })
  status: LicenceStatus;

  @Column({
    name: 'reminder_status',
    type: 'enum',
    enum: ReminderStatus,
    default: ReminderStatus.PENDING,
  })
  reminderStatus: ReminderStatus;

  @Column({ name: 'reminder_sent_at', type: 'datetime', nullable: true })
  reminderSentAt: Date | null;

  @Column({ name: 'document_url', type: 'varchar', length: 255, nullable: true })
  documentUrl: string | null;

  @Column({ type: 'text', nullable: true })
  notes: string | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
