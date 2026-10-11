import {
  Injectable,
  CanActivate,
  ExecutionContext,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { RATE_LIMIT_KEY, RateLimitOptions } from '../decorators/rate-limit.decorator';

interface ClientTracker {
  count: number;
  resetTime: number;
}

@Injectable()
export class RateLimitGuard implements CanActivate {
  private static clientMap: Map<string, ClientTracker> = new Map();

  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const options = this.reflector.getAllAndOverride<RateLimitOptions>(
      RATE_LIMIT_KEY,
      [context.getHandler(), context.getClass()],
    );

    if (!options) {
      return true; // No rate limit specified for this endpoint
    }

    const request = context.switchToHttp().getRequest();
    const ip =
      request.ip ||
      request.headers['x-forwarded-for'] ||
      request.socket.remoteAddress ||
      'unknown-client';
    const key = `${ip}:${request.method}:${request.path}`;

    const now = Date.now();
    const tracker = RateLimitGuard.clientMap.get(key);

    if (!tracker || now > tracker.resetTime) {
      // New window
      RateLimitGuard.clientMap.set(key, {
        count: 1,
        resetTime: now + options.ttlSeconds * 1000,
      });
      return true;
    }

    if (tracker.count >= options.maxRequests) {
      const retryAfterSeconds = Math.ceil((tracker.resetTime - now) / 1000);
      throw new HttpException(
        {
          statusCode: HttpStatus.TOO_MANY_REQUESTS,
          error: 'Too Many Requests',
          message: `Too many attempts. Rate limit exceeded. Please retry after ${retryAfterSeconds} seconds.`,
        },
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    tracker.count += 1;
    return true;
  }

  // Method to clear tracking map (useful for test isolation)
  static resetTrackers(): void {
    RateLimitGuard.clientMap.clear();
  }
}
