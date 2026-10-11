import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AnimalEntity } from './entities/animal.entity';
import { HealthRecordEntity } from '../animal-health/entities/health-record.entity';
import { BreedingRecordEntity } from '../breeding/entities/breeding-record.entity';
import { HerdController } from './herd.controller';
import { HerdService } from './herd.service';
import { AuditModule } from '../audit/audit.module';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([AnimalEntity, HealthRecordEntity, BreedingRecordEntity]),
    AuditModule,
    AuthModule,
  ],
  controllers: [HerdController],
  providers: [HerdService],
  exports: [HerdService],
})
export class HerdModule {}
