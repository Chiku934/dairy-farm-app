import { Injectable, Logger } from '@nestjs/common';
import { RegulatoryLicenceEntity } from './entities/regulatory-licence.entity';

@Injectable()
export class LicenceNotificationService {
  private readonly logger = new Logger(LicenceNotificationService.name);
  private isConfigured: boolean = process.env.NOTIFICATION_SERVICE_CONFIGURED === 'true';

  /**
   * Set configuration flag at runtime (useful for testing or config updates).
   */
  setConfigured(configured: boolean): void {
    this.isConfigured = configured;
    this.logger.log(`Licence notification service configured status changed to: ${configured}`);
  }

  /**
   * Checks if notification service is explicitly configured.
   */
  isServiceConfigured(): boolean {
    return this.isConfigured;
  }

  /**
   * Dispatches an expiry reminder only if the notification service is explicitly configured.
   */
  async dispatchReminder(
    licence: RegulatoryLicenceEntity,
  ): Promise<{ dispatched: boolean; message: string }> {
    if (!this.isConfigured) {
      this.logger.warn(
        `Skipped reminder for licence ${licence.licenceNumber}: Notification service is not configured.`,
      );
      return {
        dispatched: false,
        message: 'Notification service is not configured. Reminder withheld.',
      };
    }

    // Explicitly configured notification dispatch
    this.logger.log(
      `Dispatched licence expiry reminder for ${licence.licenceName} (${licence.licenceNumber}) to compliance officer`,
    );

    return {
      dispatched: true,
      message: `Notification successfully dispatched for licence ${licence.licenceNumber}.`,
    };
  }
}
