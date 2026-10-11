import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/chips/app_status_chip.dart';
import '../domain/production_models.dart';
import 'production_provider.dart';
import 'widgets/create_batch_dialog.dart';

class ProductionScreen extends ConsumerWidget {
  const ProductionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batchesAsync = ref.watch(productionBatchesProvider);
    final filter = ref.watch(productionFilterProvider);
    final filterNotifier = ref.read(productionFilterProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Production Batches'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(productionBatchesProvider),
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/batches'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const CreateBatchDialog(),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Batch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(productionBatchesProvider),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // Search & Filter Card
            _buildFilterCard(context, filter, filterNotifier),
            const SizedBox(height: AppSpacing.md),

            // Batches List
            batchesAsync.when(
              data: (data) {
                if (data.items.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(Icons.blender_outlined, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text('No production batches found', style: AppTypography.titleMedium),
                          const SizedBox(height: 6),
                          Text(
                            'Click "+ New Batch" to convert raw BMC milk into finished dairy products.',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: data.items.map((batch) => _buildBatchCard(context, batch)).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()),
              ),
              error: (err, _) => Card(
                color: AppColors.danger.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Error loading batches: $err'),
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterCard(
    BuildContext context,
    ProductionFilterState filter,
    ProductionFilterNotifier notifier,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search batch number, operator, notes...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: filter.search != null && filter.search!.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => notifier.setSearch(''),
                      )
                    : null,
                isDense: true,
              ),
              onChanged: (val) => notifier.setSearch(val),
            ),
            const SizedBox(height: 10),

            // Product Type Horizontal Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All Products'),
                    selected: filter.productType == null,
                    onSelected: (_) => notifier.setProductType(null),
                  ),
                  const SizedBox(width: 6),
                  ...ProductType.values.map((p) => Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: FilterChip(
                          label: Text(p.label),
                          selected: filter.productType == p,
                          onSelected: (selected) => notifier.setProductType(selected ? p : null),
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Quality Release Horizontal Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All Releases'),
                    selected: filter.qualityRelease == null,
                    onSelected: (_) => notifier.setQualityRelease(null),
                  ),
                  const SizedBox(width: 6),
                  FilterChip(
                    label: const Text('Approved'),
                    selected: filter.qualityRelease == QualityReleaseStatus.approved,
                    onSelected: (selected) =>
                        notifier.setQualityRelease(selected ? QualityReleaseStatus.approved : null),
                  ),
                  const SizedBox(width: 6),
                  FilterChip(
                    label: const Text('On Hold'),
                    selected: filter.qualityRelease == QualityReleaseStatus.hold,
                    onSelected: (selected) =>
                        notifier.setQualityRelease(selected ? QualityReleaseStatus.hold : null),
                  ),
                  const SizedBox(width: 6),
                  FilterChip(
                    label: const Text('Rejected'),
                    selected: filter.qualityRelease == QualityReleaseStatus.rejected,
                    onSelected: (selected) =>
                        notifier.setQualityRelease(selected ? QualityReleaseStatus.rejected : null),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchCard(BuildContext context, ProductionBatchModel batch) {
    AppStatusType statusType = AppStatusType.warning;
    if (batch.qualityRelease == QualityReleaseStatus.approved) statusType = AppStatusType.success;
    if (batch.qualityRelease == QualityReleaseStatus.rejected) statusType = AppStatusType.danger;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/batches/${batch.id}'),
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(_getProductIcon(batch.productType), color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(batch.batchNumber, style: AppTypography.titleMedium),
                          Text(
                            batch.productType.label,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  AppStatusChip(
                    label: batch.qualityRelease.label,
                    type: statusType,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Metrics Row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${batch.finishedQuantity.toStringAsFixed(1)} ${batch.unitOfMeasure}',
                          style: AppTypography.titleMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                        const Text('Output Produced', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '${batch.bmcMilkConsumedL.toStringAsFixed(1)} L',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const Text('Milk Consumed', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${batch.yieldPercentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.teal.shade700,
                          ),
                        ),
                        const Text('Conversion Yield', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Footer: Date, Expiry, Operator & Traceability action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${batch.recordDate} • Expires: ${batch.expiryDate} • ${batch.operatorName ?? "Staff"}',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.timeline_outlined, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Traceability',
                        style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getProductIcon(ProductType type) {
    switch (type) {
      case ProductType.paneer:
        return Icons.layers_outlined;
      case ProductType.khoya:
        return Icons.cookie_outlined;
      case ProductType.ghee:
        return Icons.oil_barrel_outlined;
      case ProductType.dahi:
        return Icons.coffee_outlined;
      case ProductType.butter:
        return Icons.cake_outlined;
      case ProductType.milk:
        return Icons.local_drink_outlined;
      case ProductType.biogasFertiliser:
        return Icons.eco_outlined;
    }
  }
}
