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
import { HerdService } from './herd.service';
import { CreateAnimalDto } from './dto/create-animal.dto';
import { UpdateAnimalDto } from './dto/update-animal.dto';
import { ArchiveAnimalDto } from './dto/archive-animal.dto';
import { AnimalQueryDto } from './dto/animal-query.dto';
import { AnimalEntity } from './entities/animal.entity';

@ApiTags('Herd & Calves')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('herd')
export class HerdController {
  constructor(private readonly herdService: HerdService) {}

  @Get()
  @RequirePermissions('animals:read')
  @ApiOperation({ summary: 'List and filter cattle registry with pagination' })
  @ApiResponse({ status: 200, description: 'Paginated cattle records returned' })
  async findAll(@Query() query: AnimalQueryDto) {
    return this.herdService.findAll(query);
  }

  @Get('summary')
  @RequirePermissions('animals:read')
  @ApiOperation({ summary: 'Get active herd lifecycle stage counts and totals' })
  @ApiResponse({ status: 200, description: 'Lifecycle count summary returned' })
  async getSummary() {
    return this.herdService.getSummary();
  }

  @Get(':id')
  @RequirePermissions('animals:read')
  @ApiOperation({ summary: 'Get single animal details by UUID or Ear Tag' })
  @ApiResponse({ status: 200, description: 'Animal details returned', type: AnimalEntity })
  async findOne(@Param('id') id: string) {
    return this.herdService.findByIdOrTag(id);
  }

  @Get(':id/history')
  @RequirePermissions('animals:read')
  @ApiOperation({ summary: 'Get chronological history timeline (health, breeding, milking)' })
  @ApiResponse({ status: 200, description: 'Unified historical timeline returned' })
  async getHistory(@Param('id') id: string) {
    return this.herdService.getHistory(id);
  }

  @Post()
  @RequirePermissions('animals:write')
  @ApiOperation({ summary: 'Register a new cattle into the herd registry' })
  @ApiResponse({ status: 201, description: 'Animal created successfully', type: AnimalEntity })
  async create(@Body() dto: CreateAnimalDto, @Req() req: any) {
    const userId = req.user?.id;
    return this.herdService.create(dto, userId);
  }

  @Patch(':id')
  @RequirePermissions('animals:write')
  @ApiOperation({ summary: 'Update animal details, weight, status or notes' })
  @ApiResponse({ status: 200, description: 'Animal updated successfully', type: AnimalEntity })
  async update(@Param('id') id: string, @Body() dto: UpdateAnimalDto, @Req() req: any) {
    const userId = req.user?.id;
    return this.herdService.update(id, dto, userId);
  }

  @Post(':id/archive')
  @RequirePermissions('animals:write')
  @ApiOperation({ summary: 'Archive/retire animal (Sold, Deceased) while preserving history' })
  @ApiResponse({ status: 200, description: 'Animal archived successfully', type: AnimalEntity })
  async archive(@Param('id') id: string, @Body() dto: ArchiveAnimalDto, @Req() req: any) {
    const userId = req.user?.id;
    return this.herdService.archive(id, dto, userId);
  }
}
