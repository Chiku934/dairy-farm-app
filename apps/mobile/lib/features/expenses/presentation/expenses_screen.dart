import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/cards/app_card.dart';
import '../domain/expense_models.dart';
import 'expense_provider.dart';
import 'widgets/record_expense_dialog.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  void _openRecordDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const RecordExpenseDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(operatingExpensesProvider);
    final filter = ref.watch(expenseFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Costs & Operating Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(operatingExpensesProvider),
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/expenses'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openRecordDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Record Expense'),
      ),
      body: expensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text('Failed to load expenses: $err'),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () => ref.invalidate(operatingExpensesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (data) {
          final items = data.items;
          final summary = data.summary;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(operatingExpensesProvider),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // 1. KPI Cost Centre Breakdown
                _buildKpiGrid(context, summary),
                const SizedBox(height: AppSpacing.lg),

                // 2. Filter Chips
                _buildFilterChips(ref, filter),
                const SizedBox(height: AppSpacing.md),

                // 3. Expenses List or Empty State
                if (items.isEmpty)
                  _buildEmptyState(context)
                else
                  ...items.map((e) => _buildExpenseCard(context, e)),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildKpiGrid(BuildContext context, ExpenseSummaryModel s) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _buildKpiCard(
              context,
              title: 'Total Expenses',
              value: '₹${s.totalExpenses.toStringAsFixed(0)}',
              icon: Icons.account_balance_wallet_outlined,
              color: AppColors.primary,
              width: isWide ? (constraints.maxWidth - AppSpacing.md * 3) / 4 : (constraints.maxWidth - AppSpacing.md) / 2,
            ),
            _buildKpiCard(
              context,
              title: 'Farm Centre',
              value: '₹${s.farmExpenses.toStringAsFixed(0)}',
              icon: Icons.grass_outlined,
              color: AppColors.success,
              width: isWide ? (constraints.maxWidth - AppSpacing.md * 3) / 4 : (constraints.maxWidth - AppSpacing.md) / 2,
            ),
            _buildKpiCard(
              context,
              title: 'Production Plant',
              value: '₹${s.productionExpenses.toStringAsFixed(0)}',
              icon: Icons.factory_outlined,
              color: AppColors.secondary,
              width: isWide ? (constraints.maxWidth - AppSpacing.md * 3) / 4 : (constraints.maxWidth - AppSpacing.md) / 2,
            ),
            _buildKpiCard(
              context,
              title: 'Biogas Unit',
              value: '₹${s.biogasExpenses.toStringAsFixed(0)}',
              icon: Icons.energy_savings_leaf_outlined,
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

  Widget _buildFilterChips(WidgetRef ref, ExpenseFilterState filter) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text('All Centres'),
            selected: filter.costCentre == null,
            onSelected: (_) => ref.read(expenseFilterProvider.notifier).setCostCentre(null),
          ),
          const SizedBox(width: AppSpacing.sm),
          ...CostCentre.values.map((c) {
            final isSelected = filter.costCentre == c;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FilterChip(
                label: Text(c.label),
                selected: isSelected,
                onSelected: (_) => ref.read(expenseFilterProvider.notifier).setCostCentre(isSelected ? null : c),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(BuildContext context, OperatingExpenseModel e) {
    Color centreColor;
    switch (e.costCentre) {
      case CostCentre.farm:
        centreColor = AppColors.success;
        break;
      case CostCentre.production:
        centreColor = AppColors.secondary;
        break;
      case CostCentre.biogas:
        centreColor = AppColors.warning;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Expense Number & Cost Centre Tag
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long_outlined, color: AppColors.primary, size: 20),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      e.expenseNumber ?? 'EXP-${e.id.substring(0, 8)}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: centreColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    e.costCentre.label,
                    style: TextStyle(color: centreColor, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Date & Category & Amount
            Row(
              children: [
                const Icon(Icons.event, size: 14, color: AppColors.neutralSecondary),
                const SizedBox(width: 4),
                Text(e.recordDate, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.neutralLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.neutralBorder),
                  ),
                  child: Text(
                    e.category.label,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ),
                const Spacer(),
                Text(
                  '₹${e.amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                ),
              ],
            ),
            const Divider(height: AppSpacing.lg),

            // Payee & Payment Method
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (e.payee != null && e.payee!.isNotEmpty)
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.storefront_outlined, size: 16, color: AppColors.neutralSecondary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            e.payee!,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    e.paymentMethod.label,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.primary),
                  ),
                ),
              ],
            ),

            if (e.invoiceNumber != null && e.invoiceNumber!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Invoice Ref: ${e.invoiceNumber}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              ),
            ],

            if (e.notes != null && e.notes!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Notes: ${e.notes}',
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
            Icon(Icons.receipt_outlined, size: 64, color: AppColors.neutralSecondary.withOpacity(0.5)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No Operating Expenses Recorded',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Record operational expenditures across farm, production, and biogas to monitor unit costs.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.neutralSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
