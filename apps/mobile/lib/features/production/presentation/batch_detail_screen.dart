import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/chips/app_status_chip.dart';
import '../domain/production_models.dart';
import 'production_provider.dart';

class BatchDetailScreen extends ConsumerWidget {
  final String batchId;

  const BatchDetailScreen({super.key, required this.batchId});

  void _showStatusDialog(BuildContext context, WidgetRef ref, ProductionTraceabilityModel batch) {
    QualityReleaseStatus selectedRelease = batch.qualityRelease;
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Update Quality Release Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<QualityReleaseStatus>(
                value: selectedRelease,
                decoration: const InputDecoration(labelText: 'Release Status'),
                items: QualityReleaseStatus.values
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedRelease = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'QC Audit Notes',
                  hintText: 'Lab test results, approval rationale...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final repo = ref.read(productionRepositoryProvider);
                await repo.updateBatchStatus(
                  batchId,
                  qualityRelease: selectedRelease,
                  notes: notesController.text.trim(),
                );
                ref.invalidate(productionTraceabilityProvider(batchId));
                ref.invalidate(productionBatchesProvider);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Save Status'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final traceAsync = ref.watch(productionTraceabilityProvider(batchId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Traceability'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(productionTraceabilityProvider(batchId)),
          ),
        ],
      ),
      body: traceAsync.when(
        data: (batch) => _buildContent(context, ref, batch),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                const SizedBox(height: 12),
                Text('Error loading batch: $err', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(productionTraceabilityProvider(batchId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, ProductionTraceabilityModel batch) {
    AppStatusType statusType = AppStatusType.warning;
    if (batch.qualityRelease == QualityReleaseStatus.approved) statusType = AppStatusType.success;
    if (batch.qualityRelease == QualityReleaseStatus.rejected) statusType = AppStatusType.danger;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Top Overview Card
        Card(
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(batch.batchNumber, style: AppTypography.titleLarge),
                        Text(batch.productType.label, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
                      ],
                    ),
                    AppStatusChip(label: batch.qualityRelease.label, type: statusType),
                  ],
                ),
                const SizedBox(height: 16),

                // Metrics Grid
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildField('Finished Output', '${batch.finishedQuantity.toStringAsFixed(1)} ${batch.unitOfMeasure}'),
                          _buildField('Milk Consumed', '${batch.bmcMilkConsumedL.toStringAsFixed(1)} L'),
                          _buildField('Conversion Yield', '${batch.yieldPercentage.toStringAsFixed(1)}%'),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildField('LPG Used', '${batch.lpgUsedKg.toStringAsFixed(1)} kg'),
                          _buildField('By-Products', '${batch.byproductQuantityKg.toStringAsFixed(1)} kg'),
                          _buildField('Expires On', batch.expiryDate),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Operator: ${batch.processOperator ?? "Staff"}', style: AppTypography.bodySmall),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Update QC Status'),
                      onPressed: () => _showStatusDialog(context, ref, batch),
                    ),
                  ],
                ),
                if (batch.notes != null) ...[
                  const SizedBox(height: 8),
                  Text('Notes: ${batch.notes}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // End-to-End Lineage Timeline Section
        Row(
          children: [
            const Icon(Icons.timeline, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('End-to-End Lineage Traceability', style: AppTypography.titleLarge),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Traces contributing raw milk intake lots from Farm or Suppliers through to finished output goods.',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.md),

        // Contributing Intake Lots
        Text(
          '1. Contributing Raw Milk Intake Lots (${batch.intakeLots.length})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),

        if (batch.intakeLots.isEmpty)
          Card(
            color: Colors.amber.shade50,
            child: const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text(
                'No specific intake lots linked to this batch. Milk was drawn from general BMC tank pool.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          )
        else
          ...batch.intakeLots.map((lot) => _buildIntakeLotCard(lot)),

        const SizedBox(height: AppSpacing.md),

        // Step 2: Processing & Conversion Card
        Text('2. Processing & Conversion Phase', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recipe & Heating Process', style: AppTypography.titleMedium),
                const SizedBox(height: 6),
                Text('• BMC Milk Converted: ${batch.bmcMilkConsumedL.toStringAsFixed(1)} Litres'),
                Text('• Energy Consumed: ${batch.lpgUsedKg.toStringAsFixed(1)} kg LPG'),
                Text('• By-Products Recovered: ${batch.byproductQuantityKg.toStringAsFixed(1)} kg (Whey / Buttermilk)'),
                Text('• Shift / Process Date: ${batch.recordDate} (${batch.shift})'),
                Text('• Authorized Operator: ${batch.processOperator ?? "Processing Staff"}'),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Step 3: Finished Output & Release Card
        Text('3. Finished Goods & Quality Release', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Output: ${batch.finishedQuantity.toStringAsFixed(1)} ${batch.unitOfMeasure}', style: AppTypography.titleMedium),
                    AppStatusChip(label: batch.qualityRelease.label, type: statusType),
                  ],
                ),
                const SizedBox(height: 6),
                Text('• Efficiency Yield: ${batch.yieldPercentage.toStringAsFixed(1)}%'),
                Text('• Product Expiry Date: ${batch.expiryDate}'),
                Text('• Batch Status: ${batch.status.label}'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }

  Widget _buildIntakeLotCard(TraceabilityIntakeLot lot) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade300, width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.input_outlined, size: 18, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(lot.intakeBatchNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Text(
                  '${lot.litresUsedInBatch.toStringAsFixed(1)} L used',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${lot.source} • ${lot.supplierRoute ?? "Direct Parlour"} • Date: ${lot.recordDate} (${lot.shift})',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: [
                if (lot.fatPercentage != null) _buildMiniQc('Fat ${lot.fatPercentage!.toStringAsFixed(2)}%'),
                if (lot.snfPercentage != null) _buildMiniQc('SNF ${lot.snfPercentage!.toStringAsFixed(2)}%'),
                if (lot.temperatureC != null) _buildMiniQc('${lot.temperatureC!.toStringAsFixed(1)}°C'),
                if (lot.clr != null) _buildMiniQc('CLR ${lot.clr!.toStringAsFixed(1)}'),
                if (lot.ph != null) _buildMiniQc('pH ${lot.ph!.toStringAsFixed(2)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniQc(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
    );
  }
}
