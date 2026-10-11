import {
  Controller,
  Post,
  Get,
  Body,
  Req,
  UseGuards,
  UsePipes,
  ValidationPipe,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { Request } from 'express';
import { AuthService, AuthResponse } from './auth.service';
import { LoginDto } from './dto/login.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { Public } from '../../common/decorators/public.decorator';
import { CurrentUser, AuthenticatedUser } from '../../common/decorators/current-user.decorator';

@ApiTags('Authentication & Sessions')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Public()
  @Post('login')
  @ApiOperation({ summary: 'Authenticate staff user with email and password' })
  @ApiResponse({ status: 200, description: 'Authentication successful with JWT and refresh token' })
  @ApiResponse({ status: 401, description: 'Invalid credentials or inactive user' })
  @UsePipes(new ValidationPipe({ transform: true, whitelist: true }))
  async login(
    @Body() dto: LoginDto,
    @Req() req: Request,
  ): Promise<AuthResponse> {
    const ip = req.ip || req.socket.remoteAddress;
    const userAgent = req.headers['user-agent'];
    return this.authService.login(dto, ip, userAgent);
  }

  @Public()
  @Post('refresh')
  @ApiOperation({ summary: 'Exchange a valid refresh token for a new access token' })
  @ApiResponse({ status: 200, description: 'Token refreshed successfully' })
  @ApiResponse({ status: 401, description: 'Refresh token invalid or expired' })
  @UsePipes(new ValidationPipe({ transform: true, whitelist: true }))
  async refresh(
    @Body() dto: RefreshTokenDto,
    @Req() req: Request,
  ): Promise<AuthResponse> {
    const ip = req.ip || req.socket.remoteAddress;
    const userAgent = req.headers['user-agent'];
    return this.authService.refreshToken(dto, ip, userAgent);
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Get('me')
  @ApiOperation({ summary: 'Get current authenticated user identity, roles and permissions' })
  @ApiResponse({ status: 200, description: 'Current user profile returned' })
  async me(@CurrentUser() user: AuthenticatedUser): Promise<AuthenticatedUser> {
    return user;
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Post('logout')
  @ApiOperation({ summary: 'Revoke active refresh tokens and sign out' })
  @ApiResponse({ status: 200, description: 'Session revoked successfully' })
  async logout(
    @CurrentUser('userId') userId: string,
    @Body() dto: Partial<RefreshTokenDto>,
  ): Promise<{ success: boolean }> {
    return this.authService.logout(userId, dto.refreshToken);
  }
}
