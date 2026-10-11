import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_drawer.dart';
import '../domain/inventory_models.dart';
import 'inventory_provider.dart';
import 'widgets/record_stock_receipt_dialog.dart';
import 'widgets/add_stock_item_dialog.dart';
import 'widgets/add_supplier_dialog.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openAddDialog() {
    if (_tabController.index == 0) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AddStockItemDialog(),
      );
    } else if (_tabController.index == 1) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const RecordStockReceiptDialog(),
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AddSupplierDialog(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(inventoryItemsProvider);
    final receiptsAsync = ref.watch(stockReceiptsProvider);
    final suppliersAsync = ref.watch(suppliersProvider);
    final filter = ref.watch(inventoryFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Common Inventory'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Stock Items'),
            Tab(icon: Icon(Icons.input_outlined), text: 'Inbound Receipts'),
            Tab(icon: Icon(Icons.local_shipping_outlined), text: 'Suppliers'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(inventoryItemsProvider);
              ref.invalidate(stockReceiptsProvider);
              ref.invalidate(suppliersProvider);
            },
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/inventory'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddDialog,
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0
            ? 'Add Item'
            : (_tabController.index == 1 ? 'Inbound Receipt' : 'Add Supplier')),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ------------------------------------------------------------------
          // TAB 1: Stock Items & Current Balances
          // ------------------------------------------------------------------
          itemsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: AppSpacing.md),
                  Text('Failed to load stock items: $err'),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(inventoryItemsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (data) {
              final items = data.items;
              final lowStockCount = items.where((i) => i.isLowStock).length;
              final totalValuation = items.fold<double>(
                0.0,
                (sum, i) => sum + (i.currentStock * i.weightedAvgPrice),
              );

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(inventoryItemsProvider),
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    // Metric Summary Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'Total Items',
                            '${items.length}',
                            Icons.category_outlined,
                            AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _buildMetricCard(
                            'Low Stock',
                            '$lowStockCount items',
                            Icons.warning_amber_outlined,
                            lowStockCount > 0 ? AppColors.error : AppColors.success,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _buildMetricCard(
                            'Valuation',
                            '₹${totalValuation.toStringAsFixed(0)}',
                            Icons.account_balance_wallet_outlined,
                            AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Search & Low Stock Toggle
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search items...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        ref.read(inventoryFilterProvider.notifier).setSearch(null);
                                      },
                                    )
                                  : null,
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onSubmitted: (q) {
                              ref.read(inventoryFilterProvider.notifier).setSearch(q.isEmpty ? null : q);
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        FilterChip(
                          selected: filter.lowStockOnly == true,
                          label: const Text('Low Stock Only'),
                          onSelected: (_) {
                            ref.read(inventoryFilterProvider.notifier).toggleLowStockOnly();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Category Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChip(
                            selected: filter.category == null,
                            label: const Text('All Categories'),
                            onSelected: (_) {
                              ref.read(inventoryFilterProvider.notifier).setCategory(null);
                            },
                          ),
                          ...StockCategory.values.map((c) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: FilterChip(
                                selected: filter.category == c,
                                label: Text(c.label),
                                onSelected: (_) {
                                  ref.read(inventoryFilterProvider.notifier).setCategory(c);
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    if (items.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xxl),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            const Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.neutral400),
                            const SizedBox(height: AppSpacing.md),
                            Text('No inventory items found', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: AppSpacing.sm),
                            const Text('Add raw feed ingredients, packaging, or consumables.'),
                            const SizedBox(height: AppSpacing.lg),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Add Stock Item'),
                              onPressed: _openAddDialog,
                            ),
                          ],
                        ),
                      )
                    else
                      ...items.map((item) => _buildStockItemCard(item)),
                  ],
                ),
              );
            },
          ),

          // ------------------------------------------------------------------
          // TAB 2: Inbound Receipts
          // ------------------------------------------------------------------
          receiptsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Failed to load receipts: $err')),
            data: (data) {
              final receipts = data.items;
              if (receipts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.input_outlined, size: 64, color: AppColors.neutral400),
                      const SizedBox(height: AppSpacing.md),
                      const Text('No inbound receipts recorded'),
                      const SizedBox(height: AppSpacing.lg),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Record Receipt'),
                        onPressed: _openAddDialog,
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(stockReceiptsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: receipts.length,
                  itemBuilder: (_, idx) => _buildReceiptCard(receipts[idx]),
                ),
              );
            },
          ),

          // ------------------------------------------------------------------
          // TAB 3: Suppliers Directory
          // ------------------------------------------------------------------
          suppliersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Failed to load suppliers: $err')),
            data: (suppliers) {
              if (suppliers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.local_shipping_outlined, size: 64, color: AppColors.neutral400),
                      const SizedBox(height: AppSpacing.md),
                      const Text('No suppliers registered yet'),
                      const SizedBox(height: AppSpacing.lg),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Supplier'),
                        onPressed: _openAddDialog,
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(suppliersProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: suppliers.length,
                  itemBuilder: (_, idx) => _buildSupplierCard(suppliers[idx]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(title, style: const TextStyle(fontSize: 11, color: AppColors.neutral600)),
              ],
            ),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildStockItemCard(StockItemModel item) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.category.label,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (item.isLowStock)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning, size: 12, color: AppColors.error),
                            SizedBox(width: 4),
                            Text(
                              'LOW STOCK',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                Text(
                  '${item.currentStock.toStringAsFixed(1)} ${item.unit}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: item.isLowStock ? AppColors.error : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const Divider(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('Used by: ${item.usedBy}', style: const TextStyle(fontSize: 12, color: AppColors.neutral600)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('WAC: ₹${item.weightedAvgPrice.toStringAsFixed(2)}/${item.unit}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    Text('Reorder: ${item.reorderLevel.toStringAsFixed(0)} ${item.unit}',
                        style: const TextStyle(fontSize: 11, color: AppColors.neutral600)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptCard(StockReceiptModel r) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(r.receiptNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('₹${r.totalCost.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
              ],
            ),
            const Divider(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vendor: ${r.supplierName ?? 'Direct Purchase'}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    if (r.supplierLot != null)
                      Text('Lot/Inv: ${r.supplierLot}', style: const TextStyle(fontSize: 11, color: AppColors.neutral600)),
                    Text('Date: ${r.recordDate}', style: const TextStyle(fontSize: 11, color: AppColors.neutral600)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${r.quantity.toStringAsFixed(1)} units',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    Text('@ ₹${r.unitPrice.toStringAsFixed(2)}/unit',
                        style: const TextStyle(fontSize: 11, color: AppColors.neutral600)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplierCard(SupplierModel s) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1.5,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: const Icon(Icons.business, color: AppColors.primary),
        ),
        title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.category.label, style: const TextStyle(fontSize: 11, color: AppColors.primary)),
            if (s.contactPerson != null)
              Text('Contact: ${s.contactPerson}', style: const TextStyle(fontSize: 12)),
            if (s.phone != null)
              Text('Phone: ${s.phone}', style: const TextStyle(fontSize: 12, color: AppColors.neutral600)),
          ],
        ),
        trailing: s.isActive
            ? const Icon(Icons.check_circle, color: AppColors.success, size: 20)
            : const Icon(Icons.cancel, color: AppColors.error, size: 20),
      ),
    );
  }
}
