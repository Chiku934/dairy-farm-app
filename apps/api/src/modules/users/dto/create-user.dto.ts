import {
  IsEmail,
  IsNotEmpty,
  IsOptional,
  IsString,
  MinLength,
  IsArray,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateUserDto {
  @ApiProperty({ example: 'staff.kumar@kaivalyadairy.com' })
  @IsEmail()
  email: string;

  @ApiProperty({ example: 'SecurePassword@123', minLength: 8 })
  @IsString()
  @MinLength(8)
  password: string;

  @ApiProperty({ example: 'Ramesh Kumar' })
  @IsString()
  @IsNotEmpty()
  fullName: string;

  @ApiPropertyOptional({ example: '+91 9876543211' })
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiPropertyOptional({
    example: ['role-02'],
    description: 'Array of Role IDs to initially assign',
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  roleIds?: string[];
}
