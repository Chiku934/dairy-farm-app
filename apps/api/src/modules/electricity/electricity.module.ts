import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ElectricityReadingEntity } from './entities/electricity-reading.entity';
import { ElectricityService } from './electricity.service';
import { ElectricityController } from './electricity.controller';
import { AuditModule } from '../audit/audit.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([ElectricityReadingEntity]),
    AuditModule,
  ],
  controllers: [ElectricityController],
  providers: [ElectricityService],
  exports: [ElectricityService],
})
export class ElectricityModule {}
