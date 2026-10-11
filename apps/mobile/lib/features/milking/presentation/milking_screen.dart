import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/cards/app_kpi_card.dart';
import '../../../core/widgets/chips/app_status_chip.dart';
import '../domain/milking_models.dart';
import 'milking_provider.dart';
import 'widgets/record_milking_dialog.dart';

class MilkingScreen extends ConsumerWidget {
  const MilkingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(milkingSummaryProvider);
    final logsAsync = ref.watch(milkingLogsProvider);
    final filter = ref.watch(milkingFilterProvider);
    final filterNotifier = ref.read(milkingFilterProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Milking Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(milkingLogsProvider);
              ref.invalidate(milkingSummaryProvider);
            },
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/milking'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const RecordMilkingDialog(),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Record Milking', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(milkingLogsProvider);
          ref.invalidate(milkingSummaryProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // KPI Summary Header
            summaryAsync.when(
              data: (summary) => _buildSummaryRow(context, summary),
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.md),

            // Filter Bar
            _buildFilterCard(context, filter, filterNotifier),
            const SizedBox(height: AppSpacing.md),

            // Logs List
            logsAsync.when(
              data: (data) {
                if (data.items.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(Icons.water_drop_outlined, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text('No milking sessions found', style: AppTypography.titleMedium),
                          const SizedBox(height: 6),
                          Text('Use "+ Record Milking" to add morning or evening cow yields.',
                              style: TextStyle(color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                      child: Text('Recorded Sessions (${data.total})', style: AppTypography.titleMedium),
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: data.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = data.items[index];
                        return _buildMilkingCard(context, item);
                      },
                    ),
                  ],
                );
              },
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator())),
              error: (err, _) => Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Error loading milking logs: $err', style: const TextStyle(color: Colors.red)),
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, MilkingSummaryModel summary) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 650;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            SizedBox(
              width: isWide ? (constraints.maxWidth - 24) / 4 : (constraints.maxWidth - 8) / 2,
              child: AppKpiCard(
                title: 'Eligible Milk',
                value: '${summary.eligibleLitres.toStringAsFixed(1)} L',
                subtitle: 'BMC collection pool',
                icon: Icons.check_circle_outline,
              ),
            ),
            SizedBox(
              width: isWide ? (constraints.maxWidth - 24) / 4 : (constraints.maxWidth - 8) / 2,
              child: AppKpiCard(
                title: 'Morning Shift',
                value: '${summary.morningLitres.toStringAsFixed(1)} L',
                subtitle: 'AM Yield',
                icon: Icons.wb_sunny_outlined,
              ),
            ),
            SizedBox(
              width: isWide ? (constraints.maxWidth - 24) / 4 : (constraints.maxWidth - 8) / 2,
              child: AppKpiCard(
                title: 'Evening Shift',
                value: '${summary.eveningLitres.toStringAsFixed(1)} L',
                subtitle: 'PM Yield',
                icon: Icons.nights_stay_outlined,
              ),
            ),
            SizedBox(
              width: isWide ? (constraints.maxWidth - 24) / 4 : (constraints.maxWidth - 8) / 2,
              child: AppKpiCard(
                title: 'Withheld / Calf',
                value: '${(summary.withheldLitres + summary.calfFeedingLitres).toStringAsFixed(1)} L',
                subtitle: '${summary.withheldLitres.toStringAsFixed(1)} L Withheld',
                icon: Icons.warning_amber_rounded,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterCard(
    BuildContext context,
    MilkingFilterState filter,
    MilkingFilterNotifier notifier,
  ) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: filter.date != null ? DateTime.parse(filter.date!) : DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        notifier.setDate(picked.toIso8601String().split('T')[0]);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Filter Date',
                        isDense: true,
                        prefixIcon: const Icon(Icons.calendar_today, size: 18),
                        suffixIcon: filter.date != null
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () => notifier.setDate(null),
                              )
                            : null,
                      ),
                      child: Text(filter.date ?? 'All Dates', style: AppTypography.bodySmall),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SegmentedButton<MilkingSession?>(
                  segments: const [
                    ButtonSegment(value: null, label: Text('All')),
                    ButtonSegment(value: MilkingSession.morning, label: Text('AM')),
                    ButtonSegment(value: MilkingSession.evening, label: Text('PM')),
                  ],
                  selected: {filter.session},
                  onSelectionChanged: (val) => notifier.setSession(val.first),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text('Disposition: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  FilterChip(
                    label: const Text('All'),
                    selected: filter.disposition == null,
                    onSelected: (_) => notifier.setDisposition(null),
                  ),
                  const SizedBox(width: 4),
                  FilterChip(
                    label: const Text('Eligible'),
                    selected: filter.disposition == MilkDisposition.eligible,
                    onSelected: (_) => notifier.setDisposition(MilkDisposition.eligible),
                  ),
                  const SizedBox(width: 4),
                  FilterChip(
                    label: const Text('Withheld'),
                    selected: filter.disposition == MilkDisposition.withheld,
                    onSelected: (_) => notifier.setDisposition(MilkDisposition.withheld),
                  ),
                  const SizedBox(width: 4),
                  FilterChip(
                    label: const Text('Calf'),
                    selected: filter.disposition == MilkDisposition.calfFeeding,
                    onSelected: (_) => notifier.setDisposition(MilkDisposition.calfFeeding),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilkingCard(BuildContext context, MilkingLogModel item) {
    AppStatusType chipStatus = AppStatusType.neutral;
    if (item.disposition == MilkDisposition.eligible) chipStatus = AppStatusType.success;
    if (item.disposition == MilkDisposition.withheld) chipStatus = AppStatusType.danger;
    if (item.disposition == MilkDisposition.calfFeeding) chipStatus = AppStatusType.warning;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: item.session == MilkingSession.morning
                    ? Colors.amber.shade50
                    : Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item.session == MilkingSession.morning ? Icons.wb_sunny : Icons.nights_stay,
                color: item.session == MilkingSession.morning ? Colors.orange : Colors.indigo,
                size: 24,
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
                      Text(item.targetTitle, style: AppTypography.titleMedium),
                      Text(
                        '${item.yieldLitres.toStringAsFixed(2)} L',
                        style: AppTypography.titleLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text('${item.recordDate} (${item.session.label})', style: AppTypography.bodySmall),
                      if (item.operatorName != null) ...[
                        const SizedBox(width: 8),
                        Text('• ${item.operatorName}', style: AppTypography.bodySmall),
                      ],
                    ],
                  ),
                  if (item.withheldReason != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Reason: ${item.withheldReason}',
                      style: const TextStyle(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.w500),
                    ),
                  ],
                  if (item.notes != null) ...[
                    const SizedBox(height: 4),
                    Text(item.notes!, style: AppTypography.bodySmall),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppStatusChip(label: item.disposition.label, type: chipStatus),
          ],
        ),
      ),
    );
  }
}
