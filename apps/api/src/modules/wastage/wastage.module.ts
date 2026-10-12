import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { WastageRecordEntity } from './entities/wastage-record.entity';
import { WastageService } from './wastage.service';
import { WastageController } from './wastage.controller';

@Module({
  imports: [TypeOrmModule.forFeature([WastageRecordEntity])],
  controllers: [WastageController],
  providers: [WastageService],
  exports: [WastageService],
})
export class WastageModule {}
