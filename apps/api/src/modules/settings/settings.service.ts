import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { FarmSettingsEntity } from './entities/farm-settings.entity';
import { UpdateFarmSettingsDto } from './dto/update-settings.dto';
import { AuditService } from '../audit/audit.service';
import { AuthenticatedUser } from '../../common/decorators/current-user.decorator';

@Injectable()
export class SettingsService {
  private readonly logger = new Logger(SettingsService.name);

  constructor(
    @InjectRepository(FarmSettingsEntity)
    private readonly settingsRepo: Repository<FarmSettingsEntity>,
    private readonly auditService: AuditService,
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

  async updateSettings(
    dto: UpdateFarmSettingsDto,
    user?: AuthenticatedUser,
  ): Promise<FarmSettingsEntity> {
    let settings = await this.settingsRepo.findOne({ where: { id: 1 } });
    const oldValues = settings ? { ...settings } : null;

    if (!settings) {
      settings = this.settingsRepo.create({ id: 1, ...dto });
    } else {
      Object.assign(settings, dto);
    }
    const saved = await this.settingsRepo.save(settings);

    await this.auditService.logAction({
      userId: user?.userId,
      action: 'UPDATE_FARM_SETTINGS',
      entityType: 'FARM_SETTINGS',
      entityId: '1',
      oldValues,
      newValues: saved,
    });

    this.logger.log(`Farm settings updated by user ${user?.userId || 'SYSTEM'}`);
    return saved;
  }
}
