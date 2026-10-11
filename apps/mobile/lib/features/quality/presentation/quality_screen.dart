import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_drawer.dart';
import '../domain/quality_models.dart';
import 'quality_provider.dart';
import 'widgets/record_quality_dialog.dart';

class QualityScreen extends ConsumerStatefulWidget {
  const QualityScreen({super.key});

  @override
  ConsumerState<QualityScreen> createState() => _QualityScreenState();
}

class _QualityScreenState extends ConsumerState<QualityScreen> {
  QualityDecision? _selectedDecision;

  void _openRecordDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const RecordQualityDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(qualityRecordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quality Records'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(qualityRecordsProvider),
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/quality'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openRecordDialog,
        icon: const Icon(Icons.add),
        label: const Text('Log Quality Test'),
      ),
      body: recordsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text('Failed to load quality records: $err'),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () => ref.invalidate(qualityRecordsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (data) {
          final items = data.items;
          final approvedCount = items.where((i) => i.decision == QualityDecision.approved).length;
          final rejectedCount = items.where((i) => i.decision == QualityDecision.rejected).length;
          final pendingCount = items.where((i) => i.decision == QualityDecision.pending).length;

          final filteredItems = _selectedDecision == null
              ? items
              : items.where((i) => i.decision == _selectedDecision).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(qualityRecordsProvider),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // KPI Metrics Row
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard('Approved', '$approvedCount', Icons.check_circle_outline, AppColors.success),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _buildMetricCard('Rejected', '$rejectedCount', Icons.cancel_outlined, AppColors.error),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _buildMetricCard('Pending', '$pendingCount', Icons.hourglass_top_outlined, AppColors.warning),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Decision Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        selected: _selectedDecision == null,
                        label: const Text('All Tests'),
                        onSelected: (_) => setState(() => _selectedDecision = null),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        selected: _selectedDecision == QualityDecision.approved,
                        label: const Text('Approved'),
                        selectedColor: AppColors.success.withOpacity(0.2),
                        onSelected: (_) => setState(() => _selectedDecision = QualityDecision.approved),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        selected: _selectedDecision == QualityDecision.rejected,
                        label: const Text('Rejected'),
                        selectedColor: AppColors.error.withOpacity(0.2),
                        onSelected: (_) => setState(() => _selectedDecision = QualityDecision.rejected),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        selected: _selectedDecision == QualityDecision.pending,
                        label: const Text('Pending'),
                        selectedColor: AppColors.warning.withOpacity(0.2),
                        onSelected: (_) => setState(() => _selectedDecision = QualityDecision.pending),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                if (filteredItems.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        const Icon(Icons.verified_outlined, size: 64, color: AppColors.neutral400),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No quality test records found',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.neutral600),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Text('Record fat, SNF, and laboratory readings for batches or milk intake.'),
                        const SizedBox(height: AppSpacing.lg),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Log First Test'),
                          onPressed: _openRecordDialog,
                        ),
                      ],
                    ),
                  )
                else
                  ...filteredItems.map((r) => _buildQualityCard(r)),
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
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(title, style: const TextStyle(fontSize: 11, color: AppColors.neutral600)),
              ],
            ),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityCard(QualityRecordModel r) {
    final Color badgeColor = r.decision == QualityDecision.approved
        ? AppColors.success
        : (r.decision == QualityDecision.rejected ? AppColors.error : AppColors.warning);

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
                        color: AppColors.neutral100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        r.targetType.label,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ref: ${r.targetId.length > 12 ? r.targetId.substring(0, 12) : r.targetId}',
                      style: const TextStyle(fontSize: 12, color: AppColors.neutral700),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    r.decision.label.toUpperCase(),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: badgeColor),
                  ),
                ),
              ],
            ),
            const Divider(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _paramBox('Fat', r.fatPercentage != null ? '${r.fatPercentage!.toStringAsFixed(2)}%' : '--'),
                _paramBox('SNF', r.snfPercentage != null ? '${r.snfPercentage!.toStringAsFixed(2)}%' : '--'),
                _paramBox('CLR', r.clr != null ? r.clr!.toStringAsFixed(1) : '--'),
                _paramBox('pH', r.ph != null ? r.ph!.toStringAsFixed(2) : '--'),
                _paramBox('Temp', r.temperatureC != null ? '${r.temperatureC!.toStringAsFixed(1)}°C' : '--'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Date: ${r.recordDate}', style: const TextStyle(fontSize: 11, color: AppColors.neutral600)),
                if (r.testedBy != null)
                  Text('Tested by: ${r.testedBy}', style: const TextStyle(fontSize: 11, color: AppColors.neutral600)),
              ],
            ),
            if (r.notes != null && r.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Note: ${r.notes}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _paramBox(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.neutral600)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
