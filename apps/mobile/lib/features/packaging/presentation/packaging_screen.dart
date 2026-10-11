import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_drawer.dart';
import 'packaging_provider.dart';
import 'widgets/record_packaging_dialog.dart';

class PackagingScreen extends ConsumerStatefulWidget {
  const PackagingScreen({super.key});

  @override
  ConsumerState<PackagingScreen> createState() => _PackagingScreenState();
}

class _PackagingScreenState extends ConsumerState<PackagingScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openRecordDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const RecordPackagingDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final runsAsync = ref.watch(packagingRunsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Packaging Runs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(packagingRunsProvider),
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/packaging'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openRecordDialog,
        icon: const Icon(Icons.add),
        label: const Text('Record Run'),
      ),
      body: runsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text('Failed to load packaging runs: $err'),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () => ref.invalidate(packagingRunsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (data) {
          final items = data.items;
          final totalPacks = items.fold<int>(0, (sum, r) => sum + r.numberOfPacks);
          final totalMaterial = items.fold<double>(0.0, (sum, r) => sum + r.materialConsumed);

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(packagingRunsProvider),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // KPI Header Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Total Runs',
                        '${items.length}',
                        Icons.inventory_2_outlined,
                        AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _buildMetricCard(
                        'Packs Produced',
                        '$totalPacks',
                        Icons.check_circle_outline,
                        AppColors.success,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _buildMetricCard(
                        'Material Used',
                        '${totalMaterial.toStringAsFixed(0)} units',
                        Icons.shopping_bag_outlined,
                        AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Packaging Runs (${items.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.filter_list, size: 18),
                      label: const Text('Filter'),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                if (items.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.neutral400),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No packaging runs recorded yet',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.neutral600),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Text('Package finished dairy products into retail pouches or bottles.'),
                        const SizedBox(height: AppSpacing.lg),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Record First Run'),
                          onPressed: _openRecordDialog,
                        ),
                      ],
                    ),
                  )
                else
                  ...items.map((r) => _buildRunCard(r)),
              ],
            ),
          );
        },
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
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 11, color: AppColors.neutral600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRunCard(r) {
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
                        r.batchNumber != null ? 'Batch ${r.batchNumber}' : 'Run #${r.id.substring(0, 8)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      r.recordDate,
                      style: const TextStyle(color: AppColors.neutral600, fontSize: 12),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.neutral100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${r.numberOfPacks} packs',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const Divider(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pack Size', style: TextStyle(fontSize: 11, color: AppColors.neutral600)),
                      Text('${r.packSize} ${r.packUnit}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Packaged', style: TextStyle(fontSize: 11, color: AppColors.neutral600)),
                      Text(
                        '${r.totalPackagedQuantity.toStringAsFixed(1)} ${r.packUnit}',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Material Deducted', style: TextStyle(fontSize: 11, color: AppColors.neutral600)),
                      Text('${r.materialConsumed.toStringAsFixed(0)} units', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            if (r.scrapUnits > 0) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.warning),
                  const SizedBox(width: 4),
                  Text(
                    'Scrap/burst allowance: ${r.scrapUnits} units',
                    style: const TextStyle(fontSize: 11, color: AppColors.warning),
                  ),
                ],
              ),
            ],
            if (r.notes != null && r.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Note: ${r.notes}',
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.neutral700),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
