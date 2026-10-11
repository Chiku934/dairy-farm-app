import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  Req,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { MilkingService } from './milking.service';
import { CreateMilkingLogDto } from './dto/create-milking-log.dto';
import { UpdateMilkingLogDto } from './dto/update-milking-log.dto';
import { MilkingQueryDto } from './dto/milking-query.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '../../common/guards/permissions.guard';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';

@ApiTags('Milking Log')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('milking')
export class MilkingController {
  constructor(private readonly milkingService: MilkingService) {}

  @Post()
  @RequirePermissions('milking:write')
  @ApiOperation({ summary: 'Record individual cow or group milking session yield' })
  async create(@Body() dto: CreateMilkingLogDto, @Req() req: any) {
    return this.milkingService.create(dto, req.user?.id);
  }

  @Get()
  @RequirePermissions('milking:read')
  @ApiOperation({ summary: 'List milking sessions with filters, pagination, and sorting' })
  async findAll(@Query() query: MilkingQueryDto) {
    return this.milkingService.findAll(query);
  }

  @Get('summary')
  @RequirePermissions('milking:read')
  @ApiOperation({ summary: 'Aggregate metrics for milk production and shift volumes' })
  @ApiQuery({ name: 'startDate', required: false })
  @ApiQuery({ name: 'endDate', required: false })
  async getSummary(@Query('startDate') startDate?: string, @Query('endDate') endDate?: string) {
    return this.milkingService.getSummary(startDate, endDate);
  }

  @Get(':id')
  @RequirePermissions('milking:read')
  @ApiOperation({ summary: 'Get milking log details by ID' })
  async findById(@Param('id') id: string) {
    return this.milkingService.findById(id);
  }

  @Patch(':id')
  @RequirePermissions('milking:write')
  @ApiOperation({ summary: 'Update an existing milking record' })
  async update(
    @Param('id') id: string,
    @Body() dto: UpdateMilkingLogDto,
    @Req() req: any,
  ) {
    return this.milkingService.update(id, dto, req.user?.id);
  }

  @Delete(':id')
  @RequirePermissions('milking:write')
  @ApiOperation({ summary: 'Delete a milking record' })
  async remove(@Param('id') id: string, @Req() req: any) {
    await this.milkingService.remove(id, req.user?.id);
    return { message: 'Milking log deleted successfully' };
  }
}
