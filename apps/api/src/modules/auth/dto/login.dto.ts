import { IsEmail, IsNotEmpty, IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class LoginDto {
  @ApiProperty({ example: 'admin@dairyfarm.local', description: 'User login email' })
  @IsEmail()
  email: string;

  @ApiProperty({ example: 'Password@123', description: 'User account password' })
  @IsString()
  @IsNotEmpty()
  password: string;
}
