import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { CostingService } from './costing.service';
import { DailyCostingQueryDto } from './dto/daily-costing-query.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '../../common/guards/permissions.guard';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';

@ApiTags('Unit Costing')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('costing')
export class CostingController {
  constructor(private readonly costingService: CostingService) {}

  @Get('daily-milk')
  @RequirePermissions('finance:read')
  @ApiOperation({ summary: 'Compute daily farm operating cost and cost per litre of eligible milk' })
  async getDailyMilkCosting(@Query() query: DailyCostingQueryDto) {
    return this.costingService.getDailyMilkCosting(query);
  }
}
