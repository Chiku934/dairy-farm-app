import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
  Query,
  UseGuards,
  Req,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '../../common/guards/permissions.guard';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { AnimalHealthService } from './animal-health.service';
import { CreateHealthRecordDto } from './dto/create-health-record.dto';
import { UpdateHealthRecordDto } from './dto/update-health-record.dto';
import { HealthQueryDto } from './dto/health-query.dto';
import { HealthRecordEntity } from './entities/health-record.entity';

@ApiTags('Health & Vaccination')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('health-records')
export class AnimalHealthController {
  constructor(private readonly healthService: AnimalHealthService) {}

  @Get()
  @RequirePermissions('health:read')
  @ApiOperation({ summary: 'List and filter veterinary health, vaccination and treatment records' })
  @ApiResponse({ status: 200, description: 'Paginated health records returned' })
  async findAll(@Query() query: HealthQueryDto) {
    return this.healthService.findAll(query);
  }

  @Get('reminders')
  @RequirePermissions('health:read')
  @ApiOperation({ summary: 'Get upcoming and overdue vaccination / deworming due date reminders' })
  @ApiResponse({ status: 200, description: 'Upcoming health reminders returned' })
  async getReminders() {
    return this.healthService.getReminders();
  }

  @Get('withdrawals')
  @RequirePermissions('health:read')
  @ApiOperation({ summary: 'Get active milk safety withdrawal records and withheld dates' })
  @ApiResponse({ status: 200, description: 'Active milk safety withdrawal records returned' })
  async getWithdrawals() {
    return this.healthService.getActiveWithdrawals();
  }

  @Get(':id')
  @RequirePermissions('health:read')
  @ApiOperation({ summary: 'Get single health record details by ID' })
  @ApiResponse({ status: 200, description: 'Health record details returned', type: HealthRecordEntity })
  async findOne(@Param('id') id: string) {
    return this.healthService.findById(id);
  }

  @Post()
  @RequirePermissions('health:write')
  @ApiOperation({ summary: 'Record a veterinary treatment, vaccination, deworming or examination' })
  @ApiResponse({ status: 201, description: 'Health record created successfully', type: HealthRecordEntity })
  async create(@Body() dto: CreateHealthRecordDto, @Req() req: any) {
    const userId = req.user?.id;
    return this.healthService.create(dto, userId);
  }

  @Patch(':id')
  @RequirePermissions('health:write')
  @ApiOperation({ summary: 'Update health record details or observation notes' })
  @ApiResponse({ status: 200, description: 'Health record updated successfully', type: HealthRecordEntity })
  async update(@Param('id') id: string, @Body() dto: UpdateHealthRecordDto, @Req() req: any) {
    const userId = req.user?.id;
    return this.healthService.update(id, dto, userId);
  }
}
