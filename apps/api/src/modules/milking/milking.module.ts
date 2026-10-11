import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MilkingLogEntity } from './entities/milking-log.entity';
import { AnimalEntity } from '../herd/entities/animal.entity';
import { HealthRecordEntity } from '../animal-health/entities/health-record.entity';
import { UserEntity } from '../users/entities/user.entity';
import { MilkingService } from './milking.service';
import { MilkingController } from './milking.controller';
import { AuditModule } from '../audit/audit.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      MilkingLogEntity,
      AnimalEntity,
      HealthRecordEntity,
      UserEntity,
    ]),
    AuditModule,
  ],
  controllers: [MilkingController],
  providers: [MilkingService],
  exports: [MilkingService],
})
export class MilkingModule {}
