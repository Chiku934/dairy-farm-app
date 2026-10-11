import {
  Controller,
  Get,
  Put,
  Patch,
  Body,
  UsePipes,
  ValidationPipe,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { SettingsService } from './settings.service';
import { FarmSettingsEntity } from './entities/farm-settings.entity';
import { UpdateFarmSettingsDto } from './dto/update-settings.dto';

@ApiTags('Farm Settings & Identity')
@ApiBearerAuth()
@Controller('settings')
export class SettingsController {
  constructor(private readonly settingsService: SettingsService) {}

  @Get()
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
  @ApiOperation({ summary: 'Update master farm operational parameters and identity (full replace)' })
  @ApiResponse({ status: 200, description: 'Farm settings successfully updated' })
  @UsePipes(new ValidationPipe({ transform: true, whitelist: true }))
  async updateSettings(@Body() dto: UpdateFarmSettingsDto): Promise<FarmSettingsEntity> {
    return this.settingsService.updateSettings(dto);
  }

  @Patch()
  @ApiOperation({ summary: 'Partially update master farm operational parameters or identity' })
  @ApiResponse({ status: 200, description: 'Farm settings successfully updated' })
  @UsePipes(new ValidationPipe({ transform: true, whitelist: true }))
  async patchSettings(@Body() dto: UpdateFarmSettingsDto): Promise<FarmSettingsEntity> {
    return this.settingsService.updateSettings(dto);
  }
}
