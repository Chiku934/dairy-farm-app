import { IsNotEmpty, IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class RefreshTokenDto {
  @ApiProperty({ description: 'The long-lived refresh token provided at login' })
  @IsString()
  @IsNotEmpty()
  refreshToken: string;
}
