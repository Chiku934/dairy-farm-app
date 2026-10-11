import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BmcIntakeLog } from './entities/bmc-intake-log.entity';
import { BmcService } from './bmc.service';
import { BmcController } from './bmc.controller';

@Module({
  imports: [TypeOrmModule.forFeature([BmcIntakeLog])],
  controllers: [BmcController],
  providers: [BmcService],
  exports: [BmcService],
})
export class BmcModule {}
