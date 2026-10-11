import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PackagingRunEntity } from './entities/packaging-run.entity';
import { PackagingService } from './packaging.service';
import { PackagingController } from './packaging.controller';
import { AuditModule } from '../audit/audit.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([PackagingRunEntity]),
    AuditModule,
  ],
  controllers: [PackagingController],
  providers: [PackagingService],
  exports: [PackagingService],
})
export class PackagingModule {}
