import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { FeedEntryEntity } from './entities/feed-entry.entity';
import { StockItemEntity } from './entities/stock-item.entity';
import { RationDefinitionEntity } from './entities/ration-definition.entity';
import { RationItemEntity } from './entities/ration-item.entity';
import { AnimalEntity } from '../herd/entities/animal.entity';
import { MilkingLogEntity } from '../milking/entities/milking-log.entity';
import { FeedService } from './feed.service';
import { FeedController } from './feed.controller';
import { AuditModule } from '../audit/audit.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      FeedEntryEntity,
      StockItemEntity,
      RationDefinitionEntity,
      RationItemEntity,
      AnimalEntity,
      MilkingLogEntity,
    ]),
    AuditModule,
  ],
  controllers: [FeedController],
  providers: [FeedService],
  exports: [FeedService],
})
export class FeedModule {}
