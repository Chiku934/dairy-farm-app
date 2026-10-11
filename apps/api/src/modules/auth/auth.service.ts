import {
  Injectable,
  UnauthorizedException,
  BadRequestException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource, MoreThan } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { v4 as uuidv4 } from 'uuid';
import { UsersService } from '../users/users.service';
import { UserSessionEntity } from './entities/user-session.entity';
import { LoginDto } from './dto/login.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';

export interface AuthResponse {
  accessToken: string;
  refreshToken: string;
  tokenType: string;
  expiresInSeconds: number;
  user: {
    id: string;
    email: string;
    fullName: string;
    roles: string[];
    permissions: string[];
  };
}

@Injectable()
export class AuthService {
  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
    @InjectRepository(UserSessionEntity)
    private readonly sessionRepo: Repository<UserSessionEntity>,
    private readonly dataSource: DataSource,
  ) {}

  async login(
    dto: LoginDto,
    ipAddress?: string,
    userAgent?: string,
  ): Promise<AuthResponse> {
    const user = await this.usersService.findByEmail(dto.email, true);
    if (!user || !user.isActive) {
      throw new UnauthorizedException('Invalid email or password');
    }

    const isMatch = await bcrypt.compare(dto.password, user.passwordHash);
    if (!isMatch) {
      throw new UnauthorizedException('Invalid email or password');
    }

    const roles = (user.roles || []).map((r) => r.code);
    const permissions = Array.from(
      new Set(
        (user.roles || []).flatMap((r) =>
          (r.permissions || []).map((p) => p.code),
        ),
      ),
    );

    const payload = {
      sub: user.id,
      email: user.email,
      roles,
      permissions,
    };

    const accessToken = this.jwtService.sign(payload, { expiresIn: '1h' });
    const rawRefreshToken = uuidv4();
    const refreshTokenHash = await bcrypt.hash(rawRefreshToken, 10);

    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 30); // 30 days validity

    // Save session in database transaction
    await this.dataSource.transaction(async (manager) => {
      const session = manager.create(UserSessionEntity, {
        id: uuidv4(),
        userId: user.id,
        refreshTokenHash,
        ipAddress: ipAddress || null,
        userAgent: userAgent ? userAgent.substring(0, 255) : null,
        isRevoked: false,
        expiresAt,
      });
      await manager.save(UserSessionEntity, session);
    });

    return {
      accessToken,
      refreshToken: rawRefreshToken,
      tokenType: 'Bearer',
      expiresInSeconds: 3600,
      user: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        roles,
        permissions,
      },
    };
  }

  async refreshToken(
    dto: RefreshTokenDto,
    ipAddress?: string,
    userAgent?: string,
  ): Promise<AuthResponse> {
    // Find unrevoked active sessions not expired
    const activeSessions = await this.sessionRepo.find({
      where: {
        isRevoked: false,
        expiresAt: MoreThan(new Date()),
      },
      relations: ['user', 'user.roles', 'user.roles.permissions'],
    });

    let matchedSession: UserSessionEntity | null = null;
    for (const session of activeSessions) {
      const match = await bcrypt.compare(
        dto.refreshToken,
        session.refreshTokenHash,
      );
      if (match) {
        matchedSession = session;
        break;
      }
    }

    if (!matchedSession || !matchedSession.user || !matchedSession.user.isActive) {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }

    const user = matchedSession.user;
    const roles = (user.roles || []).map((r) => r.code);
    const permissions = Array.from(
      new Set(
        (user.roles || []).flatMap((r) =>
          (r.permissions || []).map((p) => p.code),
        ),
      ),
    );

    const payload = {
      sub: user.id,
      email: user.email,
      roles,
      permissions,
    };

    const newAccessToken = this.jwtService.sign(payload, { expiresIn: '1h' });
    const newRawRefreshToken = uuidv4();
    const newRefreshTokenHash = await bcrypt.hash(newRawRefreshToken, 10);

    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 30);

    // Revoke old session and issue new session atomically in transaction
    await this.dataSource.transaction(async (manager) => {
      matchedSession!.isRevoked = true;
      await manager.save(UserSessionEntity, matchedSession!);

      const newSession = manager.create(UserSessionEntity, {
        id: uuidv4(),
        userId: user.id,
        refreshTokenHash: newRefreshTokenHash,
        ipAddress: ipAddress || null,
        userAgent: userAgent ? userAgent.substring(0, 255) : null,
        isRevoked: false,
        expiresAt,
      });
      await manager.save(UserSessionEntity, newSession);
    });

    return {
      accessToken: newAccessToken,
      refreshToken: newRawRefreshToken,
      tokenType: 'Bearer',
      expiresInSeconds: 3600,
      user: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        roles,
        permissions,
      },
    };
  }

  async logout(userId: string, refreshToken?: string): Promise<{ success: boolean }> {
    if (refreshToken) {
      const activeSessions = await this.sessionRepo.find({
        where: { userId, isRevoked: false },
      });
      for (const session of activeSessions) {
        const match = await bcrypt.compare(
          refreshToken,
          session.refreshTokenHash,
        );
        if (match) {
          session.isRevoked = true;
          await this.sessionRepo.save(session);
          break;
        }
      }
    } else {
      // Revoke all sessions for this user
      await this.sessionRepo.update({ userId, isRevoked: false }, { isRevoked: true });
    }
    return { success: true };
  }
}
