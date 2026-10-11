import { Test, TestingModule } from '@nestjs/testing';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import { ConflictException, BadRequestException } from '@nestjs/common';
import { ProductType, OrderStatus, PaymentMethod, StockCategory, CustomerType, SupplierCategory } from '@dairy-farm/api-contracts';

import { InventoryModule } from '../modules/inventory/inventory.module';
import { InventoryService } from '../modules/inventory/inventory.service';
import { StockItemEntity, StockUsedBy } from '../modules/feed/entities/stock-item.entity';
import { StockReceiptEntity } from '../modules/inventory/entities/stock-receipt.entity';
import { StockLedgerEntryEntity } from '../modules/inventory/entities/stock-ledger-entry.entity';
import { SupplierEntity } from '../modules/inventory/entities/supplier.entity';

import { SalesModule } from '../modules/sales/sales.module';
import { SalesService } from '../modules/sales/sales.service';
import { CustomerEntity } from '../modules/sales/entities/customer.entity';
import { SalesOrderEntity } from '../modules/sales/entities/sales-order.entity';
import { SalesOrderItemEntity } from '../modules/sales/entities/sales-order-item.entity';
import { SalesDispatchEntity } from '../modules/sales/entities/sales-dispatch.entity';
import { SalesDispatchItemEntity } from '../modules/sales/entities/sales-dispatch-item.entity';
import { CustomerPaymentEntity } from '../modules/sales/entities/customer-payment.entity';

import { AuditModule } from '../modules/audit/audit.module';
import { AuditLogEntity } from '../modules/audit/entities/audit-log.entity';

import { ConfigModule } from '@nestjs/config';
import { getDatabaseConfig } from '../modules/database/database.config';

