import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { ExpensesService } from './expenses.service';
import { CreateExpenseDto } from './dto/create-expense.dto';
import { ExpenseQueryDto } from './dto/expense-query.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '../../common/guards/permissions.guard';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { CurrentUser, AuthenticatedUser } from '../../common/decorators/current-user.decorator';

@ApiTags('Costs & Expenses')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('expenses')
export class ExpensesController {
  constructor(private readonly expensesService: ExpensesService) {}

  @Post()
  @RequirePermissions('finance:write')
  @ApiOperation({ summary: 'Record operational cost or expense voucher' })
  async createExpense(
    @Body() dto: CreateExpenseDto,
    @CurrentUser() user?: AuthenticatedUser,
  ) {
    return await this.expensesService.createExpense(dto, user?.userId);
  }

  @Get()
  @RequirePermissions('finance:read')
  @ApiOperation({ summary: 'List operating expenses with cost centre KPI summaries' })
  async findAll(@Query() query: ExpenseQueryDto) {
    return await this.expensesService.findAll(query);
  }

  @Get(':id')
  @RequirePermissions('finance:read')
  @ApiOperation({ summary: 'Get single operating expense details' })
  async findOne(@Param('id') id: string) {
    return await this.expensesService.findOne(id);
  }
}
