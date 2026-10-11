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
import { BreedingService } from './breeding.service';
import { CreateBreedingRecordDto } from './dto/create-breeding-record.dto';
import { UpdateBreedingRecordDto } from './dto/update-breeding-record.dto';
import { BreedingQueryDto } from './dto/breeding-query.dto';
import { BreedingRecordEntity } from './entities/breeding-record.entity';

@ApiTags('Breeding & Calving')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('breeding')
export class BreedingController {
  constructor(private readonly breedingService: BreedingService) {}

  @Get()
  @RequirePermissions('breeding:read')
  @ApiOperation({ summary: 'List and filter breeding, AI, pregnancy check and calving records' })
  @ApiResponse({ status: 200, description: 'Paginated breeding records returned' })
  async findAll(@Query() query: BreedingQueryDto) {
    return this.breedingService.findAll(query);
  }

  @Get('reminders')
  @RequirePermissions('breeding:read')
  @ApiOperation({ summary: 'Get due-date reminders for upcoming calvings and pregnancy checks' })
  @ApiResponse({ status: 200, description: 'Upcoming breeding reminders returned' })
  async getReminders() {
    return this.breedingService.getReminders();
  }

  @Get(':id')
  @RequirePermissions('breeding:read')
  @ApiOperation({ summary: 'Get single breeding record details by ID' })
  @ApiResponse({ status: 200, description: 'Breeding record details returned', type: BreedingRecordEntity })
  async findOne(@Param('id') id: string) {
    return this.breedingService.findById(id);
  }

  @Post()
  @RequirePermissions('breeding:write')
  @ApiOperation({ summary: 'Record heat, artificial insemination, pregnancy confirmation or calving' })
  @ApiResponse({ status: 201, description: 'Breeding record created successfully', type: BreedingRecordEntity })
  async create(@Body() dto: CreateBreedingRecordDto, @Req() req: any) {
    const userId = req.user?.id;
    return this.breedingService.create(dto, userId);
  }

  @Patch(':id')
  @RequirePermissions('breeding:write')
  @ApiOperation({ summary: 'Update breeding record details or calf tag' })
  @ApiResponse({ status: 200, description: 'Breeding record updated successfully', type: BreedingRecordEntity })
  async update(@Param('id') id: string, @Body() dto: UpdateBreedingRecordDto, @Req() req: any) {
    const userId = req.user?.id;
    return this.breedingService.update(id, dto, userId);
  }
}
