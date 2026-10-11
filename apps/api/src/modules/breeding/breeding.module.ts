import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BreedingRecordEntity } from './entities/breeding-record.entity';
import { AnimalEntity } from '../herd/entities/animal.entity';
import { BreedingController } from './breeding.controller';
import { BreedingService } from './breeding.service';
import { AuditModule } from '../audit/audit.module';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([BreedingRecordEntity, AnimalEntity]),
    AuditModule,
    AuthModule,
  ],
  controllers: [BreedingController],
  providers: [BreedingService],
  exports: [BreedingService],
})
export class BreedingModule {}
