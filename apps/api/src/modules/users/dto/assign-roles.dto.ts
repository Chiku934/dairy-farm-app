import { IsArray, IsNotEmpty, IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class AssignRolesDto {
  @ApiProperty({
    example: ['role-01', 'role-02'],
    description: 'Array of Role IDs to associate with this user',
  })
  @IsArray()
  @IsNotEmpty()
  @IsString({ each: true })
  roleIds: string[];
}
