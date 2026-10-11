import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SettingsController } from './settings.controller';
import { SettingsService } from './settings.service';
import { FarmSettingsEntity } from './entities/farm-settings.entity';

@Module({
  imports: [TypeOrmModule.forFeature([FarmSettingsEntity])],
  controllers: [SettingsController],
  providers: [SettingsService],
  exports: [SettingsService],
})
export class SettingsModule {}
