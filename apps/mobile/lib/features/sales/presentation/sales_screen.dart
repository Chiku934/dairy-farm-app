import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_drawer.dart';
import '../domain/sales_models.dart';
import 'sales_provider.dart';
import 'widgets/book_sales_order_dialog.dart';
import 'widgets/record_sales_dispatch_dialog.dart';
import 'widgets/record_customer_payment_dialog.dart';
import 'widgets/add_customer_dialog.dart';

class SalesScreen extends ConsumerStatefulWidget {
  final int initialTab;

  const SalesScreen({
    super.key,
    this.initialTab = 0,
  });

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 2),
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openAddDialog() {
    if (_tabController.index == 0) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const BookSalesOrderDialog(),
      );
    } else if (_tabController.index == 1) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const RecordSalesDispatchDialog(),
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const RecordCustomerPaymentDialog(),
      );
    }
  }

  void _openAddCustomerDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AddCustomerDialog(),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.warning;
      case OrderStatus.partiallyFulfilled:
        return AppColors.info;
      case OrderStatus.fulfilled:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.error;
    }
  }

  Future<void> _cancelOrder(SalesOrderModel order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Sales Order'),
        content: Text('Are you sure you want to cancel order ${order.orderNumber}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No, Keep Order'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes, Cancel Order'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final repo = ref.read(salesRepositoryProvider);
        await repo.cancelOrder(order.id);
        ref.invalidate(salesOrdersProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order ${order.orderNumber} cancelled successfully.'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel order: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(salesOrdersProvider);
    final dispatchesAsync = ref.watch(salesDispatchesProvider);
    final paymentsAsync = ref.watch(customerPaymentsProvider);
    final customersAsync = ref.watch(customersProvider);
    final filter = ref.watch(salesFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales & Orders'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.assignment_outlined), text: 'Orders & Booking'),
            Tab(icon: Icon(Icons.local_shipping_outlined), text: 'Dispatches'),
            Tab(icon: Icon(Icons.payments_outlined), text: 'Customer Accounts'),
          ],
        ),
        actions: [
          if (_tabController.index == 2)
            IconButton(
              icon: const Icon(Icons.person_add_outlined),
              tooltip: 'Register Customer',
              onPressed: _openAddCustomerDialog,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(salesOrdersProvider);
              ref.invalidate(salesDispatchesProvider);
              ref.invalidate(customerPaymentsProvider);
              ref.invalidate(customersProvider);
            },
          ),
        ],
      ),
      drawer: AppDrawer(
        currentRoute: _tabController.index == 0
            ? '/orders'
            : (_tabController.index == 1 ? '/sales' : '/payments'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddDialog,
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0
            ? 'Book Order'
            : (_tabController.index == 1 ? 'Record Dispatch' : 'Record Payment')),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ------------------------------------------------------------------
          // TAB 1: Sales Orders & Fulfillment
          // ------------------------------------------------------------------
          Column(
            children: [
              // Order status filter bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                color: Theme.of(context).cardColor,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All Statuses'),
                        selected: filter.orderStatus == null,
                        onSelected: (_) {
                          ref.read(salesFilterProvider.notifier).setOrderStatus(null);
                        },
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ...OrderStatus.values.map((st) {
                        return Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: FilterChip(
                            label: Text(st.label),
                            selected: filter.orderStatus == st,
                            onSelected: (selected) {
                              ref
                                  .read(salesFilterProvider.notifier)
                                  .setOrderStatus(selected ? st : null);
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // Orders List
              Expanded(
                child: ordersAsync.when(
                  data: (data) {
                    if (data.items.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_turned_in_outlined,
                                size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
                            const SizedBox(height: AppSpacing.md),
                            const Text(
                              'No sales orders found',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            const Text(
                              'Tap "Book Order" to schedule a customer delivery order.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: data.items.length,
                      itemBuilder: (ctx, index) {
                        final order = data.items[index];
                        final statusColor = _getStatusColor(order.status);

                        return Card(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: AppColors.border.withOpacity(0.6)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            order.orderNumber,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            order.customerName ?? 'Customer',
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: statusColor.withOpacity(0.4)),
                                      ),
                                      child: Text(
                                        order.status.label,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: AppSpacing.lg),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Order Date',
                                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                          Text(order.orderDate,
                                              style: const TextStyle(fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Delivery Date',
                                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                          Text(order.deliveryDate,
                                              style: const TextStyle(fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          const Text('Total Value',
                                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                          Text('₹${order.totalAmount.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: AppColors.primary,
                                              )),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (order.items.isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.sm),
                                  Container(
                                    padding: const EdgeInsets.all(AppSpacing.sm),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: order.items.map((it) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 2),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '${it.productType.label} (${it.quantityDispatched}/${it.quantityOrdered} dispatched)',
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                              Text(
                                                '₹${it.totalPrice.toStringAsFixed(2)}',
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: AppSpacing.sm),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (order.status == OrderStatus.pending) ...[
                                      TextButton.icon(
                                        icon: const Icon(Icons.cancel_outlined, size: 16, color: AppColors.error),
                                        label: const Text('Cancel', style: TextStyle(color: AppColors.error)),
                                        onPressed: () => _cancelOrder(order),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                    ],
                                    if (order.status == OrderStatus.pending ||
                                        order.status == OrderStatus.partiallyFulfilled)
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.local_shipping, size: 16),
                                        label: const Text('Dispatch'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (_) => RecordSalesDispatchDialog(initialOrder: order),
                                          );
                                        },
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(
                    child: Text('Failed to load orders: $err',
                        style: const TextStyle(color: AppColors.error)),
                  ),
                ),
              ),
            ],
          ),

          // ------------------------------------------------------------------
          // TAB 2: Sales Dispatches
          // ------------------------------------------------------------------
          dispatchesAsync.when(
            data: (data) {
              if (data.items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_shipping_outlined,
                          size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
                      const SizedBox(height: AppSpacing.md),
                      const Text(
                        'No dispatch records found',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'Tap "Record Dispatch" to log a delivery note & invoice.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: data.items.length,
                itemBuilder: (ctx, index) {
                  final disp = data.items[index];
                  final isFullyPaid = disp.balanceDue <= 0.001;

                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppColors.border.withOpacity(0.6)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      disp.dispatchNumber,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      disp.customerName ?? 'Customer',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (isFullyPaid ? AppColors.success : AppColors.warning)
                                      .withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: (isFullyPaid ? AppColors.success : AppColors.warning)
                                        .withOpacity(0.4),
                                  ),
                                ),
                                child: Text(
                                  isFullyPaid ? 'Settled' : 'Balance ₹${disp.balanceDue.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: isFullyPaid ? AppColors.success : AppColors.warning,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: AppSpacing.lg),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Product & Packs',
                                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    Text(
                                      '${disp.packsSold} packs ${disp.productType.label}',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Rate & Total',
                                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    Text(
                                      '₹${disp.pricePerPack.toStringAsFixed(2)} → ₹${disp.totalAmount.toStringAsFixed(2)}',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Date',
                                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    Text(disp.recordDate,
                                        style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (!isFullyPaid) ...[
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.payment, size: 16),
                                  label: const Text('Record Payment'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.secondary,
                                    side: const BorderSide(color: AppColors.secondary),
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (_) => RecordCustomerPaymentDialog(initialDispatch: disp),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Text('Failed to load dispatches: $err',
                  style: const TextStyle(color: AppColors.error)),
            ),
          ),

          // ------------------------------------------------------------------
          // TAB 3: Customer Accounts & Payment History
          // ------------------------------------------------------------------
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Header: Outstanding Balances
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Customer Ledgers & Balances',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.person_add, size: 16),
                      label: const Text('New Customer'),
                      onPressed: _openAddCustomerDialog,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Customer horizontal cards
                customersAsync.when(
                  data: (customers) {
                    if (customers.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                        child: Text('No customers registered yet.',
                            style: TextStyle(color: AppColors.textSecondary)),
                      );
                    }

                    return SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: customers.length,
                        itemBuilder: (ctx, idx) {
                          final c = customers[idx];
                          final hasCreditRisk = c.creditLimit > 0 && c.currentBalance > c.creditLimit;

                          return Container(
                            width: 220,
                            margin: const EdgeInsets.only(right: AppSpacing.md),
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: hasCreditRisk ? AppColors.error : AppColors.border,
                                width: hasCreditRisk ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        c.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (hasCreditRisk)
                                      const Icon(Icons.warning_amber_rounded,
                                          color: AppColors.error, size: 18),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Outstanding A/R:',
                                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    Text(
                                      '₹${c.currentBalance.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: c.currentBalance > 0
                                            ? AppColors.warning
                                            : AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  'Credit Limit: ₹${c.creditLimit.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (err, _) => Text('Error: $err', style: const TextStyle(color: AppColors.error)),
                ),

                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Payment Receipts & Settlement History',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Payments list
                paymentsAsync.when(
                  data: (data) {
                    if (data.items.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.payments_outlined,
                                  size: 48, color: AppColors.textSecondary.withOpacity(0.5)),
                              const SizedBox(height: AppSpacing.sm),
                              const Text('No customer payments recorded yet.',
                                  style: TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: data.items.length,
                      itemBuilder: (ctx, idx) {
                        final p = data.items[idx];

                        return Card(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: AppColors.border.withOpacity(0.6)),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.secondary.withOpacity(0.12),
                              child: const Icon(Icons.check, color: AppColors.secondary, size: 20),
                            ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  p.customerName ?? 'Customer Payment',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  '+ ₹${p.amountReceived.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${p.paymentNumber} • ${p.paymentMethod.label}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(p.recordDate, style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(
                    child: Text('Failed to load payments: $err',
                        style: const TextStyle(color: AppColors.error)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
