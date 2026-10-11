import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ElectricityService } from './electricity.service';
import { CreateElectricityReadingDto } from './dto/create-electricity-reading.dto';
import { ElectricityQueryDto } from './dto/electricity-query.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '../../common/guards/permissions.guard';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { CurrentUser, AuthenticatedUser } from '../../common/decorators/current-user.decorator';

@Controller('electricity')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class ElectricityController {
  constructor(private readonly electricityService: ElectricityService) {}

  @Post('readings')
  @RequirePermissions('utilities:write')
  createReading(
    @Body() dto: CreateElectricityReadingDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.electricityService.createReading(dto, user);
  }

  @Get('readings')
  @RequirePermissions('utilities:read')
  findAll(@Query() query: ElectricityQueryDto) {
    return this.electricityService.findAll(query);
  }

  @Get('readings/:id')
  @RequirePermissions('utilities:read')
  findOne(@Param('id') id: string) {
    return this.electricityService.findOne(id);
  }
}
