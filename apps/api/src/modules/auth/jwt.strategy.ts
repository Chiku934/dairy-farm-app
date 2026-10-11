import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { UsersService } from '../users/users.service';

export interface JwtPayload {
  sub: string;
  email: string;
  roles: string[];
  permissions: string[];
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(private readonly usersService: UsersService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: process.env.JWT_SECRET || 'dairy-farm-super-secret-key-change-in-prod',
    });
  }

  async validate(payload: JwtPayload) {
    const user = await this.usersService.findById(payload.sub);
    if (!user || !user.isActive) {
      throw new UnauthorizedException('User is inactive or no longer exists');
    }

    const roles = user.roles.map((r) => r.code);
    const permissions = Array.from(
      new Set(
        user.roles.flatMap((r) => (r.permissions || []).map((p) => p.code)),
      ),
    );

    return {
      userId: user.id,
      email: user.email,
      fullName: user.fullName,
      roles,
      permissions,
    };
  }
}