describe('Phase 10: Inventory, Orders, Dispatches, Sales & Customer Payments Integration Tests', () => {
  let module: TestingModule;
  let dataSource: DataSource;
  let inventoryService: InventoryService;
  let salesService: SalesService;

  const mockUser = {
    userId: 'usr-dev-admin',
    email: 'admin@dairyfarm.local',
    roles: ['FARM_OWNER'],
    permissions: ['inventory:read', 'inventory:write', 'sales:read', 'sales:write'],
  };

  beforeAll(async () => {
    module = await Test.createTestingModule({
      imports: [
        ConfigModule.forRoot({ isGlobal: true }),
        TypeOrmModule.forRootAsync({
          useFactory: () => getDatabaseConfig(),
        }),
        InventoryModule,
        SalesModule,
        AuditModule,
      ],
    }).compile();

    dataSource = module.get<DataSource>(DataSource);
    inventoryService = module.get<InventoryService>(InventoryService);
    salesService = module.get<SalesService>(SalesService);
  });

  afterAll(async () => {
    if (dataSource && dataSource.isInitialized) {
      await dataSource.destroy();
    }
  });

  describe('1. Inventory Inbound Receipts & Moving WAC Calculation', () => {
    const testItemId = `item-test-wac-${Date.now()}`;

    beforeAll(async () => {
      // Seed item with 100 units @ ₹20
      await dataSource.query(
        `INSERT INTO stock_items (id, name, used_by, category, unit, current_stock, weighted_avg_price, reorder_level)
         VALUES (?, ?, 'FARM', 'FEED', 'kg', 100.00, 20.00, 50.00)`,
        [testItemId, `Test Feed Maize ${Date.now()}`],
      );
    });

    afterAll(async () => {
      await dataSource.query(`DELETE FROM stock_ledger_entries WHERE stock_item_id = ?`, [testItemId]);
      await dataSource.query(`DELETE FROM stock_receipts WHERE stock_item_id = ?`, [testItemId]);
      await dataSource.query(`DELETE FROM stock_items WHERE id = ?`, [testItemId]);
    });

    it('calculates moving Weighted Average Cost and updates ledger on receipt', async () => {
      // Receiving 200 units @ ₹35
      // Expected new stock = 100 + 200 = 300
      // Expected WAC = (100*20 + 200*35) / 300 = (2000 + 7000) / 300 = 9000 / 300 = ₹30.00
      const receipt = await inventoryService.createReceipt(
        {
          recordDate: '2026-10-18',
          stockItemId: testItemId,
          supplierName: 'Agro Feeds Pvt',
          quantity: 200.0,
          unitPrice: 35.0,
          notes: 'Test batch delivery',
        },
        mockUser as any,
      );

      expect(receipt).toBeDefined();
      expect(receipt.totalCost).toBe(7000.0);

      const [item] = await dataSource.query(`SELECT current_stock, weighted_avg_price FROM stock_items WHERE id = ?`, [
        testItemId,
      ]);
      expect(Number(item.current_stock)).toBe(300.0);
      expect(Number(item.weighted_avg_price)).toBe(30.0);

      const [ledger] = await dataSource.query(
        `SELECT * FROM stock_ledger_entries WHERE stock_item_id = ? AND transaction_type = 'RECEIPT' ORDER BY created_at DESC LIMIT 1`,
        [testItemId],
      );
      expect(ledger).toBeDefined();
      expect(Number(ledger.quantity_change)).toBe(200.0);
      expect(Number(ledger.balance_after)).toBe(300.0);
      expect(Number(ledger.unit_cost)).toBe(35.0);
    });

    it('correctly reports low-stock reorder indicators', async () => {
      // Current stock is 300, set reorder to 350
      await dataSource.query(`UPDATE stock_items SET reorder_level = 350.00 WHERE id = ?`, [testItemId]);

      const itemRes = await inventoryService.getItemById(testItemId);
      expect(itemRes.isLowStock).toBe(true);

      // Set reorder to 200
      await dataSource.query(`UPDATE stock_items SET reorder_level = 200.00 WHERE id = ?`, [testItemId]);
      const itemRes2 = await inventoryService.getItemById(testItemId);
      expect(itemRes2.isLowStock).toBe(false);
    });
  });

  describe('2. Negative Stock Protection & Idempotency', () => {
    it('rejects duplicate receipt numbers with ConflictException', async () => {
      const fixedReceiptNo = `REC-TEST-DUP-${Date.now()}`;
      const tempItemId = `item-temp-${Date.now()}`;

      await dataSource.query(
        `INSERT INTO stock_items (id, name, used_by, category, unit, current_stock, weighted_avg_price, reorder_level)
         VALUES (?, ?, 'PRODUCTION', 'PACKAGING', 'units', 50.00, 2.00, 10.00)`,
        [tempItemId, `Temp Pouches ${Date.now()}`],
      );

      await inventoryService.createReceipt(
        {
          receiptNumber: fixedReceiptNo,
          recordDate: '2026-10-18',
          stockItemId: tempItemId,
          quantity: 10.0,
          unitPrice: 2.0,
        },
        mockUser as any,
      );

      await expect(
        inventoryService.createReceipt(
          {
            receiptNumber: fixedReceiptNo,
            recordDate: '2026-10-18',
            stockItemId: tempItemId,
            quantity: 10.0,
            unitPrice: 2.0,
          },
          mockUser as any,
        ),
      ).rejects.toThrow(ConflictException);

      await dataSource.query(`DELETE FROM stock_ledger_entries WHERE stock_item_id = ?`, [tempItemId]);
      await dataSource.query(`DELETE FROM stock_receipts WHERE stock_item_id = ?`, [tempItemId]);
      await dataSource.query(`DELETE FROM stock_items WHERE id = ?`, [tempItemId]);
    });
  });

  describe('3. Sales Orders, Partial Dispatches & Status State Machine', () => {
    const testCustomerId = `cust-test-${Date.now()}`;
    let createdOrderId: string;

    beforeAll(async () => {
      await dataSource.query(
        `INSERT INTO customers (id, name, phone, customer_type, credit_limit, current_balance)
         VALUES (?, 'Maa Tarini Sweets', '+91 9999900001', 'WHOLESALE', 50000.00, 0.00)`,
        [testCustomerId],
      );
    });

    afterAll(async () => {
      await dataSource.query(`DELETE FROM customer_payments WHERE customer_id = ?`, [testCustomerId]);
      await dataSource.query(`DELETE FROM sales_dispatch_items WHERE dispatch_id IN (SELECT id FROM sales_dispatches WHERE customer_id = ?)`, [testCustomerId]);
      await dataSource.query(`DELETE FROM sales_dispatches WHERE customer_id = ?`, [testCustomerId]);
      await dataSource.query(`DELETE FROM sales_order_items WHERE order_id IN (SELECT id FROM sales_orders WHERE customer_id = ?)`, [testCustomerId]);
      await dataSource.query(`DELETE FROM sales_orders WHERE customer_id = ?`, [testCustomerId]);
      await dataSource.query(`DELETE FROM customers WHERE id = ?`, [testCustomerId]);
    });

    it('books a multi-line sales order with PENDING status and correct pricing', async () => {
      const order = await salesService.createOrder(
        {
          customerId: testCustomerId,
          orderDate: '2026-10-18',
          deliveryDate: '2026-10-19',
          items: [
            {
              productType: ProductType.MILK,
              quantityOrdered: 100,
              unitPrice: 30.0, // 3000
            },
            {
              productType: ProductType.PANEER,
              quantityOrdered: 20,
              unitPrice: 150.0, // 3000
            },
          ],
          notes: 'Morning fresh delivery',
        },
        mockUser as any,
      );

      expect(order).toBeDefined();
      expect(order.status).toBe(OrderStatus.PENDING);
      expect(order.totalAmount).toBe(6000.0);
      expect(order.items.length).toBe(2);
      createdOrderId = order.id;
    });

    it('partially dispatches order, transitions status to PARTIALLY_FULFILLED, and tracks balance', async () => {
      // Dispatch 60 of 100 milk packs @ ₹30 = ₹1,800. Customer pays ₹1,000 cash advance.
      const dispatch = await salesService.createDispatch(
        {
          orderId: createdOrderId,
          customerId: testCustomerId,
          recordDate: '2026-10-19',
          productType: ProductType.MILK,
          packsSold: 60,
          pricePerPack: 30.0,
          amountReceived: 1000.0,
          paymentMethod: PaymentMethod.CASH,
          notes: 'First partial vehicle trip',
        },
        mockUser as any,
      );

      expect(dispatch).toBeDefined();
      expect(dispatch.totalAmount).toBe(1800.0);
      expect(dispatch.amountReceived).toBe(1000.0);
      expect(dispatch.balanceDue).toBe(800.0);

      // Verify order status updated to PARTIALLY_FULFILLED
      const order = await salesService.getOrderById(createdOrderId);
      expect(order.status).toBe(OrderStatus.PARTIALLY_FULFILLED);

      // Verify customer receivable balance updated to ₹800
      const customer = await salesService.getCustomerById(testCustomerId);
      expect(Number(customer.currentBalance)).toBe(800.0);

      // Verify linked payment record was automatically created for the ₹1,000
      const [payment] = await dataSource.query(
        `SELECT * FROM customer_payments WHERE customer_id = ? AND dispatch_id = ?`,
        [testCustomerId, dispatch.id],
      );
      expect(payment).toBeDefined();
      expect(Number(payment.amount_received)).toBe(1000.0);
    });

    it('rejects order cancellation when fulfillment has already begun', async () => {
      await expect(salesService.cancelOrder(createdOrderId, mockUser as any)).rejects.toThrow(
        BadRequestException,
      );
    });

    it('completes remaining items and automatically transitions order to FULFILLED', async () => {
      // Second dispatch fulfilling remaining 40 milk packs and 20 paneer packs
      const dispatch = await salesService.createDispatch(
        {
          orderId: createdOrderId,
          customerId: testCustomerId,
          recordDate: '2026-10-19',
          items: [
            {
              productType: ProductType.MILK,
              quantity: 40,
              unitPrice: 30.0, // 1200
            },
            {
              productType: ProductType.PANEER,
              quantity: 20,
              unitPrice: 150.0, // 3000
            },
          ],
          amountReceived: 0.0, // on credit
          notes: 'Second vehicle trip completing order',
        },
        mockUser as any,
      );

      expect(dispatch.totalAmount).toBe(4200.0);
      expect(dispatch.balanceDue).toBe(4200.0);

      // Order should now be FULFILLED
      const order = await salesService.getOrderById(createdOrderId);
      expect(order.status).toBe(OrderStatus.FULFILLED);

      // Customer balance: prior 800 + 4200 = 5000
      const customer = await salesService.getCustomerById(testCustomerId);
      expect(Number(customer.currentBalance)).toBe(5000.0);
    });
  });

  describe('4. Customer Payments & Receivable Reconciliation', () => {
    const testCustomerId = `cust-pay-${Date.now()}`;
    let dispatchId: string;

    beforeAll(async () => {
      await dataSource.query(
        `INSERT INTO customers (id, name, customer_type, credit_limit, current_balance)
         VALUES (?, 'Balaji Hotel', 'WHOLESALE', 20000.00, 0.00)`,
        [testCustomerId],
      );

      // Create a dispatch of ₹2,500 with ₹500 advance (balance due ₹2,000)
      const dispatch = await salesService.createDispatch(
        {
          customerId: testCustomerId,
          recordDate: '2026-10-18',
          productType: ProductType.PANEER,
          packsSold: 10,
          pricePerPack: 250.0,
          amountReceived: 500.0,
        },
        mockUser as any,
      );
      dispatchId = dispatch.id;
    });

    afterAll(async () => {
      await dataSource.query(`DELETE FROM customer_payments WHERE customer_id = ?`, [testCustomerId]);
      await dataSource.query(`DELETE FROM sales_dispatch_items WHERE dispatch_id IN (SELECT id FROM sales_dispatches WHERE customer_id = ?)`, [testCustomerId]);
      await dataSource.query(`DELETE FROM sales_dispatches WHERE customer_id = ?`, [testCustomerId]);
      await dataSource.query(`DELETE FROM customers WHERE id = ?`, [testCustomerId]);
    });

    it('settles specific dispatch balance and reconciles customer accounts receivable', async () => {
      // Pay ₹1,200 specifically against the dispatch
      const payment = await salesService.createPayment(
        {
          customerId: testCustomerId,
          dispatchId,
          recordDate: '2026-10-19',
          amountReceived: 1200.0,
          paymentMethod: PaymentMethod.UPI,
          referenceCode: 'UPI-TXN-123456',
          notes: 'Partial settlement via phonepe',
        },
        mockUser as any,
      );

      expect(payment).toBeDefined();

      // Dispatch balance due was 2,000; now should be 800
      const dispatch = await salesService.getDispatchById(dispatchId);
      expect(Number(dispatch.balanceDue)).toBe(800.0);

      // Customer balance was 2,000; now should be 800
      const customer = await salesService.getCustomerById(testCustomerId);
      expect(Number(customer.currentBalance)).toBe(800.0);

      // General on-account payment of remaining ₹800
      await salesService.createPayment(
        {
          customerId: testCustomerId,
          recordDate: '2026-10-20',
          amountReceived: 800.0,
          paymentMethod: PaymentMethod.BANK_TRANSFER,
          referenceCode: 'NEFT-554433',
        },
        mockUser as any,
      );

      const customerFinal = await salesService.getCustomerById(testCustomerId);
      expect(Number(customerFinal.currentBalance)).toBe(0.0);
    });

    it('rejects invalid non-positive payment amounts', async () => {
      await expect(
        salesService.createPayment(
          {
            customerId: testCustomerId,
            recordDate: '2026-10-20',
            amountReceived: -100.0,
            paymentMethod: PaymentMethod.CASH,
          },
          mockUser as any,
        ),
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe('5. Concurrency & Row-Locking Test', () => {
    it('executes concurrent payments without balance corruption', async () => {
      const concurrentCustId = `cust-concurrent-${Date.now()}`;
      await dataSource.query(
        `INSERT INTO customers (id, name, customer_type, credit_limit, current_balance)
         VALUES (?, 'Concurrent Test Customer', 'RETAIL', 10000.00, 3000.00)`,
        [concurrentCustId],
      );

      // Execute 3 simultaneous payments of ₹500, ₹300, and ₹200
      const promises = [
        salesService.createPayment(
          { customerId: concurrentCustId, recordDate: '2026-10-18', amountReceived: 500.0, paymentMethod: PaymentMethod.CASH },
          mockUser as any,
        ),
        salesService.createPayment(
          { customerId: concurrentCustId, recordDate: '2026-10-18', amountReceived: 300.0, paymentMethod: PaymentMethod.UPI },
          mockUser as any,
        ),
        salesService.createPayment(
          { customerId: concurrentCustId, recordDate: '2026-10-18', amountReceived: 200.0, paymentMethod: PaymentMethod.CASH },
          mockUser as any,
        ),
      ];

      await Promise.all(promises);

      // Expected final balance: 3000 - (500 + 300 + 200) = 2000.00
      const [cust] = await dataSource.query(`SELECT current_balance FROM customers WHERE id = ?`, [concurrentCustId]);
      expect(Number(cust.current_balance)).toBe(2000.0);

      await dataSource.query(`DELETE FROM customer_payments WHERE customer_id = ?`, [concurrentCustId]);
      await dataSource.query(`DELETE FROM customers WHERE id = ?`, [concurrentCustId]);
    });
  });
});
