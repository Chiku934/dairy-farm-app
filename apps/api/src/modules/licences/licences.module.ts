import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { RegulatoryLicenceEntity } from './entities/regulatory-licence.entity';
import { LicencesService } from './licences.service';
import { LicencesController } from './licences.controller';
import { LicenceNotificationService } from './licence-notification.service';
import { AuditModule } from '../audit/audit.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([RegulatoryLicenceEntity]),
    AuditModule,
  ],
  controllers: [LicencesController],
  providers: [LicencesService, LicenceNotificationService],
  exports: [LicencesService, LicenceNotificationService],
})
export class LicencesModule {}
