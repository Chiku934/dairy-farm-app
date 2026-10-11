import { SetMetadata } from '@nestjs/common';

export interface RateLimitOptions {
  ttlSeconds: number;
  maxRequests: number;
}

export const RATE_LIMIT_KEY = 'rate_limit';
export const RateLimit = (options: RateLimitOptions) =>
  SetMetadata(RATE_LIMIT_KEY, options);
