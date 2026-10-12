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
import { WastageService } from './wastage.service';
import { CreateWastageDto } from './dto/create-wastage.dto';
import { WastageQueryDto } from './dto/wastage-query.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '../../common/guards/permissions.guard';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { CurrentUser, AuthenticatedUser } from '../../common/decorators/current-user.decorator';

@ApiTags('Wastage & Losses')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('wastage')
export class WastageController {
  constructor(private readonly wastageService: WastageService) {}

  @Post()
  @RequirePermissions('inventory:write')
  @ApiOperation({ summary: 'Record wastage or spoilage incident and adjust stock ledger' })
  async recordWastage(
    @Body() dto: CreateWastageDto,
    @CurrentUser() user?: AuthenticatedUser,
  ) {
    return await this.wastageService.recordWastage(dto, user?.userId);
  }

  @Get()
  @RequirePermissions('inventory:read')
  @ApiOperation({ summary: 'List wastage records with KPI summary metrics' })
  async findAll(@Query() query: WastageQueryDto) {
    return await this.wastageService.findAll(query);
  }

  @Get(':id')
  @RequirePermissions('inventory:read')
  @ApiOperation({ summary: 'Get single wastage record details' })
  async findOne(@Param('id') id: string) {
    return await this.wastageService.findOne(id);
  }
}
