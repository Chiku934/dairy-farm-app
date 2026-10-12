import {
  Controller,
  Get,
  Post,
  Put,
  Patch,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { LicencesService } from './licences.service';
import { CreateLicenceDto } from './dto/create-licence.dto';
import { UpdateLicenceDto } from './dto/update-licence.dto';
import { LicenceQueryDto } from './dto/licence-query.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '../../common/guards/permissions.guard';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { CurrentUser, AuthenticatedUser } from '../../common/decorators/current-user.decorator';

@ApiTags('Regulatory Licences & Compliance')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('licences')
export class LicencesController {
  constructor(private readonly licencesService: LicencesService) {}

  @Post()
  @RequirePermissions('farm:settings:write')
  @ApiOperation({ summary: 'Register a regulatory licence (FSSAI, Pollution, etc.)' })
  async create(
    @Body() dto: CreateLicenceDto,
    @CurrentUser() user?: AuthenticatedUser,
  ) {
    return this.licencesService.create(dto, user);
  }

  @Get()
  @RequirePermissions('farm:settings:read')
  @ApiOperation({ summary: 'List regulatory licences with computed status' })
  async findAll(@Query() query: LicenceQueryDto) {
    return this.licencesService.findAll(query);
  }

  @Get(':id')
  @RequirePermissions('farm:settings:read')
  @ApiOperation({ summary: 'Get single licence details' })
  async findOne(@Param('id') id: string) {
    return this.licencesService.findOne(id);
  }

  @Put(':id')
  @RequirePermissions('farm:settings:write')
  @ApiOperation({ summary: 'Update regulatory licence' })
  async update(
    @Param('id') id: string,
    @Body() dto: UpdateLicenceDto,
    @CurrentUser() user?: AuthenticatedUser,
  ) {
    return this.licencesService.update(id, dto, user);
  }

  @Patch(':id')
  @RequirePermissions('farm:settings:write')
  @ApiOperation({ summary: 'Partially update regulatory licence' })
  async patch(
    @Param('id') id: string,
    @Body() dto: UpdateLicenceDto,
    @CurrentUser() user?: AuthenticatedUser,
  ) {
    return this.licencesService.update(id, dto, user);
  }

  @Post('process-reminders')
  @RequirePermissions('farm:settings:write')
  @ApiOperation({ summary: 'Trigger expiry reminder processing via configured notification service' })
  async processReminders(@CurrentUser() user?: AuthenticatedUser) {
    return this.licencesService.processReminders(user);
  }

  @Patch(':id/dismiss-reminder')
  @RequirePermissions('farm:settings:write')
  @ApiOperation({ summary: 'Dismiss reminder alert for a licence' })
  async dismissReminder(
    @Param('id') id: string,
    @CurrentUser() user?: AuthenticatedUser,
  ) {
    return this.licencesService.dismissReminder(id, user);
  }
}
