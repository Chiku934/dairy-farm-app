import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ProductionBatch } from './entities/production-batch.entity';
import { ProductionBatchIntake } from './entities/production-batch-intake.entity';
import { BmcIntakeLog } from '../bmc/entities/bmc-intake-log.entity';
import { StockItemEntity } from '../feed/entities/stock-item.entity';
import { ProductionService } from './production.service';
import { ProductionController } from './production.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      ProductionBatch,
      ProductionBatchIntake,
      BmcIntakeLog,
      StockItemEntity,
    ]),
  ],
  controllers: [ProductionController],
  providers: [ProductionService],
  exports: [ProductionService],
})
export class ProductionModule {}
