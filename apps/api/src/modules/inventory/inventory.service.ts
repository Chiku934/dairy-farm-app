import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ConflictException,
} from '@nestjs/common';
import { DataSource } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import { StockTransactionType } from '@dairy-farm/api-contracts';
import { StockItemEntity } from '../feed/entities/stock-item.entity';
import { StockReceiptEntity } from './entities/stock-receipt.entity';
import { StockLedgerEntryEntity } from './entities/stock-ledger-entry.entity';
import { SupplierEntity } from './entities/supplier.entity';
import { CreateStockItemDto } from './dto/create-stock-item.dto';
import { CreateStockReceiptDto } from './dto/create-stock-receipt.dto';
import { CreateSupplierDto } from './dto/create-supplier.dto';
import { InventoryQueryDto } from './dto/inventory-query.dto';
import { AuditService } from '../audit/audit.service';
import { AuthenticatedUser } from '../../common/decorators/current-user.decorator';

@Injectable()
export class InventoryService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly auditService: AuditService,
  ) {}

  async getItems(query: InventoryQueryDto) {
    const page = Math.max(1, Number(query.page) || 1);
    const limit = Math.max(1, Math.min(100, Number(query.limit) || 20));
    const offset = (page - 1) * limit;

    const qb = this.dataSource
      .getRepository(StockItemEntity)
      .createQueryBuilder('item');

    if (query.category) {
      qb.andWhere('item.category = :category', { category: query.category });
    }

    if (query.usedBy) {
      qb.andWhere('(item.used_by = :usedBy OR item.used_by = "BOTH")', { usedBy: query.usedBy });
    }

    if (query.search) {
      qb.andWhere('LOWER(item.name) LIKE LOWER(:search)', { search: `%${query.search}%` });
    }

    if (query.lowStockOnly) {
      qb.andWhere('item.current_stock <= item.reorder_level');
    }

    qb.orderBy('item.name', 'ASC');

    const [items, total] = await qb.skip(offset).take(limit).getManyAndCount();

    const enhanced = items.map((item) => ({
      ...item,
      isLowStock: Number(item.current_stock) <= Number(item.reorder_level),
    }));

    return {
      items: enhanced,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async getItemById(id: string) {
    const item = await this.dataSource.getRepository(StockItemEntity).findOne({ where: { id } });
    if (!item) {
      throw new NotFoundException(`Stock item with ID "${id}" not found.`);
    }
    return {
      ...item,
      isLowStock: Number(item.current_stock) <= Number(item.reorder_level),
    };
  }

  async createItem(dto: CreateStockItemDto, user: AuthenticatedUser) {
    const existing = await this.dataSource
      .getRepository(StockItemEntity)
      .findOne({ where: { name: dto.name.trim() } });
    if (existing) {
      throw new ConflictException(`Stock item with name "${dto.name}" already exists.`);
    }

    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      const id = uuidv4();
      const initialStock = Math.round((Number(dto.initialStock) || 0) * 100) / 100;
      const initialPrice = Math.round((Number(dto.initialPrice) || 0) * 100) / 100;
      const reorderLevel = Math.round((Number(dto.reorderLevel) || 0) * 100) / 100;

      const item = queryRunner.manager.create(StockItemEntity, {
        id,
        name: dto.name.trim(),
        used_by: dto.usedBy,
        category: dto.category,
        unit: dto.unit.trim(),
        current_stock: initialStock,
        weighted_avg_price: initialPrice,
        reorder_level: reorderLevel,
        notes: dto.notes ? dto.notes.trim() : null,
      });

      await queryRunner.manager.save(item);

      if (initialStock > 0) {
        const ledgerEntry = queryRunner.manager.create(StockLedgerEntryEntity, {
          id: uuidv4(),
          stockItemId: id,
          recordDate: new Date().toISOString().split('T')[0],
          transactionType: StockTransactionType.RECEIPT,
          referenceId: 'INITIAL_STOCK',
          quantityChange: initialStock,
          balanceAfter: initialStock,
          unitCost: initialPrice,
          notes: 'Initial inventory balance setup',
        });
        await queryRunner.manager.save(ledgerEntry);
      }

      await queryRunner.commitTransaction();

      await this.auditService.logAction({
        userId: user?.userId,
        action: 'CREATE_STOCK_ITEM',
        entityType: 'STOCK_ITEM',
        entityId: id,
        newValues: { name: item.name, category: item.category, currentStock: initialStock },
      });

      return this.getItemById(id);
    } catch (err) {
      await queryRunner.rollbackTransaction();
      throw err;
    } finally {
      await queryRunner.release();
    }
  }

  async getReceipts(page = 1, limit = 20) {
    const offset = (page - 1) * limit;
    const [items, total] = await this.dataSource
      .getRepository(StockReceiptEntity)
      .createQueryBuilder('receipt')
      .orderBy('receipt.record_date', 'DESC')
      .addOrderBy('receipt.created_at', 'DESC')
      .skip(offset)
      .take(limit)
      .getManyAndCount();

    return {
      items,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async createReceipt(dto: CreateStockReceiptDto, user: AuthenticatedUser) {
    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      // 1. Pessimistic write lock on StockItem
      const stockItem = await queryRunner.manager
        .createQueryBuilder(StockItemEntity, 'item')
        .setLock('pessimistic_write')
        .where('item.id = :id', { id: dto.stockItemId })
        .getOne();

      if (!stockItem) {
        throw new NotFoundException(`Stock item with ID "${dto.stockItemId}" not found.`);
      }

      const receiptQty = Math.round(Number(dto.quantity) * 100) / 100;
      const unitPrice = Math.round(Number(dto.unitPrice) * 100) / 100;
      if (receiptQty <= 0 || unitPrice <= 0) {
        throw new BadRequestException('Quantity and unit price must be positive numbers.');
      }

      const totalCost = Math.round(receiptQty * unitPrice * 100) / 100;

      // 2. Resolve Supplier Info
      let supplierName = dto.supplierName?.trim() || null;
      if (dto.supplierId) {
        const supplier = await queryRunner.manager.findOne(SupplierEntity, {
          where: { id: dto.supplierId },
        });
        if (supplier) {
          supplierName = supplier.name;
        }
      }

      // 3. Generate Receipt Number
      const receiptNumber =
        dto.receiptNumber?.trim() ||
        `REC-${dto.recordDate.replace(/-/g, '')}-${Math.floor(1000 + Math.random() * 9000)}`;

      const existingReceipt = await queryRunner.manager.findOne(StockReceiptEntity, {
        where: { receiptNumber },
      });
      if (existingReceipt) {
        throw new ConflictException(`Stock receipt with number "${receiptNumber}" already exists.`);
      }

      // 4. Calculate Moving Weighted Average Cost (WAC)
      const currentStock = Number(stockItem.current_stock);
      const currentWac = Number(stockItem.weighted_avg_price);
      const newStock = Math.round((currentStock + receiptQty) * 100) / 100;

      let newWac: number;
      if (newStock > 0) {
        newWac = Math.round(((currentStock * currentWac + receiptQty * unitPrice) / newStock) * 100) / 100;
      } else {
        newWac = unitPrice;
      }

      // 5. Save Stock Receipt
      const receiptId = uuidv4();
      const receipt = queryRunner.manager.create(StockReceiptEntity, {
        id: receiptId,
        receiptNumber,
        recordDate: dto.recordDate,
        stockItemId: dto.stockItemId,
        supplierId: dto.supplierId || null,
        supplierName,
        supplierLot: dto.supplierLot ? dto.supplierLot.trim() : null,
        quantity: receiptQty,
        unitPrice,
        totalCost,
        expiryDate: dto.expiryDate || null,
        notes: dto.notes ? dto.notes.trim() : null,
        createdBy: user?.userId || null,
      });
      await queryRunner.manager.save(receipt);

      // 6. Double-entry Stock Ledger Entry
      const ledgerEntry = queryRunner.manager.create(StockLedgerEntryEntity, {
        id: uuidv4(),
        stockItemId: dto.stockItemId,
        recordDate: dto.recordDate,
        transactionType: StockTransactionType.RECEIPT,
        referenceId: receiptNumber,
        quantityChange: receiptQty,
        balanceAfter: newStock,
        unitCost: unitPrice,
        notes: `Receipt from ${supplierName || 'vendor'} (Lot: ${dto.supplierLot || 'N/A'})`,
      });
      await queryRunner.manager.save(ledgerEntry);

      // 7. Update Stock Item
      stockItem.current_stock = newStock;
      stockItem.weighted_avg_price = newWac;
      await queryRunner.manager.save(stockItem);

      await queryRunner.commitTransaction();

      await this.auditService.logAction({
        userId: user?.userId,
        action: 'CREATE_STOCK_RECEIPT',
        entityType: 'STOCK_RECEIPT',
        entityId: receiptId,
        newValues: {
          receiptNumber,
          stockItemId: dto.stockItemId,
          quantity: receiptQty,
          unitPrice,
          newStock,
          newWac,
        },
      });

      return receipt;
    } catch (err) {
      await queryRunner.rollbackTransaction();
      throw err;
    } finally {
      await queryRunner.release();
    }
  }

  async getSuppliers() {
    return this.dataSource
      .getRepository(SupplierEntity)
      .find({ where: { isActive: true }, order: { name: 'ASC' } });
  }

  async createSupplier(dto: CreateSupplierDto, user: AuthenticatedUser) {
    const existing = await this.dataSource
      .getRepository(SupplierEntity)
      .findOne({ where: { name: dto.name.trim() } });
    if (existing) {
      throw new ConflictException(`Supplier with name "${dto.name}" already exists.`);
    }

    const supplier = this.dataSource.getRepository(SupplierEntity).create({
      id: uuidv4(),
      name: dto.name.trim(),
      contactPerson: dto.contactPerson?.trim() || null,
      phone: dto.phone?.trim() || null,
      email: dto.email?.trim() || null,
      address: dto.address?.trim() || null,
      category: dto.category,
      isActive: true,
    });

    const saved = await this.dataSource.getRepository(SupplierEntity).save(supplier);

    await this.auditService.logAction({
      userId: user?.userId,
      action: 'CREATE_SUPPLIER',
      entityType: 'SUPPLIER',
      entityId: saved.id,
      newValues: { name: saved.name, category: saved.category },
    });

    return saved;
  }

  async getLedger(stockItemId?: string, page = 1, limit = 25) {
    const offset = (page - 1) * limit;
    const qb = this.dataSource
      .getRepository(StockLedgerEntryEntity)
      .createQueryBuilder('ledger');

    if (stockItemId) {
      qb.andWhere('ledger.stock_item_id = :stockItemId', { stockItemId });
    }

    qb.orderBy('ledger.record_date', 'DESC').addOrderBy('ledger.created_at', 'DESC');

    const [items, total] = await qb.skip(offset).take(limit).getManyAndCount();

    return {
      items,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }
}
