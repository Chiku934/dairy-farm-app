import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/chips/app_status_chip.dart';
import '../domain/costing_models.dart';
import 'costing_provider.dart';

class CostingScreen extends ConsumerWidget {
  const CostingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final costingAsync = ref.watch(dailyMilkCostingProvider);
    final selectedDate = ref.watch(costingSelectedDateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unit Costing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(dailyMilkCostingProvider),
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/costing'),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(dailyMilkCostingProvider),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // Date Filter Bar
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Costing Date:', style: AppTypography.titleMedium),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate != null ? DateTime.parse(selectedDate) : DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          ref.read(costingSelectedDateProvider.notifier).setDate(
                              picked.toIso8601String().split('T')[0]);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              selectedDate ?? 'Today (Live)',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Costing Results Card
            costingAsync.when(
              data: (costing) => _buildCostingView(context, costing),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(48.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Error loading unit costing: $err', style: const TextStyle(color: Colors.red)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostingView(BuildContext context, DailyMilkCostingModel costing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cost per Litre Hero Card
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Farm Milk Cost per Litre', style: AppTypography.titleLarge),
                    AppStatusChip(
                      label: costing.status,
                      type: costing.isComplete ? AppStatusType.success : AppStatusType.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (costing.isComplete) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${costing.currency} ${costing.costPerLitre!.toStringAsFixed(2)}',
                        style: AppTypography.headlineLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('/ litre of eligible milk', style: TextStyle(color: AppColors.textMuted)),
                    ],
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            costing.warningMessage ?? 'No eligible milk recorded for this date. Cost per litre cannot be computed.',
                            style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Divider(height: 24),

                // Operational Milk Volumes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetric('Eligible Milk', '${costing.eligibleMilkLitres.toStringAsFixed(1)} L', AppColors.primary),
                    _buildMetric('Total Milk', '${costing.totalMilkRecordedLitres.toStringAsFixed(1)} L', AppColors.textMain),
                    _buildMetric('Withheld', '${costing.withheldMilkLitres.toStringAsFixed(1)} L', costing.withheldMilkLitres > 0 ? AppColors.danger : AppColors.textMuted),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Total Farm Operating Cost & Component Breakdown
        Text('Daily Cost Breakdown (${costing.currency} ${costing.totalDailyFarmCost.toStringAsFixed(2)})', style: AppTypography.titleMedium),
        const SizedBox(height: 8),

        Card(
          child: Column(
            children: [
              _buildCostRow('Feed Consumed', costing.breakdown.feedCost, costing.currency, Icons.grass),
              const Divider(height: 1),
              _buildCostRow('Veterinary & Medicines', costing.breakdown.medicineCost, costing.currency, Icons.medical_services_outlined),
              const Divider(height: 1),
              _buildCostRow('Other Farm Materials', costing.breakdown.materialsCost, costing.currency, Icons.inventory_2_outlined),
              const Divider(height: 1),
              _buildCostRow('Daily Farm Salaries (Prorated)', costing.breakdown.dailySalaries, costing.currency, Icons.badge_outlined),
              const Divider(height: 1),
              _buildCostRow(
                costing.breakdown.isElectricityDefaulted ? 'Electricity (Defaulted 50 kWh)' : 'Farm Electricity',
                costing.breakdown.electricityCost,
                costing.currency,
                Icons.bolt,
                subtitle: costing.breakdown.isElectricityDefaulted ? 'No meter reading logged for date' : null,
              ),
              const Divider(height: 1),
              _buildCostRow('Other Operational Expenses', costing.breakdown.otherExpenses, costing.currency, Icons.account_balance_wallet_outlined),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildCostRow(String title, double amount, String currency, IconData icon, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyMedium),
                if (subtitle != null) ...[
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ],
            ),
          ),
          Text(
            '$currency ${amount.toStringAsFixed(2)}',
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
