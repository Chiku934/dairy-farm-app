import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { MaterialsService } from './materials.service';
import { CreateMaterialIssueDto } from './dto/create-material-issue.dto';
import { MaterialQueryDto } from './dto/material-query.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '../../common/guards/permissions.guard';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { CurrentUser, AuthenticatedUser } from '../../common/decorators/current-user.decorator';

@Controller('materials')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class MaterialsController {
  constructor(private readonly materialsService: MaterialsService) {}

  @Post('issues')
  @RequirePermissions('inventory:write')
  createIssue(
    @Body() dto: CreateMaterialIssueDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.materialsService.createIssue(dto, user);
  }

  @Get('issues')
  @RequirePermissions('inventory:read')
  findAll(@Query() query: MaterialQueryDto) {
    return this.materialsService.findAll(query);
  }

  @Get('issues/:id')
  @RequirePermissions('inventory:read')
  findOne(@Param('id') id: string) {
    return this.materialsService.findOne(id);
  }
}
