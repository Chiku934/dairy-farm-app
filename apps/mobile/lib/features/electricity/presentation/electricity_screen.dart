import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_drawer.dart';
import '../domain/electricity_models.dart';
import 'electricity_provider.dart';
import 'widgets/record_electricity_dialog.dart';

class ElectricityScreen extends ConsumerStatefulWidget {
  const ElectricityScreen({super.key});

  @override
  ConsumerState<ElectricityScreen> createState() => _ElectricityScreenState();
}

class _ElectricityScreenState extends ConsumerState<ElectricityScreen> {
  ElectricityDepartment? _selectedDept;

  void _openRecordDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const RecordElectricityDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final readingsAsync = ref.watch(electricityReadingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Electricity Readings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(electricityReadingsProvider),
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/electricity'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openRecordDialog,
        icon: const Icon(Icons.add),
        label: const Text('Log Meter Reading'),
      ),
      body: readingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text('Failed to load electricity readings: $err'),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () => ref.invalidate(electricityReadingsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (data) {
          final items = data.items;
          final totalKwh = items.fold<double>(0.0, (sum, r) => sum + r.unitsKwh);
          final totalCost = items.fold<double>(0.0, (sum, r) => sum + r.totalCost);
          final farmKwh = items
              .where((r) => r.department == ElectricityDepartment.farm)
              .fold<double>(0.0, (sum, r) => sum + r.unitsKwh);
          final prodKwh = items
              .where((r) => r.department == ElectricityDepartment.production)
              .fold<double>(0.0, (sum, r) => sum + r.unitsKwh);

          final filteredItems = _selectedDept == null
              ? items
              : items.where((r) => r.department == _selectedDept).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(electricityReadingsProvider),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // Metrics Row
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Total Energy',
                        '${totalKwh.toStringAsFixed(0)} kWh',
                        Icons.bolt,
                        AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _buildMetricCard(
                        'Total Cost',
                        '₹${totalCost.toStringAsFixed(0)}',
                        Icons.currency_rupee,
                        AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _buildMetricCard(
                        'Farm / Prod',
                        '${farmKwh.toStringAsFixed(0)} / ${prodKwh.toStringAsFixed(0)}',
                        Icons.pie_chart_outline,
                        AppColors.secondary,
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
                        label: const Text('All Meters'),
                        onSelected: (_) => setState(() => _selectedDept = null),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        selected: _selectedDept == ElectricityDepartment.farm,
                        label: const Text('Farm Meter'),
                        onSelected: (_) => setState(() => _selectedDept = ElectricityDepartment.farm),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        selected: _selectedDept == ElectricityDepartment.production,
                        label: const Text('Production Hall'),
                        onSelected: (_) => setState(() => _selectedDept = ElectricityDepartment.production),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        selected: _selectedDept == ElectricityDepartment.biogas,
                        label: const Text('Biogas Meter'),
                        onSelected: (_) => setState(() => _selectedDept = ElectricityDepartment.biogas),
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
                        const Icon(Icons.bolt_outlined, size: 64, color: AppColors.neutral400),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No meter readings recorded',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.neutral600),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Text('Track daily opening and closing meter units across departments.'),
                        const SizedBox(height: AppSpacing.lg),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Log Meter Reading'),
                          onPressed: _openRecordDialog,
                        ),
                      ],
                    ),
                  )
                else
                  ...filteredItems.map((r) => _buildReadingCard(r)),
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
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingCard(ElectricityReadingModel r) {
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
                        color: AppColors.warning.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        r.department.label,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(r.recordDate, style: const TextStyle(fontSize: 12, color: AppColors.neutral600)),
                  ],
                ),
                Text(
                  '₹${r.totalCost.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                ),
              ],
            ),
            const Divider(height: AppSpacing.md),
            Row(
              children: [
                if (r.openingReadingKwh != null && r.closingReadingKwh != null) ...[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Counters (Open → Close)', style: TextStyle(fontSize: 10, color: AppColors.neutral600)),
                        Text('${r.openingReadingKwh!.toStringAsFixed(1)} → ${r.closingReadingKwh!.toStringAsFixed(1)}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Consumption', style: TextStyle(fontSize: 10, color: AppColors.neutral600)),
                      Text('${r.unitsKwh.toStringAsFixed(1)} kWh',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tariff Rate', style: TextStyle(fontSize: 10, color: AppColors.neutral600)),
                      Text('₹${r.tariffRate.toStringAsFixed(2)}/kWh',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    ],
                  ),
                ),
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
}
