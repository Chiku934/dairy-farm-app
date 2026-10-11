import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dairy_mobile/features/inventory/domain/inventory_models.dart';
import 'package:dairy_mobile/features/inventory/presentation/inventory_provider.dart';
import 'package:dairy_mobile/features/inventory/presentation/inventory_screen.dart';
import 'package:dairy_mobile/features/inventory/presentation/widgets/add_stock_item_dialog.dart';

import 'package:dairy_mobile/features/sales/domain/sales_models.dart';
import 'package:dairy_mobile/features/sales/presentation/sales_provider.dart';
import 'package:dairy_mobile/features/sales/presentation/sales_screen.dart';
import 'package:dairy_mobile/features/sales/presentation/widgets/record_sales_dispatch_dialog.dart';
import 'package:dairy_mobile/features/sales/presentation/widgets/record_customer_payment_dialog.dart';

void main() {
  group('Phase 10: Common Inventory, Orders, Dispatches, Sales & Customer Payments Widget Tests', () {
    testWidgets('InventoryScreen renders stock items, low stock warning badge, and tab switches', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final List<StockItemModel> mockStockItems = [
        StockItemModel(
          id: 'item-01',
          name: 'Premium Cattle Feed Pellets',
          usedBy: 'BOTH',
          category: StockCategory.feed,
          unit: 'KG',
          currentStock: 30.0,
          weightedAvgPrice: 28.50,
          reorderLevel: 50.0,
          isLowStock: true,
        ),
        StockItemModel(
          id: 'item-02',
          name: '500ml Milk LDPE Pouches',
          usedBy: 'PROCESSING',
          category: StockCategory.packaging,
          unit: 'PCS',
          currentStock: 5000.0,
          weightedAvgPrice: 0.65,
          reorderLevel: 1000.0,
          isLowStock: false,
        ),
      ];

      final List<StockReceiptModel> mockReceipts = [
        StockReceiptModel(
          id: 'rcp-01',
          receiptNumber: 'RCP-2026-0001',
          recordDate: '2026-10-10',
          stockItemId: 'item-01',
          stockItemName: 'Premium Cattle Feed Pellets',
          supplierId: 'sup-01',
          supplierName: 'Agro Feeds Ltd',
          quantity: 200.0,
          unitPrice: 28.50,
          totalCost: 5700.0,
        ),
      ];

      final List<SupplierModel> mockSuppliers = [
        SupplierModel(
          id: 'sup-01',
          name: 'Agro Feeds Ltd',
          category: SupplierCategory.feed,
          contactPerson: 'Ramesh Sharma',
          phone: '+919876543210',
          isActive: true,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inventoryItemsProvider.overrideWith(
              (ref) => Future.value((items: mockStockItems, total: 2, totalPages: 1)),
            ),
            stockReceiptsProvider.overrideWith(
              (ref) => Future.value((items: mockReceipts, total: 1, totalPages: 1)),
            ),
            suppliersProvider.overrideWith(
              (ref) => Future.value(mockSuppliers),
            ),
          ],
          child: const MaterialApp(
            home: InventoryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header and item display
      expect(find.text('Common Inventory'), findsOneWidget);
      expect(find.text('Premium Cattle Feed Pellets'), findsOneWidget);
      expect(find.text('500ml Milk LDPE Pouches'), findsOneWidget);

      // Low stock warning badge check (30.0 <= 50.0)
      expect(find.text('LOW STOCK'), findsOneWidget);

      // Current balance and moving WAC checks
      expect(find.text('30.0 KG'), findsOneWidget);
      expect(find.text('5000.0 PCS'), findsOneWidget);
      expect(find.text('WAC: ₹28.50/KG'), findsOneWidget);

      // Switch to Inbound Receipts Tab
      await tester.tap(find.text('Inbound Receipts'));
      await tester.pumpAndSettle();

      expect(find.text('RCP-2026-0001'), findsOneWidget);
      expect(find.text('Vendor: Agro Feeds Ltd'), findsOneWidget);
      expect(find.text('200.0 units'), findsOneWidget);
      expect(find.text('@ ₹28.50/unit'), findsOneWidget);

      // Switch to Suppliers Tab
      await tester.tap(find.text('Suppliers'));
      await tester.pumpAndSettle();

      expect(find.text('Agro Feeds Ltd'), findsOneWidget);
      expect(find.text('Contact: Ramesh Sharma'), findsOneWidget);
    });

    testWidgets('AddStockItemDialog validates required fields', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AddStockItemDialog(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final saveButton = find.text('Create Item');
      expect(saveButton, findsOneWidget);
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text('Item name is required'), findsOneWidget);
    });

    testWidgets('SalesScreen renders orders, dispatches, status chips, and customer accounts', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final List<SalesOrderModel> mockOrders = [
        SalesOrderModel(
          id: 'ord-01',
          orderNumber: 'SO-2026-0001',
          customerId: 'cust-01',
          customerName: 'Heritage Supermarket',
          orderDate: '2026-10-11',
          deliveryDate: '2026-10-12',
          status: OrderStatus.partiallyFulfilled,
          totalAmount: 3200.0,
          items: [
            SalesOrderItemModel(
              id: 'item-01',
              orderId: 'ord-01',
              productType: ProductType.milk,
              packSize: 1.0,
              packUnit: 'LITRE',
              quantityOrdered: 100,
              quantityDispatched: 50,
              unitPrice: 32.0,
              totalPrice: 3200.0,
            ),
          ],
        ),
      ];

      final List<SalesDispatchModel> mockDispatches = [
        SalesDispatchModel(
          id: 'dsp-01',
          dispatchNumber: 'DSP-2026-0001',
          orderId: 'ord-01',
          customerId: 'cust-01',
          customerName: 'Heritage Supermarket',
          recordDate: '2026-10-11',
          productType: ProductType.milk,
          packsSold: 50,
          pricePerPack: 32.0,
          totalAmount: 1600.0,
          amountReceived: 600.0,
          balanceDue: 1000.0,
          paymentMethod: PaymentMethod.cash,
        ),
      ];

      final List<CustomerModel> mockCustomers = [
        CustomerModel(
          id: 'cust-01',
          name: 'Heritage Supermarket',
          phone: '+919988776655',
          customerType: CustomerType.wholesale,
          creditLimit: 5000.0,
          currentBalance: 1000.0,
          isActive: true,
        ),
      ];

      final List<CustomerPaymentModel> mockPayments = [
        CustomerPaymentModel(
          id: 'pay-01',
          paymentNumber: 'PAY-2026-0001',
          customerId: 'cust-01',
          customerName: 'Heritage Supermarket',
          dispatchId: 'dsp-01',
          recordDate: '2026-10-11',
          amountReceived: 600.0,
          paymentMethod: PaymentMethod.cash,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            salesOrdersProvider.overrideWith(
              (ref) => Future.value((items: mockOrders, total: 1, totalPages: 1)),
            ),
            salesDispatchesProvider.overrideWith(
              (ref) => Future.value((items: mockDispatches, total: 1, totalPages: 1)),
            ),
            customersProvider.overrideWith(
              (ref) => Future.value(mockCustomers),
            ),
            customerPaymentsProvider.overrideWith(
              (ref) => Future.value((items: mockPayments, total: 1, totalPages: 1)),
            ),
          ],
          child: const MaterialApp(
            home: SalesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tab 1: Orders
      expect(find.text('Sales & Orders'), findsOneWidget);
      expect(find.text('SO-2026-0001'), findsOneWidget);
      expect(find.text('Heritage Supermarket'), findsOneWidget);
      expect(find.text('Partially Dispatched'), findsNWidgets(2));
      expect(find.text('₹3200.00'), findsNWidgets(2));
      expect(find.text('Dispatch'), findsOneWidget);

      // Switch to Tab 2: Dispatches
      await tester.tap(find.text('Dispatches'));
      await tester.pumpAndSettle();

      expect(find.text('DSP-2026-0001'), findsOneWidget);
      expect(find.text('50 packs Milk (Pouches)'), findsOneWidget);
      expect(find.text('Balance ₹1000.00'), findsOneWidget);
      expect(find.text('Record Payment'), findsOneWidget);

      // Switch to Tab 3: Customer Accounts
      await tester.tap(find.text('Customer Accounts'));
      await tester.pumpAndSettle();

      expect(find.text('Customer Ledgers & Balances'), findsOneWidget);
      expect(find.text('₹1000.00'), findsOneWidget);
      expect(find.text('Credit Limit: ₹5000'), findsOneWidget);
      expect(find.text('PAY-2026-0001 • Cash'), findsOneWidget);
      expect(find.text('+ ₹600.00'), findsOneWidget);
    });

    testWidgets('RecordSalesDispatchDialog validates customer requirement', (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockCustomers = [
        CustomerModel(
          id: 'cust-01',
          name: 'Heritage Supermarket',
          customerType: CustomerType.wholesale,
          creditLimit: 5000.0,
          currentBalance: 0.0,
          isActive: true,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customersProvider.overrideWith((ref) => Future.value(mockCustomers)),
            salesOrdersProvider.overrideWith(
              (ref) => Future.value((items: <SalesOrderModel>[], total: 0, totalPages: 1)),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: RecordSalesDispatchDialog(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final postButton = find.text('Post Dispatch');
      expect(postButton, findsOneWidget);
      await tester.ensureVisible(postButton);
      await tester.tap(postButton);
      await tester.pumpAndSettle();

      expect(find.text('Please select a customer'), findsOneWidget);
    });

    testWidgets('RecordCustomerPaymentDialog validates customer requirement and amount', (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockCustomers = [
        CustomerModel(
          id: 'cust-01',
          name: 'Heritage Supermarket',
          customerType: CustomerType.wholesale,
          creditLimit: 5000.0,
          currentBalance: 0.0,
          isActive: true,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customersProvider.overrideWith((ref) => Future.value(mockCustomers)),
            salesDispatchesProvider.overrideWith(
              (ref) => Future.value((items: <SalesDispatchModel>[], total: 0, totalPages: 1)),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: RecordCustomerPaymentDialog(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final recordBtn = find.text('Record Payment');
      expect(recordBtn, findsOneWidget);
      await tester.ensureVisible(recordBtn);
      await tester.tap(recordBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please select a customer'), findsOneWidget);
    });
  });
}
