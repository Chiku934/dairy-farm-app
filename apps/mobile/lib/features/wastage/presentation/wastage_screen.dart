import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/cards/app_card.dart';
import '../domain/wastage_models.dart';
import 'wastage_provider.dart';
import 'widgets/record_wastage_dialog.dart';

class WastageScreen extends ConsumerWidget {
  const WastageScreen({super.key});

  void _openRecordDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const RecordWastageDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wastageAsync = ref.watch(wastageRecordsProvider);
    final filter = ref.watch(wastageFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wastage & Losses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(wastageRecordsProvider),
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/wastage'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openRecordDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Record Wastage'),
      ),
      body: wastageAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text('Failed to load wastage records: $err'),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () => ref.invalidate(wastageRecordsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (data) {
          final items = data.items;
          final summary = data.summary;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(wastageRecordsProvider),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // 1. KPI Cards
                _buildKpiGrid(context, summary),
                const SizedBox(height: AppSpacing.lg),

                // 2. Filter Chips
                _buildFilterChips(ref, filter),
                const SizedBox(height: AppSpacing.md),

                // 3. Incidents List or Empty State
                if (items.isEmpty)
                  _buildEmptyState(context)
                else
                  ...items.map((w) => _buildWastageCard(context, w)),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildKpiGrid(BuildContext context, WastageSummaryModel s) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _buildKpiCard(
              context,
              title: 'Total Incidents',
              value: '${s.totalIncidents}',
              icon: Icons.report_problem_outlined,
              color: AppColors.error,
              width: isWide ? (constraints.maxWidth - AppSpacing.md * 3) / 4 : (constraints.maxWidth - AppSpacing.md) / 2,
            ),
            _buildKpiCard(
              context,
              title: 'Total Loss Cost',
              value: '₹${s.totalEstimatedLoss.toStringAsFixed(0)}',
              icon: Icons.currency_rupee,
              color: AppColors.error,
              width: isWide ? (constraints.maxWidth - AppSpacing.md * 3) / 4 : (constraints.maxWidth - AppSpacing.md) / 2,
            ),
            _buildKpiCard(
              context,
              title: 'Raw Milk Lost',
              value: '${s.bmcLossLitres.toStringAsFixed(1)} L',
              icon: Icons.water_drop_outlined,
              color: AppColors.warning,
              width: isWide ? (constraints.maxWidth - AppSpacing.md * 3) / 4 : (constraints.maxWidth - AppSpacing.md) / 2,
            ),
            _buildKpiCard(
              context,
              title: 'Supply Write-offs',
              value: '₹${s.supplyLossValue.toStringAsFixed(0)}',
              icon: Icons.inventory_2_outlined,
              color: AppColors.secondary,
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

  Widget _buildFilterChips(WidgetRef ref, WastageFilterState filter) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text('All Types'),
            selected: filter.stockType == null,
            onSelected: (_) => ref.read(wastageFilterProvider.notifier).setStockType(null),
          ),
          const SizedBox(width: AppSpacing.sm),
          ...StockType.values.map((t) {
            final isSelected = filter.stockType == t;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FilterChip(
                label: Text(t.label),
                selected: isSelected,
                onSelected: (_) => ref.read(wastageFilterProvider.notifier).setStockType(isSelected ? null : t),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWastageCard(BuildContext context, WastageRecordModel w) {
    Color typeColor;
    switch (w.stockType) {
      case StockType.bmc:
        typeColor = AppColors.primary;
        break;
      case StockType.supply:
        typeColor = AppColors.secondary;
        break;
      case StockType.packagedProduct:
      case StockType.bulkProduct:
        typeColor = AppColors.warning;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Wastage Number & Stock Type Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      w.wastageNumber ?? 'WST-${w.id.substring(0, 8)}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    w.stockType.label,
                    style: TextStyle(color: typeColor, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Date & Reason
            Row(
              children: [
                const Icon(Icons.event, size: 14, color: AppColors.neutralSecondary),
                const SizedBox(width: 4),
                Text(w.recordDate, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    w.reason.label,
                    style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 11),
                  ),
                ),
                const Spacer(),
                Text(
                  'Loss: ₹${w.estimatedLossCost.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const Divider(height: AppSpacing.lg),

            // Loss Quantity & Reference Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Quantity Written Off', style: TextStyle(fontSize: 11, color: AppColors.neutralSecondary)),
                    const SizedBox(height: 2),
                    Text(
                      '${w.quantityLost} ${w.unit}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Reference / Item', style: TextStyle(fontSize: 11, color: AppColors.neutralSecondary)),
                    const SizedBox(height: 2),
                    Text(
                      w.stockItemName ?? w.referenceId,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),

            if (w.notes != null && w.notes!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Notes: ${w.notes}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.neutralSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          children: [
            Icon(Icons.shield_outlined, size: 64, color: AppColors.success.withOpacity(0.6)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No Wastage or Losses Recorded',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Zero recorded spoilage or inventory losses for this period. Great operational control!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.neutralSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
