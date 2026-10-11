import {
  Injectable,
  NotFoundException,
  ConflictException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource, In } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { v4 as uuidv4 } from 'uuid';
import { UserEntity } from './entities/user.entity';
import { RoleEntity } from './entities/role.entity';
import { PermissionEntity } from './entities/permission.entity';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { AssignRolesDto } from './dto/assign-roles.dto';
import { UserQueryDto } from './dto/user-query.dto';
import { paginateQuery } from '../../common/pagination/paginate.util';
import { PaginatedResult } from '../../common/pagination/pagination.dto';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(UserEntity)
    private readonly userRepo: Repository<UserEntity>,
    @InjectRepository(RoleEntity)
    private readonly roleRepo: Repository<RoleEntity>,
    @InjectRepository(PermissionEntity)
    private readonly permissionRepo: Repository<PermissionEntity>,
    private readonly dataSource: DataSource,
  ) {}

  async findAll(query: UserQueryDto): Promise<PaginatedResult<UserEntity>> {
    const qb = this.userRepo
      .createQueryBuilder('user')
      .leftJoinAndSelect('user.roles', 'role')
      .leftJoinAndSelect('role.permissions', 'permission');

    if (query.search) {
      qb.andWhere(
        '(user.fullName LIKE :search OR user.email LIKE :search OR user.phone LIKE :search)',
        { search: `%${query.search}%` },
      );
    }

    if (query.isActive !== undefined) {
      qb.andWhere('user.isActive = :isActive', { isActive: query.isActive });
    }

    if (query.roleCode) {
      qb.andWhere('role.code = :roleCode', { roleCode: query.roleCode });
    }

    const sortField = query.sortBy || 'createdAt';
    const sortOrder = query.sortOrder || 'DESC';
    qb.orderBy(`user.${sortField}`, sortOrder);

    return paginateQuery(qb, query);
  }

  async findById(id: string): Promise<UserEntity> {
    const user = await this.userRepo
      .createQueryBuilder('user')
      .leftJoinAndSelect('user.roles', 'role')
      .leftJoinAndSelect('role.permissions', 'permission')
      .where('user.id = :id', { id })
      .getOne();

    if (!user) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }

    return user;
  }

  async findByEmail(email: string, includePassword = false): Promise<UserEntity | null> {
    const qb = this.userRepo
      .createQueryBuilder('user')
      .leftJoinAndSelect('user.roles', 'role')
      .leftJoinAndSelect('role.permissions', 'permission')
      .where('user.email = :email', { email });

    if (includePassword) {
      qb.addSelect('user.passwordHash');
    }

    return qb.getOne();
  }

  async createUser(dto: CreateUserDto): Promise<UserEntity> {
    const existing = await this.userRepo.findOne({ where: { email: dto.email } });
    if (existing) {
      throw new ConflictException(`User with email ${dto.email} already exists`);
    }

    // Execute in a database transaction
    return this.dataSource.transaction(async (manager) => {
      const passwordHash = await bcrypt.hash(dto.password, 10);
      const userId = uuidv4();

      let roles: RoleEntity[] = [];
      if (dto.roleIds && dto.roleIds.length > 0) {
        roles = await manager.find(RoleEntity, {
          where: { id: In(dto.roleIds) },
        });
      }

      const user = manager.create(UserEntity, {
        id: userId,
        email: dto.email,
        passwordHash,
        fullName: dto.fullName,
        phone: dto.phone || null,
        isActive: true,
        roles,
      });

      return manager.save(UserEntity, user);
    });
  }

  async updateUser(id: string, dto: UpdateUserDto): Promise<UserEntity> {
    const user = await this.findById(id);

    if (dto.email && dto.email !== user.email) {
      const existing = await this.userRepo.findOne({ where: { email: dto.email } });
      if (existing) {
        throw new ConflictException(`Email ${dto.email} is already in use`);
      }
      user.email = dto.email;
    }

    if (dto.fullName) user.fullName = dto.fullName;
    if (dto.phone !== undefined) user.phone = dto.phone;
    if (dto.isActive !== undefined) user.isActive = dto.isActive;

    if (dto.password) {
      user.passwordHash = await bcrypt.hash(dto.password, 10);
    }

    return this.userRepo.save(user);
  }

  async assignRoles(id: string, dto: AssignRolesDto): Promise<UserEntity> {
    return this.dataSource.transaction(async (manager) => {
      const user = await manager.findOne(UserEntity, {
        where: { id },
        relations: ['roles'],
      });
      if (!user) {
        throw new NotFoundException(`User with ID ${id} not found`);
      }

      const roles = await manager.find(RoleEntity, {
        where: { id: In(dto.roleIds) },
      });

      user.roles = roles;
      await manager.save(UserEntity, user);

      return manager.findOneOrFail(UserEntity, {
        where: { id },
        relations: ['roles', 'roles.permissions'],
      });
    });
  }

  async getAllRoles(): Promise<RoleEntity[]> {
    return this.roleRepo.find({
      relations: ['permissions'],
      order: { name: 'ASC' },
    });
  }

  async getAllPermissions(): Promise<PermissionEntity[]> {
    return this.permissionRepo.find({
      order: { module: 'ASC', code: 'ASC' },
    });
  }
}
