import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_drawer.dart';
import '../domain/material_models.dart';
import 'material_provider.dart';
import 'widgets/record_material_issue_dialog.dart';

class MaterialsScreen extends ConsumerStatefulWidget {
  const MaterialsScreen({super.key});

  @override
  ConsumerState<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends ConsumerState<MaterialsScreen> {
  IssueDepartment? _selectedDept;

  void _openRecordDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const RecordMaterialIssueDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final issuesAsync = ref.watch(materialIssuesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Material Issues'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(materialIssuesProvider),
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/materials'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openRecordDialog,
        icon: const Icon(Icons.add),
        label: const Text('Issue Material'),
      ),
      body: issuesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text('Failed to load material issues: $err'),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () => ref.invalidate(materialIssuesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (data) {
          final items = data.items;
          final totalCost = items.fold<double>(0.0, (sum, i) => sum + (i.totalCost ?? 0.0));
          final farmCost = items
              .where((i) => i.department == IssueDepartment.farm)
              .fold<double>(0.0, (sum, i) => sum + (i.totalCost ?? 0.0));
          final prodCost = items
              .where((i) => i.department == IssueDepartment.production)
              .fold<double>(0.0, (sum, i) => sum + (i.totalCost ?? 0.0));

          final filteredItems = _selectedDept == null
              ? items
              : items.where((i) => i.department == _selectedDept).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(materialIssuesProvider),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // Cost Metrics Row
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Total Issued',
                        '₹${totalCost.toStringAsFixed(0)}',
                        Icons.payments_outlined,
                        AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _buildMetricCard(
                        'Farm Care',
                        '₹${farmCost.toStringAsFixed(0)}',
                        Icons.grass_outlined,
                        AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _buildMetricCard(
                        'Production',
                        '₹${prodCost.toStringAsFixed(0)}',
                        Icons.blender_outlined,
                        AppColors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Department Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        selected: _selectedDept == null,
                        label: const Text('All Cost Centers'),
                        onSelected: (_) => setState(() => _selectedDept = null),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        selected: _selectedDept == IssueDepartment.farm,
                        label: const Text('Farm'),
                        onSelected: (_) => setState(() => _selectedDept = IssueDepartment.farm),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        selected: _selectedDept == IssueDepartment.production,
                        label: const Text('Production'),
                        onSelected: (_) => setState(() => _selectedDept = IssueDepartment.production),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        selected: _selectedDept == IssueDepartment.biogas,
                        label: const Text('Biogas'),
                        onSelected: (_) => setState(() => _selectedDept = IssueDepartment.biogas),
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
                        const Icon(Icons.outbox_outlined, size: 64, color: AppColors.neutral400),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No material issues recorded',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.neutral600),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Text('Issue cleaning supplies, consumables, packaging or minerals.'),
                        const SizedBox(height: AppSpacing.lg),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Issue Material'),
                          onPressed: _openRecordDialog,
                        ),
                      ],
                    ),
                  )
                else
                  ...filteredItems.map((item) => _buildIssueCard(item)),
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
            Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueCard(MaterialIssueModel item) {
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
                        item.department.label,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(item.recordDate, style: const TextStyle(fontSize: 12, color: AppColors.neutral600)),
                  ],
                ),
                if (item.totalCost != null)
                  Text(
                    '₹${item.totalCost!.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                  ),
              ],
            ),
            const Divider(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.stockItemName ?? 'Item: ${item.stockItemId}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    if (item.issuedTo != null)
                      Text('Issued to: ${item.issuedTo}', style: const TextStyle(fontSize: 12, color: AppColors.neutral600)),
                  ],
                ),
                Text(
                  '${item.quantity.toStringAsFixed(1)} ${item.stockItemUnit ?? 'units'}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                ),
              ],
            ),
            if (item.productionBatchId != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.qr_code, size: 14, color: AppColors.neutral600),
                  const SizedBox(width: 4),
                  Text(
                    'Batch: ${item.batchNumber ?? item.productionBatchId}',
                    style: const TextStyle(fontSize: 11, color: AppColors.neutral600),
                  ),
                ],
              ),
            ],
            if (item.notes != null && item.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Note: ${item.notes}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }
}
