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
  private cachedSettings: FarmSettingsEntity | null = null;
  private cacheExpiresAt: number = 0;
  private readonly CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes safe TTL

  constructor(
    @InjectRepository(FarmSettingsEntity)
    private readonly settingsRepo: Repository<FarmSettingsEntity>,
    private readonly auditService: AuditService,
  ) {}

  invalidateCache(): void {
    this.cachedSettings = null;
    this.cacheExpiresAt = 0;
  }

  async getSettings(): Promise<FarmSettingsEntity> {
    const now = Date.now();
    if (this.cachedSettings && now < this.cacheExpiresAt) {
      return this.cachedSettings;
    }

    const settings = await this.settingsRepo.findOne({ where: { id: 1 } });
    if (!settings) {
      // Create initial record if missing
      const initial = this.settingsRepo.create({ id: 1 });
      const saved = await this.settingsRepo.save(initial);
      this.cachedSettings = saved;
      this.cacheExpiresAt = now + this.CACHE_TTL_MS;
      return saved;
    }

    this.cachedSettings = settings;
    this.cacheExpiresAt = now + this.CACHE_TTL_MS;
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

    // Invalidate cached copy immediately upon persistence
    this.invalidateCache();

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
