import {
  Controller,
  Get,
  Query,
  UsePipes,
  ValidationPipe,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { AuditService } from './audit.service';
import { AuditQueryDto } from './dto/audit-query.dto';
import { AuditLogEntity } from './entities/audit-log.entity';
import { PaginatedResult } from '../../common/pagination/pagination.dto';

@ApiTags('Audit Logs & Compliance')
@ApiBearerAuth()
@Controller('audit-logs')
export class AuditController {
  constructor(private readonly auditService: AuditService) {}

  @Get()
  @ApiOperation({ summary: 'Retrieve paginated system audit trails and compliance events' })
  @ApiResponse({ status: 200, description: 'Paginated audit logs returned' })
  @UsePipes(new ValidationPipe({ transform: true }))
  async findAll(
    @Query() query: AuditQueryDto,
  ): Promise<PaginatedResult<AuditLogEntity>> {
    return this.auditService.findAll(query);
  }
}
