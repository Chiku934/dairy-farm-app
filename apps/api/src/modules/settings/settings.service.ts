import { Injectable } from '@nestjs/common';
import { UpdateFarmSettingsDto } from './dto/update-settings.dto';

export interface FarmSettingsEntity extends UpdateFarmSettingsDto {
  id: number;
  timezone: string;
  updatedAt: string;
}

@Injectable()
export class SettingsService {
  // Initial default settings seeded directly from reference specification
  private settings: FarmSettingsEntity = {
    id: 1,
    bmcCapacityLitres: 2000.0,
    feedBaseKg: 1.0,
    feedRatePerLitre: 0.4,
    feedMaxCapKg: 8.0,
    electricityTariff: 1.4,
    farmDefaultKwh: 50.0,
    productionDefaultKwh: 200.0,
    mgmtSalaryToFarmPct: 50.0,
    operatorName: 'Kaivalya team',
    timezone: 'Asia/Kolkata',
    updatedAt: new Date().toISOString(),
  };

  getSettings(): FarmSettingsEntity {
    return this.settings;
  }

  updateSettings(dto: UpdateFarmSettingsDto): FarmSettingsEntity {
    this.settings = {
      ...this.settings,
      ...dto,
      updatedAt: new Date().toISOString(),
    };
    return this.settings;
  }
}
