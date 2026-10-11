import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { InventoryController } from './inventory.controller';
import { InventoryService } from './inventory.service';
import { StockItemEntity } from '../feed/entities/stock-item.entity';
import { StockReceiptEntity } from './entities/stock-receipt.entity';
import { StockLedgerEntryEntity } from './entities/stock-ledger-entry.entity';
import { SupplierEntity } from './entities/supplier.entity';
import { AuditModule } from '../audit/audit.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      StockItemEntity,
      StockReceiptEntity,
      StockLedgerEntryEntity,
      SupplierEntity,
    ]),
    AuditModule,
  ],
  controllers: [InventoryController],
  providers: [InventoryService],
  exports: [InventoryService],
})
export class InventoryModule {}
