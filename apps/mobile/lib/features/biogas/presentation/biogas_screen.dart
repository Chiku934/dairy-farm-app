import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/cards/app_card.dart';
import '../domain/biogas_models.dart';
import 'biogas_provider.dart';
import 'widgets/record_biogas_run_dialog.dart';

class BiogasScreen extends ConsumerWidget {
  const BiogasScreen({super.key});

  void _openRecordDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const RecordBiogasRunDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runsAsync = ref.watch(biogasRunsProvider);
    final filter = ref.watch(biogasFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Biogas & Bio-Fertiliser'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(biogasRunsProvider),
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/biogas'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openRecordDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Record Run'),
      ),
      body: runsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text('Failed to load biogas runs: $err'),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () => ref.invalidate(biogasRunsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (data) {
          final items = data.items;
          final summary = data.summary;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(biogasRunsProvider),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // 1. KPI Summary Cards
                _buildKpiGrid(context, summary),
                const SizedBox(height: AppSpacing.lg),

                // 2. Filter Chips
                _buildFilterChips(ref, filter),
                const SizedBox(height: AppSpacing.md),

                // 3. Runs List or Empty State
                if (items.isEmpty)
                  _buildEmptyState(context)
                else
                  ...items.map((run) => _buildRunCard(context, run)),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildKpiGrid(BuildContext context, BiogasSummaryModel s) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _buildKpiCard(
              context,
              title: 'Slurry Input',
              value: '${s.totalSlurryInputKg.toStringAsFixed(0)} kg',
              icon: Icons.water_drop_outlined,
              color: AppColors.primary,
              width: isWide ? (constraints.maxWidth - AppSpacing.md * 3) / 4 : (constraints.maxWidth - AppSpacing.md) / 2,
            ),
            _buildKpiCard(
              context,
              title: 'Dry Output',
              value: '${s.totalDryFertiliserKg.toStringAsFixed(0)} kg',
              icon: Icons.eco_outlined,
              color: AppColors.success,
              width: isWide ? (constraints.maxWidth - AppSpacing.md * 3) / 4 : (constraints.maxWidth - AppSpacing.md) / 2,
            ),
            _buildKpiCard(
              context,
              title: 'Avg Yield',
              value: '${s.overallYieldPct.toStringAsFixed(1)}%',
              icon: Icons.percent_outlined,
              color: AppColors.secondary,
              width: isWide ? (constraints.maxWidth - AppSpacing.md * 3) / 4 : (constraints.maxWidth - AppSpacing.md) / 2,
            ),
            _buildKpiCard(
              context,
              title: 'Packed Bags',
              value: '${s.totalPackedBags}',
              icon: Icons.inventory_2_outlined,
              color: AppColors.warning,
              width: isWide ? (constraints.maxWidth - AppSpacing.md * 3) / 4 : (constraints.maxWidth - AppSpacing.md) / 2,
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              foregroundColor: color,
              radius: 20,
              child: Icon(icon, size: 22),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.neutralSecondary)),
                  Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(WidgetRef ref, BiogasFilterState filter) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text('All Uses'),
            selected: filter.usageType == null,
            onSelected: (_) => ref.read(biogasFilterProvider.notifier).setUsageType(null),
          ),
          const SizedBox(width: AppSpacing.sm),
          ...BiogasUsageType.values.map((u) {
            final isSelected = filter.usageType == u;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FilterChip(
                label: Text(u.label),
                selected: isSelected,
                onSelected: (_) => ref.read(biogasFilterProvider.notifier).setUsageType(isSelected ? null : u),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRunCard(BuildContext context, BiogasRunModel run) {
    Color usageColor;
    switch (run.usageType) {
      case BiogasUsageType.storeStock:
        usageColor = AppColors.primary;
        break;
      case BiogasUsageType.directSale:
        usageColor = AppColors.success;
        break;
      case BiogasUsageType.internalFarm:
        usageColor = AppColors.secondary;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Run Number & Usage Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.fireplace_outlined, color: AppColors.primary, size: 20),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      run.runNumber ?? 'RUN-${run.id.substring(0, 8)}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: usageColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    run.usageType.label,
                    style: TextStyle(color: usageColor, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Date and Moisture
            Row(
              children: [
                const Icon(Icons.event, size: 14, color: AppColors.neutralSecondary),
                const SizedBox(width: 4),
                Text(run.recordDate, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: AppSpacing.md),
                const Icon(Icons.opacity, size: 14, color: AppColors.neutralSecondary),
                const SizedBox(width: 4),
                Text('Moisture: ${run.moisturePct}%', style: Theme.of(context).textTheme.bodySmall),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Yield: ${run.yieldPct}%',
                    style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const Divider(height: AppSpacing.lg),

            // Production Metrics
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricColumn('Slurry Input', '${run.slurryInputKg.toStringAsFixed(1)} kg'),
                _buildMetricColumn('Dry Output', '${run.dryFertiliserOutputKg.toStringAsFixed(1)} kg'),
                _buildMetricColumn('Total Packed', '${run.totalPackedKg.toStringAsFixed(1)} kg'),
              ],
            ),

            // Bag breakdown badges if bags were packed
            if (run.totalPackedKg > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  if (run.bags1kg > 0) _buildBagBadge('${run.bags1kg} × 1kg'),
                  if (run.bags5kg > 0) _buildBagBadge('${run.bags5kg} × 5kg'),
                  if (run.bags25kg > 0) _buildBagBadge('${run.bags25kg} × 25kg'),
                  if (run.bags50kg > 0) _buildBagBadge('${run.bags50kg} × 50kg'),
                ],
              ),
            ],

            // Target or Sale info
            if (run.buyerOrFarmPlot != null && run.buyerOrFarmPlot!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                run.usageType == BiogasUsageType.directSale
                    ? 'Buyer: ${run.buyerOrFarmPlot}${run.saleAmount != null ? " (₹${run.saleAmount!.toStringAsFixed(2)})" : ""}'
                    : 'Target Plot: ${run.buyerOrFarmPlot}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              ),
            ],

            if (run.notes != null && run.notes!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Notes: ${run.notes}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.neutralSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.neutralSecondary)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildBagBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.neutralLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.neutralBorder),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          children: [
            Icon(Icons.energy_savings_leaf_outlined, size: 64, color: AppColors.neutralSecondary.withOpacity(0.5)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No Biogas Runs Found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Record slurry input and dry bio-fertiliser production runs to track yields and inventory.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.neutralSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
