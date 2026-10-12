import {
  IsString,
  IsNotEmpty,
  IsEnum,
  IsDateString,
  IsOptional,
  IsNumber,
  Min,
  IsBoolean,
  IsEmail,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Department, EmploymentStatus } from '@dairy-farm/api-contracts';

export class CreateEmployeeDto {
  @ApiProperty({ example: 'EMP-1001', description: 'Unique employee code' })
  @IsString()
  @IsNotEmpty()
  employeeCode: string;

  @ApiProperty({ example: 'Ramesh Patel', description: 'Employee full name' })
  @IsString()
  @IsNotEmpty()
  fullName: string;

  @ApiProperty({ enum: Department, example: Department.FARM })
  @IsEnum(Department)
  department: Department;

  @ApiProperty({ example: 'Herd Manager', description: 'Designation / job title' })
  @IsString()
  @IsNotEmpty()
  jobTitle: string;

  @ApiProperty({ example: '2025-01-15', description: 'Joining date (YYYY-MM-DD)' })
  @IsDateString()
  joiningDate: string;

  @ApiPropertyOptional({ example: '2026-06-30', description: 'Leaving date (YYYY-MM-DD)' })
  @IsOptional()
  @IsDateString()
  leavingDate?: string;

  @ApiProperty({ example: 36000.00, description: 'Approved monthly salary' })
  @IsNumber()
  @Min(0)
  monthlySalary: number;

  @ApiPropertyOptional({ enum: EmploymentStatus, default: EmploymentStatus.ACTIVE })
  @IsOptional()
  @IsEnum(EmploymentStatus)
  status?: EmploymentStatus;

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @ApiPropertyOptional({ example: '+919876543210' })
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiPropertyOptional({ example: 'ramesh.patel@dairyfarm.com' })
  @IsOptional()
  @IsEmail()
  email?: string;

  @ApiPropertyOptional({ example: 'Experienced dairy herd specialist' })
  @IsOptional()
  @IsString()
  notes?: string;
}
