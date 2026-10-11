import {
  Controller,
  Get,
  Post,
  Patch,
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
} from '@nestjs/swagger';
import { UsersService } from './users.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { AssignRolesDto } from './dto/assign-roles.dto';
import { UserQueryDto } from './dto/user-query.dto';
import { UserEntity } from './entities/user.entity';
import { RoleEntity } from './entities/role.entity';
import { PermissionEntity } from './entities/permission.entity';
import { PaginatedResult } from '../../common/pagination/pagination.dto';

@ApiTags('Users, Roles & Permissions')
@ApiBearerAuth()
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  @ApiOperation({ summary: 'List all farm users with pagination, sorting and filters' })
  @ApiResponse({ status: 200, description: 'Paginated user list returned' })
  @UsePipes(new ValidationPipe({ transform: true }))
  async findAll(@Query() query: UserQueryDto): Promise<PaginatedResult<UserEntity>> {
    return this.usersService.findAll(query);
  }

  @Get('roles')
  @ApiOperation({ summary: 'List all available system roles with mapped permissions' })
  @ApiResponse({ status: 200, description: 'Role definitions list returned', type: [RoleEntity] })
  async getRoles(): Promise<RoleEntity[]> {
    return this.usersService.getAllRoles();
  }

  @Get('permissions')
  @ApiOperation({ summary: 'List all granular security permissions' })
  @ApiResponse({ status: 200, description: 'Permissions list returned', type: [PermissionEntity] })
  async getPermissions(): Promise<PermissionEntity[]> {
    return this.usersService.getAllPermissions();
  }

  @Get(':id')
  @ApiOperation({ summary: 'Retrieve user details and assigned roles by ID' })
  @ApiParam({ name: 'id', description: 'User UUID' })
  @ApiResponse({ status: 200, description: 'User record found', type: UserEntity })
  @ApiResponse({ status: 404, description: 'User not found' })
  async findById(@Param('id') id: string): Promise<UserEntity> {
    return this.usersService.findById(id);
  }

  @Post()
  @ApiOperation({ summary: 'Create a new farm staff user account' })
  @ApiResponse({ status: 201, description: 'User successfully created', type: UserEntity })
  @ApiResponse({ status: 409, description: 'Email address already in use' })
  @UsePipes(new ValidationPipe({ transform: true, whitelist: true }))
  async create(@Body() dto: CreateUserDto): Promise<UserEntity> {
    return this.usersService.createUser(dto);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update an existing user profile or credentials' })
  @ApiParam({ name: 'id', description: 'User UUID' })
  @ApiResponse({ status: 200, description: 'User successfully updated', type: UserEntity })
  @ApiResponse({ status: 404, description: 'User not found' })
  @UsePipes(new ValidationPipe({ transform: true, whitelist: true }))
  async update(
    @Param('id') id: string,
    @Body() dto: UpdateUserDto,
  ): Promise<UserEntity> {
    return this.usersService.updateUser(id, dto);
  }

  @Post(':id/roles')
  @ApiOperation({ summary: 'Assign or replace role assignments for a user' })
  @ApiParam({ name: 'id', description: 'User UUID' })
  @ApiResponse({ status: 200, description: 'Roles updated for user', type: UserEntity })
  @UsePipes(new ValidationPipe({ transform: true, whitelist: true }))
  async assignRoles(
    @Param('id') id: string,
    @Body() dto: AssignRolesDto,
  ): Promise<UserEntity> {
    return this.usersService.assignRoles(id, dto);
  }
}
