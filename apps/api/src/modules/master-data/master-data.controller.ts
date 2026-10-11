import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  UsePipes,
  ValidationPipe,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiParam,
  ApiQuery,
} from '@nestjs/swagger';
import { MasterDataService } from './master-data.service';
import { UnitOfMeasurementEntity } from './entities/unit-of-measurement.entity';
import { LookupCategoryEntity } from './entities/lookup-category.entity';
import { LookupValueEntity } from './entities/lookup-value.entity';
import { CreateUomDto } from './dto/create-uom.dto';
import { CreateLookupCategoryDto, CreateLookupValueDto } from './dto/create-lookup.dto';

@ApiTags('Master Data & Lookups')
@ApiBearerAuth()
@Controller('master-data')
export class MasterDataController {
  constructor(private readonly masterDataService: MasterDataService) {}

  @Get('uoms')
  @ApiOperation({ summary: 'List all units of measurement' })
  @ApiQuery({ name: 'isActiveOnly', required: false, type: Boolean })
  @ApiResponse({ status: 200, description: 'UOM list returned', type: [UnitOfMeasurementEntity] })
  async getUoms(
    @Query('isActiveOnly') isActiveOnly?: boolean,
  ): Promise<UnitOfMeasurementEntity[]> {
    return this.masterDataService.getAllUoms(
      isActiveOnly !== undefined ? String(isActiveOnly) === 'true' : true,
    );
  }

  @Post('uoms')
  @ApiOperation({ summary: 'Register a new unit of measurement' })
  @ApiResponse({ status: 201, description: 'UOM created', type: UnitOfMeasurementEntity })
  @ApiResponse({ status: 409, description: 'UOM code already exists' })
  @UsePipes(new ValidationPipe({ transform: true, whitelist: true }))
  async createUom(@Body() dto: CreateUomDto): Promise<UnitOfMeasurementEntity> {
    return this.masterDataService.createUom(dto);
  }

  @Get('categories')
  @ApiOperation({ summary: 'List all lookup categories and their values' })
  @ApiResponse({ status: 200, description: 'Categories returned', type: [LookupCategoryEntity] })
  async getCategories(): Promise<LookupCategoryEntity[]> {
    return this.masterDataService.getAllCategories();
  }

  @Post('categories')
  @ApiOperation({ summary: 'Create a new lookup master category' })
  @ApiResponse({ status: 201, description: 'Category created', type: LookupCategoryEntity })
  @UsePipes(new ValidationPipe({ transform: true, whitelist: true }))
  async createCategory(
    @Body() dto: CreateLookupCategoryDto,
  ): Promise<LookupCategoryEntity> {
    return this.masterDataService.createCategory(dto);
  }

  @Get('categories/:categoryCode/values')
  @ApiOperation({ summary: 'Get all lookup values for a specific category' })
  @ApiParam({ name: 'categoryCode', example: 'ANIMAL_BREED' })
  @ApiQuery({ name: 'isActiveOnly', required: false, type: Boolean })
  @ApiResponse({ status: 200, description: 'Lookup values returned', type: [LookupValueEntity] })
  async getValuesByCategory(
    @Param('categoryCode') categoryCode: string,
    @Query('isActiveOnly') isActiveOnly?: boolean,
  ): Promise<LookupValueEntity[]> {
    return this.masterDataService.getValuesByCategory(
      categoryCode,
      isActiveOnly !== undefined ? String(isActiveOnly) === 'true' : true,
    );
  }

  @Post('values')
  @ApiOperation({ summary: 'Add a new value to a lookup category' })
  @ApiResponse({ status: 201, description: 'Lookup value created', type: LookupValueEntity })
  @UsePipes(new ValidationPipe({ transform: true, whitelist: true }))
  async createValue(
    @Body() dto: CreateLookupValueDto,
  ): Promise<LookupValueEntity> {
    return this.masterDataService.createLookupValue(dto);
  }
}
