import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';

@ApiTags('Health & Diagnostics')
@Controller('health')
export class HealthController {
  @Get()
  @ApiOperation({ summary: 'Liveness & readiness probe' })
  @ApiResponse({ status: 200, description: 'Application is operational' })
  check() {
    return {
      status: 'ok',
      service: 'dairy-farm-api',
      timestamp: new Date().toISOString(),
      uptimeSeconds: Math.floor(process.uptime()),
    };
  }
}
