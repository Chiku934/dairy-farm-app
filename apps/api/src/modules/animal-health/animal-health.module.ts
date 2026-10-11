import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { HealthRecordEntity } from './entities/health-record.entity';
import { AnimalEntity } from '../herd/entities/animal.entity';
import { AnimalHealthController } from './animal-health.controller';
import { AnimalHealthService } from './animal-health.service';
import { AuditModule } from '../audit/audit.module';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([HealthRecordEntity, AnimalEntity]),
    AuditModule,
    AuthModule,
  ],
  controllers: [AnimalHealthController],
  providers: [AnimalHealthService],
  exports: [AnimalHealthService],
})
export class AnimalHealthModule {}
