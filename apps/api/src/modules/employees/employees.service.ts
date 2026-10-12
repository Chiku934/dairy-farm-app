import {
  Injectable,
  NotFoundException,
  ConflictException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import { EmployeeEntity } from './entities/employee.entity';
import { CreateEmployeeDto } from './dto/create-employee.dto';
import { UpdateEmployeeDto } from './dto/update-employee.dto';
import { EmployeeQueryDto } from './dto/employee-query.dto';
import { AuditService } from '../audit/audit.service';
import { AuthenticatedUser } from '../../common/decorators/current-user.decorator';
import { EmploymentStatus } from '@dairy-farm/api-contracts';

const SALARY_AUTHORIZED_ROLES = ['FARM_OWNER', 'SUPER_ADMIN', 'HR_ADMIN', 'ACCOUNTANT'];

@Injectable()
export class EmployeesService {
  private readonly logger = new Logger(EmployeesService.name);

  constructor(
    @InjectRepository(EmployeeEntity)
    private readonly employeeRepo: Repository<EmployeeEntity>,
    private readonly auditService: AuditService,
  ) {}

  /**
   * Evaluates if caller has HR or Finance clearance to view sensitive salary figures.
   */
  hasSalaryClearance(user?: AuthenticatedUser): boolean {
    if (!user) return false;
    if (user.roles?.includes('FARM_OWNER') || user.roles?.includes('SUPER_ADMIN')) {
      return true;
    }
    return user.roles?.some((role) => SALARY_AUTHORIZED_ROLES.includes(role)) ?? false;
  }

  /**
   * Strips salary information for callers lacking HR or Finance clearance.
   */
  redactSalaryFields(employee: EmployeeEntity, user?: AuthenticatedUser): EmployeeEntity {
    if (this.hasSalaryClearance(user)) {
      return employee;
    }
    return {
      ...employee,
      monthlySalary: null,
      dailySalaryRate: null,
    };
  }

  private sanitizeForAudit(data: Record<string, any> | null): Record<string, any> | null {
    if (!data) return null;
    const sanitized = { ...data };
    if ('monthlySalary' in sanitized || 'monthly_salary' in sanitized) {
      sanitized.monthlySalary = '[REDACTED]';
      delete sanitized.monthly_salary;
    }
    if ('dailySalaryRate' in sanitized || 'daily_salary_rate' in sanitized) {
      sanitized.dailySalaryRate = '[REDACTED]';
      delete sanitized.daily_salary_rate;
    }
    return sanitized;
  }

  private validateDates(joiningDate: string, leavingDate?: string | null): void {
    const today = new Date().toISOString().slice(0, 10);
    if (joiningDate > today) {
      throw new BadRequestException('joining_date cannot be in the future');
    }
    if (leavingDate && leavingDate < joiningDate) {
      throw new BadRequestException('leaving_date must be on or after joining_date');
    }
  }

  async create(dto: CreateEmployeeDto, user?: AuthenticatedUser): Promise<EmployeeEntity> {
    this.validateDates(dto.joiningDate, dto.leavingDate);

    const existingCode = await this.employeeRepo.findOne({
      where: { employeeCode: dto.employeeCode },
    });
    if (existingCode) {
      throw new ConflictException(`Employee code ${dto.employeeCode} already exists`);
    }

    const employee = this.employeeRepo.create({
      id: uuidv4(),
      employeeCode: dto.employeeCode,
      fullName: dto.fullName,
      department: dto.department,
      jobTitle: dto.jobTitle,
      joiningDate: dto.joiningDate,
      leavingDate: dto.leavingDate || null,
      monthlySalary: dto.monthlySalary,
      isActive: dto.isActive !== undefined ? dto.isActive : true,
      status: dto.status || EmploymentStatus.ACTIVE,
      phone: dto.phone || null,
      email: dto.email || null,
      notes: dto.notes || null,
    });

    const saved = await this.employeeRepo.save(employee);

    // Reload to obtain stored generated daily_salary_rate
    const loaded = await this.employeeRepo.findOne({ where: { id: saved.id } });
    const finalRecord = loaded || saved;

    // Secure audit log without exposing salary amounts in plaintext
    await this.auditService.logAction({
      userId: user?.userId,
      action: 'CREATE_EMPLOYEE',
      entityType: 'EMPLOYEE',
      entityId: finalRecord.id,
      newValues: this.sanitizeForAudit({
        employeeCode: finalRecord.employeeCode,
        fullName: finalRecord.fullName,
        department: finalRecord.department,
        jobTitle: finalRecord.jobTitle,
        joiningDate: finalRecord.joiningDate,
        monthlySalary: finalRecord.monthlySalary,
        dailySalaryRate: finalRecord.dailySalaryRate,
        status: finalRecord.status,
      }),
    });

    this.logger.log(`Created employee profile ${finalRecord.employeeCode}`);
    return this.redactSalaryFields(finalRecord, user);
  }

  async findAll(
    query: EmployeeQueryDto,
    user?: AuthenticatedUser,
  ): Promise<{ data: EmployeeEntity[]; total: number; page: number; limit: number }> {
    const qb = this.employeeRepo.createQueryBuilder('employee');

    if (query.department) {
      qb.andWhere('employee.department = :department', { department: query.department });
    }

    if (query.status) {
      qb.andWhere('employee.status = :status', { status: query.status });
    }

    if (query.isActive !== undefined) {
      qb.andWhere('employee.is_active = :isActive', { isActive: query.isActive });
    }

    if (query.search) {
      qb.andWhere(
        '(employee.employee_code LIKE :search OR employee.full_name LIKE :search OR employee.job_title LIKE :search OR employee.phone LIKE :search OR employee.email LIKE :search)',
        { search: `%${query.search}%` },
      );
    }

    qb.orderBy('employee.createdAt', 'DESC');

    const page = query.page || 1;
    const limit = query.limit || 20;
    qb.skip((page - 1) * limit).take(limit);

    const [items, total] = await qb.getManyAndCount();

    const data = items.map((emp) => this.redactSalaryFields(emp, user));

    return { data, total, page, limit };
  }

  async findOne(id: string, user?: AuthenticatedUser): Promise<EmployeeEntity> {
    const employee = await this.employeeRepo.findOne({ where: { id } });
    if (!employee) {
      throw new NotFoundException(`Employee with ID ${id} not found`);
    }
    return this.redactSalaryFields(employee, user);
  }

  async update(
    id: string,
    dto: UpdateEmployeeDto,
    user?: AuthenticatedUser,
  ): Promise<EmployeeEntity> {
    const employee = await this.employeeRepo.findOne({ where: { id } });
    if (!employee) {
      throw new NotFoundException(`Employee with ID ${id} not found`);
    }

    const joiningDate = dto.joiningDate || employee.joiningDate;
    const leavingDate = dto.leavingDate !== undefined ? dto.leavingDate : employee.leavingDate;
    this.validateDates(joiningDate, leavingDate);

    if (dto.employeeCode && dto.employeeCode !== employee.employeeCode) {
      const existing = await this.employeeRepo.findOne({
        where: { employeeCode: dto.employeeCode },
      });
      if (existing) {
        throw new ConflictException(`Employee code ${dto.employeeCode} already exists`);
      }
      employee.employeeCode = dto.employeeCode;
    }

    const oldValues = {
      employeeCode: employee.employeeCode,
      fullName: employee.fullName,
      jobTitle: employee.jobTitle,
      monthlySalary: employee.monthlySalary,
      status: employee.status,
    };

    if (dto.fullName !== undefined) employee.fullName = dto.fullName;
    if (dto.department !== undefined) employee.department = dto.department;
    if (dto.jobTitle !== undefined) employee.jobTitle = dto.jobTitle;
    if (dto.joiningDate !== undefined) employee.joiningDate = dto.joiningDate;
    if (dto.leavingDate !== undefined) employee.leavingDate = dto.leavingDate || null;
    if (dto.monthlySalary !== undefined) employee.monthlySalary = dto.monthlySalary;
    if (dto.status !== undefined) employee.status = dto.status;
    if (dto.isActive !== undefined) employee.isActive = dto.isActive;
    if (dto.phone !== undefined) employee.phone = dto.phone || null;
    if (dto.email !== undefined) employee.email = dto.email || null;
    if (dto.notes !== undefined) employee.notes = dto.notes || null;

    const saved = await this.employeeRepo.save(employee);
    const updated = (await this.employeeRepo.findOne({ where: { id } })) || saved;

    await this.auditService.logAction({
      userId: user?.userId,
      action: 'UPDATE_EMPLOYEE',
      entityType: 'EMPLOYEE',
      entityId: employee.id,
      oldValues: this.sanitizeForAudit(oldValues),
      newValues: this.sanitizeForAudit({
        employeeCode: updated.employeeCode,
        fullName: updated.fullName,
        jobTitle: updated.jobTitle,
        monthlySalary: updated.monthlySalary,
        status: updated.status,
      }),
    });

    this.logger.log(`Updated employee profile ${updated.employeeCode}`);
    return this.redactSalaryFields(updated, user);
  }

  async remove(id: string, user?: AuthenticatedUser): Promise<{ message: string }> {
    const employee = await this.employeeRepo.findOne({ where: { id } });
    if (!employee) {
      throw new NotFoundException(`Employee with ID ${id} not found`);
    }

    employee.isActive = false;
    employee.status = EmploymentStatus.TERMINATED;
    if (!employee.leavingDate) {
      employee.leavingDate = new Date().toISOString().slice(0, 10);
    }
    await this.employeeRepo.save(employee);

    await this.auditService.logAction({
      userId: user?.userId,
      action: 'DEACTIVATE_EMPLOYEE',
      entityType: 'EMPLOYEE',
      entityId: employee.id,
      newValues: {
        employeeCode: employee.employeeCode,
        status: employee.status,
        isActive: employee.isActive,
        leavingDate: employee.leavingDate,
      },
    });

    return { message: `Employee ${employee.employeeCode} successfully deactivated` };
  }
}
