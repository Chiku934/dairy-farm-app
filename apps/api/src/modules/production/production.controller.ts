import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ProductionService } from './production.service';
import { CreateProductionBatchDto } from './dto/create-production-batch.dto';
import { UpdateBatchStatusDto } from './dto/update-batch-status.dto';
import { ProductionQueryDto } from './dto/production-query.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '../../common/guards/permissions.guard';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { CurrentUser, AuthenticatedUser } from '../../common/decorators/current-user.decorator';

@Controller('production')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class ProductionController {
  constructor(private readonly productionService: ProductionService) {}

  @Post('batches')
  @RequirePermissions('production:write')
  async createBatch(
    @Body() dto: CreateProductionBatchDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.productionService.createBatch(dto, user);
  }

  @Get('batches')
  @RequirePermissions('production:read')
  async findAllBatches(@Query() query: ProductionQueryDto) {
    return this.productionService.findAllBatches(query);
  }

  @Get('batches/:id')
  @RequirePermissions('production:read')
  async findOneBatch(@Param('id') id: string) {
    return this.productionService.findOneBatch(id);
  }

  @Get('batches/:id/traceability')
  @RequirePermissions('production:read')
  async getTraceability(@Param('id') id: string) {
    return this.productionService.getTraceability(id);
  }

  @Patch('batches/:id/status')
  @RequirePermissions('production:write')
  async updateStatus(
    @Param('id') id: string,
    @Body() dto: UpdateBatchStatusDto,
  ) {
    return this.productionService.updateReleaseStatus(id, dto);
  }
}
