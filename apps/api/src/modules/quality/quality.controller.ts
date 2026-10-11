import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { QualityService } from './quality.service';
import { CreateQualityRecordDto } from './dto/create-quality-record.dto';
import { QualityQueryDto } from './dto/quality-query.dto';
import { QualityTargetType } from '@dairy-farm/api-contracts';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '../../common/guards/permissions.guard';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { CurrentUser, AuthenticatedUser } from '../../common/decorators/current-user.decorator';

@Controller('quality')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class QualityController {
  constructor(private readonly qualityService: QualityService) {}

  @Post('records')
  @RequirePermissions('quality:write')
  createRecord(
    @Body() dto: CreateQualityRecordDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.qualityService.createRecord(dto, user);
  }

  @Get('records')
  @RequirePermissions('quality:read')
  findAll(@Query() query: QualityQueryDto) {
    return this.qualityService.findAll(query);
  }

  @Get('records/:id')
  @RequirePermissions('quality:read')
  findOne(@Param('id') id: string) {
    return this.qualityService.findOne(id);
  }

  @Get('target/:targetType/:targetId')
  @RequirePermissions('quality:read')
  findByTarget(
    @Param('targetType') targetType: QualityTargetType,
    @Param('targetId') targetId: string,
  ) {
    return this.qualityService.findByTarget(targetType, targetId);
  }
}
