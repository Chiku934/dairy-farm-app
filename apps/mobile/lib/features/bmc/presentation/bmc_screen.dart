import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/chips/app_status_chip.dart';
import '../domain/bmc_models.dart';
import 'bmc_provider.dart';
import 'widgets/record_intake_dialog.dart';

class BmcScreen extends ConsumerWidget {
  const BmcScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(bmcTankBalanceProvider);
    final intakeAsync = ref.watch(bmcIntakeListProvider);
    final filter = ref.watch(bmcFilterProvider);
    final filterNotifier = ref.read(bmcFilterProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('BMC & Milk Intake'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(bmcTankBalanceProvider);
              ref.invalidate(bmcIntakeListProvider);
            },
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/bmc'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const RecordIntakeDialog(),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Record Intake', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(bmcTankBalanceProvider);
          ref.invalidate(bmcIntakeListProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // BMC Tank Balance Ledger Card
            balanceAsync.when(
              data: (balance) => _buildTankLedgerCard(context, balance),
              loading: () => const Center(
                child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator()),
              ),
              error: (err, _) => Card(
                color: AppColors.danger.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Error loading tank balance: $err'),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Search & Filter Card
            _buildFilterCard(context, filter, filterNotifier),
            const SizedBox(height: AppSpacing.md),

            // Intake Logs List
            intakeAsync.when(
              data: (data) {
                if (data.items.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(Icons.local_shipping_outlined, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text('No milk intake records found', style: AppTypography.titleMedium),
                          const SizedBox(height: 6),
                          Text(
                            'Click "+ Record Intake" to log farm or external collection sessions.',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: data.items.map((item) => _buildIntakeCard(context, item)).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()),
              ),
              error: (err, _) => Card(
                color: AppColors.danger.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Error loading intake logs: $err'),
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildTankLedgerCard(BuildContext context, BmcTankBalanceModel balance) {
    AppStatusType statusType = AppStatusType.success;
    if (balance.status == 'WARNING') statusType = AppStatusType.warning;
    if (balance.status == 'CRITICAL') statusType = AppStatusType.danger;

    final progressVal = (balance.utilizationPercentage / 100.0).clamp(0.0, 1.0);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      child: const Icon(Icons.storage_outlined, color: AppColors.primary),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bulk Milk Cooler (BMC)', style: AppTypography.titleMedium),
                        Text(
                          'Capacity: ${balance.capacityLitres.toStringAsFixed(0)} L',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
                AppStatusChip(
                  label: '${balance.utilizationPercentage.toStringAsFixed(1)}% Full',
                  type: statusType,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Balance Metric
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${balance.currentBalanceLitres.toStringAsFixed(1)} L',
                  style: AppTypography.headlineLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(
                  '/ ${balance.capacityLitres.toStringAsFixed(0)} L Live Tank Balance',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progressVal,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  balance.status == 'CRITICAL'
                      ? AppColors.danger
                      : balance.status == 'WARNING'
                          ? Colors.orange
                          : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Ledger Metrics Row
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSubMetric('Total Accepted', '${balance.totalAcceptedIntake.toStringAsFixed(0)} L', AppColors.primary),
                  _buildSubMetric('Sent to Prod.', '${balance.totalProductionConsumed.toStringAsFixed(0)} L', Colors.indigo),
                  _buildSubMetric('BMC Wastage', '${balance.totalWastageLost.toStringAsFixed(1)} L', AppColors.danger),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }

  Widget _buildFilterCard(
    BuildContext context,
    BmcFilterState filter,
    BmcFilterNotifier notifier,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search batch number, route, operator...',
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

            // Source Filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All Sources'),
                    selected: filter.source == null,
                    onSelected: (_) => notifier.setSource(null),
                  ),
                  const SizedBox(width: 6),
                  FilterChip(
                    label: const Text('Farm Only'),
                    selected: filter.source == MilkIntakeSource.farm,
                    onSelected: (_) => notifier.setSource(MilkIntakeSource.farm),
                  ),
                  const SizedBox(width: 6),
                  FilterChip(
                    label: const Text('External Suppliers'),
                    selected: filter.source == MilkIntakeSource.external,
                    onSelected: (_) => notifier.setSource(MilkIntakeSource.external),
                  ),
                  const SizedBox(width: 12),
                  FilterChip(
                    label: const Text('Morning (AM)'),
                    selected: filter.shift == IntakeShift.am,
                    onSelected: (selected) => notifier.setShift(selected ? IntakeShift.am : null),
                  ),
                  const SizedBox(width: 6),
                  FilterChip(
                    label: const Text('Evening (PM)'),
                    selected: filter.shift == IntakeShift.pm,
                    onSelected: (selected) => notifier.setShift(selected ? IntakeShift.pm : null),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntakeCard(BuildContext context, BmcIntakeLogModel item) {
    final isAccepted = item.decision == IntakeDecision.accepted;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: item.shift == IntakeShift.am ? Colors.amber.shade50 : Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item.shift == IntakeShift.am ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined,
                color: item.shift == IntakeShift.am ? Colors.amber.shade800 : Colors.indigo,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.batchNumber, style: AppTypography.titleMedium),
                      Text(
                        '${item.quantityLitres.toStringAsFixed(1)} L',
                        style: AppTypography.titleLarge.copyWith(
                          color: isAccepted ? AppColors.primary : AppColors.danger,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(item.source.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      if (item.supplierRoute != null) ...[
                        Text(' • ${item.supplierRoute}', style: AppTypography.bodySmall),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),

                  // QC Metrics Chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (item.fatPercentage != null) _buildQcBadge('Fat ${item.fatPercentage!.toStringAsFixed(2)}%'),
                      if (item.snfPercentage != null) _buildQcBadge('SNF ${item.snfPercentage!.toStringAsFixed(2)}%'),
                      if (item.temperatureC != null) _buildQcBadge('${item.temperatureC!.toStringAsFixed(1)}°C'),
                      if (item.ph != null) _buildQcBadge('pH ${item.ph!.toStringAsFixed(2)}'),
                    ],
                  ),

                  if (!isAccepted && item.rejectionReason != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Rejection: ${item.rejectionReason}',
                      style: const TextStyle(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.w500),
                    ),
                  ],

                  const SizedBox(height: 6),
                  Text(
                    '${item.recordDate} • ${item.shift.value} • ${item.operatorName ?? "Staff"}',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppStatusChip(
              label: item.decision.label,
              type: isAccepted ? AppStatusType.success : AppStatusType.danger,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQcBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }
}
