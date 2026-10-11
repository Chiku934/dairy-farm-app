import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { SalesService } from './sales.service';
import { CreateCustomerDto } from './dto/create-customer.dto';
import { CreateSalesOrderDto } from './dto/create-sales-order.dto';
import { CreateSalesDispatchDto } from './dto/create-sales-dispatch.dto';
import { CreateCustomerPaymentDto } from './dto/create-customer-payment.dto';
import {
  SalesOrderQueryDto,
  SalesDispatchQueryDto,
  CustomerPaymentQueryDto,
} from './dto/sales-query.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '../../common/guards/permissions.guard';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { CurrentUser, AuthenticatedUser } from '../../common/decorators/current-user.decorator';

@Controller('sales')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class SalesController {
  constructor(private readonly salesService: SalesService) {}

  // --------------------------------------------------------------------------
  // Customers
  // --------------------------------------------------------------------------
  @Get('customers')
  @RequirePermissions('sales:read')
  getCustomers() {
    return this.salesService.getCustomers();
  }

  @Get('customers/:id')
  @RequirePermissions('sales:read')
  getCustomerById(@Param('id') id: string) {
    return this.salesService.getCustomerById(id);
  }

  @Post('customers')
  @RequirePermissions('sales:write')
  createCustomer(
    @Body() dto: CreateCustomerDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.salesService.createCustomer(dto, user);
  }

  // --------------------------------------------------------------------------
  // Sales Orders
  // --------------------------------------------------------------------------
  @Get('orders')
  @RequirePermissions('sales:read')
  getOrders(@Query() query: SalesOrderQueryDto) {
    return this.salesService.getOrders(query);
  }

  @Get('orders/:id')
  @RequirePermissions('sales:read')
  getOrderById(@Param('id') id: string) {
    return this.salesService.getOrderById(id);
  }

  @Post('orders')
  @RequirePermissions('sales:write')
  createOrder(
    @Body() dto: CreateSalesOrderDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.salesService.createOrder(dto, user);
  }

  @Post('orders/:id/cancel')
  @RequirePermissions('sales:write')
  cancelOrder(
    @Param('id') id: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.salesService.cancelOrder(id, user);
  }

  // --------------------------------------------------------------------------
  // Sales Dispatches
  // --------------------------------------------------------------------------
  @Get('dispatches')
  @RequirePermissions('sales:read')
  getDispatches(@Query() query: SalesDispatchQueryDto) {
    return this.salesService.getDispatches(query);
  }

  @Get('dispatches/:id')
  @RequirePermissions('sales:read')
  getDispatchById(@Param('id') id: string) {
    return this.salesService.getDispatchById(id);
  }

  @Post('dispatches')
  @RequirePermissions('sales:write')
  createDispatch(
    @Body() dto: CreateSalesDispatchDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.salesService.createDispatch(dto, user);
  }

  // --------------------------------------------------------------------------
  // Customer Payments
  // --------------------------------------------------------------------------
  @Get('payments')
  @RequirePermissions('sales:read')
  getPayments(@Query() query: CustomerPaymentQueryDto) {
    return this.salesService.getPayments(query);
  }

  @Post('payments')
  @RequirePermissions('sales:write')
  createPayment(
    @Body() dto: CreateCustomerPaymentDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.salesService.createPayment(dto, user);
  }
}
