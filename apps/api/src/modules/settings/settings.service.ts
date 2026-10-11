import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { FarmSettingsEntity } from './entities/farm-settings.entity';
import { UpdateFarmSettingsDto } from './dto/update-settings.dto';

@Injectable()
export class SettingsService {
  constructor(
    @InjectRepository(FarmSettingsEntity)
    private readonly settingsRepo: Repository<FarmSettingsEntity>,
  ) {}

  async getSettings(): Promise<FarmSettingsEntity> {
    const settings = await this.settingsRepo.findOne({ where: { id: 1 } });
    if (!settings) {
      // Create initial record if missing
      const initial = this.settingsRepo.create({ id: 1 });
      return this.settingsRepo.save(initial);
    }
    return settings;
  }

  async updateSettings(dto: UpdateFarmSettingsDto): Promise<FarmSettingsEntity> {
    let settings = await this.settingsRepo.findOne({ where: { id: 1 } });
    if (!settings) {
      settings = this.settingsRepo.create({ id: 1, ...dto });
    } else {
      Object.assign(settings, dto);
    }
    return this.settingsRepo.save(settings);
  }
}
