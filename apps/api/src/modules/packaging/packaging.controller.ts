import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { PackagingService } from './packaging.service';
import { CreatePackagingRunDto } from './dto/create-packaging-run.dto';
import { PackagingQueryDto } from './dto/packaging-query.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '../../common/guards/permissions.guard';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { CurrentUser, AuthenticatedUser } from '../../common/decorators/current-user.decorator';

@Controller('packaging')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class PackagingController {
  constructor(private readonly packagingService: PackagingService) {}

  @Post('runs')
  @RequirePermissions('production:write')
  createRun(
    @Body() dto: CreatePackagingRunDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.packagingService.createRun(dto, user);
  }

  @Get('runs')
  @RequirePermissions('production:read')
  findAll(@Query() query: PackagingQueryDto) {
    return this.packagingService.findAll(query);
  }

  @Get('runs/:id')
  @RequirePermissions('production:read')
  findOne(@Param('id') id: string) {
    return this.packagingService.findOne(id);
  }

  @Get('batch/:batchId')
  @RequirePermissions('production:read')
  findByBatch(@Param('batchId') batchId: string) {
    return this.packagingService.findByBatch(batchId);
  }
}
