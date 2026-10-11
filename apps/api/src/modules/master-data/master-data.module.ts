import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MasterDataController } from './master-data.controller';
import { MasterDataService } from './master-data.service';
import { UnitOfMeasurementEntity } from './entities/unit-of-measurement.entity';
import { LookupCategoryEntity } from './entities/lookup-category.entity';
import { LookupValueEntity } from './entities/lookup-value.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      UnitOfMeasurementEntity,
      LookupCategoryEntity,
      LookupValueEntity,
    ]),
  ],
  controllers: [MasterDataController],
  providers: [MasterDataService],
  exports: [MasterDataService],
})
export class MasterDataModule {}
