import { Controller, Get, Put, Body, UsePipes, ValidationPipe } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { SettingsService, FarmSettingsEntity } from './settings.service';
import { UpdateFarmSettingsDto } from './dto/update-settings.dto';

@ApiTags('Business: Farm Settings')
@Controller('settings')
export class SettingsController {
  constructor(private readonly settingsService: SettingsService) {}

  @Get()
  @ApiOperation({ summary: 'Retrieve master farm operational parameters' })
  @ApiResponse({ status: 200, description: 'Current farm settings returned' })
  getSettings(): FarmSettingsEntity {
    return this.settingsService.getSettings();
  }

  @Put()
  @ApiOperation({ summary: 'Update master farm operational parameters' })
  @ApiResponse({ status: 200, description: 'Farm settings successfully updated' })
  @UsePipes(new ValidationPipe({ transform: true, whitelist: true }))
  updateSettings(@Body() dto: UpdateFarmSettingsDto): FarmSettingsEntity {
    return this.settingsService.updateSettings(dto);
  }
}
