import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { PERMISSIONS_KEY } from '../decorators/permissions.decorator';
import { AuthenticatedUser } from '../decorators/current-user.decorator';

@Injectable()
export class PermissionsGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredPermissions = this.reflector.getAllAndOverride<string[]>(
      PERMISSIONS_KEY,
      [context.getHandler(), context.getClass()],
    );

    if (!requiredPermissions || requiredPermissions.length === 0) {
      return true;
    }

    const { user } = context.switchToHttp().getRequest() as {
      user?: AuthenticatedUser;
    };

    if (!user || !user.permissions) {
      throw new ForbiddenException('Access denied: insufficient permissions');
    }

    // Super Admin / FARM_OWNER has global wildcard access
    if (user.roles?.includes('FARM_OWNER') || user.roles?.includes('SUPER_ADMIN')) {
      return true;
    }

    const hasPermission = requiredPermissions.every((perm) =>
      user.permissions.includes(perm),
    );

    if (!hasPermission) {
      throw new ForbiddenException(
        `Access denied: required permission(s) (${requiredPermissions.join(', ')})`,
      );
    }

    return true;
  }
}
