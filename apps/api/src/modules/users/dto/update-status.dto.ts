import { IsBoolean } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class UpdateUserStatusDto {
  @ApiProperty({
    example: false,
    description: 'Set to false to deactivate account (immediately revoking active sessions), or true to reactivate',
  })
  @IsBoolean()
  isActive: boolean;
}
