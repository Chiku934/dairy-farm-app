import {
  Controller,
  Get,
  Post,
  Put,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { EmployeesService } from './employees.service';
import { CreateEmployeeDto } from './dto/create-employee.dto';
import { UpdateEmployeeDto } from './dto/update-employee.dto';
import { EmployeeQueryDto } from './dto/employee-query.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '../../common/guards/permissions.guard';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { CurrentUser, AuthenticatedUser } from '../../common/decorators/current-user.decorator';

@ApiTags('Employees & Personnel')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('employees')
export class EmployeesController {
  constructor(private readonly employeesService: EmployeesService) {}

  @Post()
  @RequirePermissions('hr:write')
  @ApiOperation({ summary: 'Create new employee profile' })
  async create(
    @Body() dto: CreateEmployeeDto,
    @CurrentUser() user?: AuthenticatedUser,
  ) {
    return this.employeesService.create(dto, user);
  }

  @Get()
  @RequirePermissions('hr:read')
  @ApiOperation({ summary: 'List employees with role-based salary privacy' })
  async findAll(
    @Query() query: EmployeeQueryDto,
    @CurrentUser() user?: AuthenticatedUser,
  ) {
    return this.employeesService.findAll(query, user);
  }

  @Get(':id')
  @RequirePermissions('hr:read')
  @ApiOperation({ summary: 'Get single employee profile with salary redaction if unauthorized' })
  async findOne(
    @Param('id') id: string,
    @CurrentUser() user?: AuthenticatedUser,
  ) {
    return this.employeesService.findOne(id, user);
  }

  @Put(':id')
  @RequirePermissions('hr:write')
  @ApiOperation({ summary: 'Update employee profile' })
  async update(
    @Param('id') id: string,
    @Body() dto: UpdateEmployeeDto,
    @CurrentUser() user?: AuthenticatedUser,
  ) {
    return this.employeesService.update(id, dto, user);
  }

  @Patch(':id')
  @RequirePermissions('hr:write')
  @ApiOperation({ summary: 'Partially update employee profile' })
  async patch(
    @Param('id') id: string,
    @Body() dto: UpdateEmployeeDto,
    @CurrentUser() user?: AuthenticatedUser,
  ) {
    return this.employeesService.update(id, dto, user);
  }

  @Delete(':id')
  @RequirePermissions('hr:write')
  @ApiOperation({ summary: 'Deactivate employee profile' })
  async remove(
    @Param('id') id: string,
    @CurrentUser() user?: AuthenticatedUser,
  ) {
    return this.employeesService.remove(id, user);
  }
}
