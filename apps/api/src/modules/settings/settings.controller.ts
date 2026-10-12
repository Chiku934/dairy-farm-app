import {
  Controller,
  Get,
  Put,
  Patch,
  Body,
  UsePipes,
  ValidationPipe,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { SettingsService } from './settings.service';
import { FarmSettingsEntity } from './entities/farm-settings.entity';
import { UpdateFarmSettingsDto } from './dto/update-settings.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '../../common/guards/permissions.guard';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { CurrentUser, AuthenticatedUser } from '../../common/decorators/current-user.decorator';

@ApiTags('Farm Settings & Identity')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('settings')
export class SettingsController {
  constructor(private readonly settingsService: SettingsService) {}

  @Get()
  @RequirePermissions('farm:settings:read')
  @ApiOperation({ summary: 'Retrieve master farm operational parameters and identity' })
  @ApiResponse({
    status: 200,
    description: 'Current farm settings and identity records returned',
    type: FarmSettingsEntity,
  })
  async getSettings(): Promise<FarmSettingsEntity> {
    return this.settingsService.getSettings();
  }

  @Put()
  @RequirePermissions('farm:settings:write')
  @ApiOperation({ summary: 'Update master farm operational parameters and identity (full replace)' })
  @ApiResponse({ status: 200, description: 'Farm settings successfully updated' })
  @UsePipes(new ValidationPipe({ transform: true, whitelist: true }))
  async updateSettings(
    @Body() dto: UpdateFarmSettingsDto,
    @CurrentUser() user?: AuthenticatedUser,
  ): Promise<FarmSettingsEntity> {
    return this.settingsService.updateSettings(dto, user);
  }

  @Patch()
  @RequirePermissions('farm:settings:write')
  @ApiOperation({ summary: 'Partially update master farm operational parameters or identity' })
  @ApiResponse({ status: 200, description: 'Farm settings successfully updated' })
  @UsePipes(new ValidationPipe({ transform: true, whitelist: true }))
  async patchSettings(
    @Body() dto: UpdateFarmSettingsDto,
    @CurrentUser() user?: AuthenticatedUser,
  ): Promise<FarmSettingsEntity> {
    return this.settingsService.updateSettings(dto, user);
  }
}
