import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { BiogasService } from './biogas.service';
import { CreateBiogasRunDto } from './dto/create-biogas-run.dto';
import { BiogasQueryDto } from './dto/biogas-query.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '../../common/guards/permissions.guard';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { CurrentUser, AuthenticatedUser } from '../../common/decorators/current-user.decorator';

@ApiTags('Biogas Fertiliser')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('biogas')
export class BiogasController {
  constructor(private readonly biogasService: BiogasService) {}

  @Post('runs')
  @RequirePermissions('utilities:write')
  @ApiOperation({ summary: 'Record biogas run and fertiliser output' })
  async createRun(
    @Body() dto: CreateBiogasRunDto,
    @CurrentUser() user?: AuthenticatedUser,
  ) {
    return await this.biogasService.createRun(dto, user?.userId);
  }

  @Get('runs')
  @RequirePermissions('utilities:read')
  @ApiOperation({ summary: 'List biogas runs with summary KPI metrics' })
  async findAll(@Query() query: BiogasQueryDto) {
    return await this.biogasService.findAll(query);
  }

  @Get('runs/:id')
  @RequirePermissions('utilities:read')
  @ApiOperation({ summary: 'Get single biogas run details' })
  async findOne(@Param('id') id: string) {
    return await this.biogasService.findOne(id);
  }
}
