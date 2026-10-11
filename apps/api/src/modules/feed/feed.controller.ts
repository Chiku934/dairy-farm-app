import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  Query,
  UseGuards,
  Req,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { FeedService } from './feed.service';
import { CreateFeedEntryDto } from './dto/create-feed-entry.dto';
import { CreateRationDto } from './dto/create-ration.dto';
import { UpdateRationDto } from './dto/update-ration.dto';
import { FeedQueryDto } from './dto/feed-query.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '../../common/guards/permissions.guard';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';

@ApiTags('Feed & Ration Planning')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('feed')
export class FeedController {
  constructor(private readonly feedService: FeedService) {}

  @Post()
  @RequirePermissions('feed:write')
  @ApiOperation({ summary: 'Record daily cattle feed issuance and deduct inventory' })
  async recordFeedConsumption(
    @Body() dto: CreateFeedEntryDto,
    @Req() req: any,
  ) {
    return this.feedService.recordFeedConsumption(dto, req.user?.id);
  }

  @Get()
  @RequirePermissions('feed:read')
  @ApiOperation({ summary: 'List feed consumption logs with filters and pagination' })
  async findAllFeedEntries(@Query() query: FeedQueryDto) {
    return this.feedService.findAllFeedEntries(query);
  }

  @Get('rules/:animalId')
  @RequirePermissions('feed:read')
  @ApiOperation({ summary: 'Calculate milk-production linked target concentrate for a cow' })
  async calculateConcentrateTarget(@Param('animalId') animalId: string) {
    return this.feedService.calculateConcentrateTarget(animalId);
  }

  @Get('rations')
  @RequirePermissions('feed:read')
  @ApiOperation({ summary: 'List ration formulations with computed total and unit costs' })
  async findAllRations() {
    return this.feedService.findAllRations();
  }

  @Post('rations')
  @RequirePermissions('feed:write')
  @ApiOperation({ summary: 'Create a new ration diet definition and its ingredient list' })
  async createRation(@Body() dto: CreateRationDto, @Req() req: any) {
    return this.feedService.createRation(dto, req.user?.id);
  }

  @Get('rations/:id')
  @RequirePermissions('feed:read')
  @ApiOperation({ summary: 'Get single ration formulation and its computed cost metrics' })
  async findRationById(@Param('id') id: string) {
    return this.feedService.findRationById(id);
  }

  @Patch('rations/:id')
  @RequirePermissions('feed:write')
  @ApiOperation({ summary: 'Update ration formulation details and ingredient list' })
  async updateRation(
    @Param('id') id: string,
    @Body() dto: UpdateRationDto,
    @Req() req: any,
  ) {
    return this.feedService.updateRation(id, dto, req.user?.id);
  }
}
