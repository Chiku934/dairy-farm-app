import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { InventoryService } from './inventory.service';
import { CreateStockItemDto } from './dto/create-stock-item.dto';
import { CreateStockReceiptDto } from './dto/create-stock-receipt.dto';
import { CreateSupplierDto } from './dto/create-supplier.dto';
import { InventoryQueryDto } from './dto/inventory-query.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '../../common/guards/permissions.guard';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { CurrentUser, AuthenticatedUser } from '../../common/decorators/current-user.decorator';

@Controller('inventory')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class InventoryController {
  constructor(private readonly inventoryService: InventoryService) {}

  @Get('items')
  @RequirePermissions('inventory:read')
  getItems(@Query() query: InventoryQueryDto) {
    return this.inventoryService.getItems(query);
  }

  @Get('items/:id')
  @RequirePermissions('inventory:read')
  getItemById(@Param('id') id: string) {
    return this.inventoryService.getItemById(id);
  }

  @Post('items')
  @RequirePermissions('inventory:write')
  createItem(
    @Body() dto: CreateStockItemDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.inventoryService.createItem(dto, user);
  }

  @Get('receipts')
  @RequirePermissions('inventory:read')
  getReceipts(
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.inventoryService.getReceipts(
      page ? parseInt(page, 10) : 1,
      limit ? parseInt(limit, 10) : 20,
    );
  }

  @Post('receipts')
  @RequirePermissions('inventory:write')
  createReceipt(
    @Body() dto: CreateStockReceiptDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.inventoryService.createReceipt(dto, user);
  }

  @Get('suppliers')
  @RequirePermissions('inventory:read')
  getSuppliers() {
    return this.inventoryService.getSuppliers();
  }

  @Post('suppliers')
  @RequirePermissions('inventory:write')
  createSupplier(
    @Body() dto: CreateSupplierDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.inventoryService.createSupplier(dto, user);
  }

  @Get('ledger')
  @RequirePermissions('inventory:read')
  getLedger(
    @Query('stockItemId') stockItemId?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.inventoryService.getLedger(
      stockItemId,
      page ? parseInt(page, 10) : 1,
      limit ? parseInt(limit, 10) : 25,
    );
  }
}
