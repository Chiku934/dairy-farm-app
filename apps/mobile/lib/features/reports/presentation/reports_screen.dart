import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_drawer.dart';
import '../domain/report_models.dart';
import 'reports_provider.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(reportFilterProvider);
    final filterNotifier = ref.read(reportFilterProvider.notifier);
    final reportAsync = ref.watch(activeReportDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enterprise Reports & Exports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export CSV',
            onPressed: () async {
              try {
                final csvData = await ref.read(reportsRepositoryProvider).exportReportCsv(
                      filter.selectedType,
                      startDate: filter.startDate,
                      endDate: filter.endDate,
                      filterKey: filter.filterKey,
                      search: filter.search,
                    );
                if (context.mounted) {
                  final lineCount = csvData.trim().split('\r\n').length;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Successfully generated formula-safe CSV for ${filter.selectedType.title} ($lineCount lines)',
                      ),
                      backgroundColor: Colors.green.shade800,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to export CSV: $e'),
                      backgroundColor: Colors.red.shade800,
                    ),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(activeReportDataProvider),
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/reports'),
      body: Column(
        children: [
          // Report Type Selector Bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            color: Theme.of(context).cardColor,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ReportType.values.map((type) {
                  final isSelected = filter.selectedType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      avatar: Icon(type.icon, size: 16),
                      label: Text(type.title),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) filterNotifier.setReportType(type);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1),

          // Security Alert for Sensitive Reports
          if (filter.selectedType.isSensitive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.amber.shade100,
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, size: 20, color: Colors.amber.shade900),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Confidential Data: Staff salaries & wage rates require HR Admin or Finance clearance.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Date & Search Filter Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search within ${filter.selectedType.title}...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (val) => filterNotifier.setSearch(val),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.date_range, size: 18),
                  label: Text(
                    filter.startDate != null
                        ? '${filter.startDate} - ${filter.endDate ?? "Now"}'
                        : 'Filter Dates',
                  ),
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      final s =
                          "${picked.start.year.toString().padLeft(4, '0')}-${picked.start.month.toString().padLeft(2, '0')}-${picked.start.day.toString().padLeft(2, '0')}";
                      final e =
                          "${picked.end.year.toString().padLeft(4, '0')}-${picked.end.month.toString().padLeft(2, '0')}-${picked.end.day.toString().padLeft(2, '0')}";
                      filterNotifier.setDateRange(s, e);
                    }
                  },
                ),
                if (filter.startDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    tooltip: 'Clear Date Filter',
                    onPressed: () => filterNotifier.setDateRange(null, null),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Report Content Area
          Expanded(
            child: reportAsync.when(
              data: (result) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // KPI Summary Card
                      _buildSummaryCard(context, filter.selectedType, result.summary),
                      const SizedBox(height: 16),

                      // Preview Data Records Table
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Data Records (${result.total} total)',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.download, size: 16),
                            label: const Text('Export CSV'),
                            onPressed: () async {
                              final csv = await ref
                                  .read(reportsRepositoryProvider)
                                  .exportReportCsv(filter.selectedType);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('CSV generated (${csv.length} bytes, formula-safe)'),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (result.items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                            child: Text(
                              'No records found matching filters',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: result.items.first.keys
                                    .map(
                                      (k) => DataColumn(
                                        label: Text(
                                          k.toUpperCase().replaceAll('_', ' '),
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                rows: result.items.take(30).map((row) {
                                  return DataRow(
                                    cells: row.values
                                        .map((v) => DataCell(Text(v?.toString() ?? '')))
                                        .toList(),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_person_outlined, size: 54, color: Colors.orange),
                      const SizedBox(height: 12),
                      Text(
                        'Access Denied or Failed to Load Report',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        err.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(activeReportDataProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    ReportType type,
    Map<String, dynamic> summary,
  ) {
    switch (type) {
      case ReportType.milkProduction:
        return _buildKpiRow([
          _KpiItem('Total Yield', '${summary['totalYieldLitres'] ?? 0} L', Colors.blue),
          _KpiItem('Withheld Volume', '${summary['withheldLitres'] ?? 0} L', Colors.red),
          _KpiItem('Shift Logs', '${summary['recordCount'] ?? 0}', Colors.teal),
        ]);
      case ReportType.sales:
        return _buildKpiRow([
          _KpiItem('Gross Revenue', '₹${summary['totalSales'] ?? 0}', Colors.green),
          _KpiItem('Payments Received', '₹${summary['totalPaid'] ?? 0}', Colors.teal),
          _KpiItem('Outstanding Receivables', '₹${summary['totalBalance'] ?? 0}', Colors.orange),
        ]);
      case ReportType.expenses:
        return _buildKpiRow([
          _KpiItem('Total Expenses', '₹${summary['totalExpenses'] ?? 0}', Colors.red),
          _KpiItem('Farm Operations', '₹${summary['farmExpenses'] ?? 0}', Colors.blue),
          _KpiItem('Plant Processing', '₹${summary['productionExpenses'] ?? 0}', Colors.orange),
          _KpiItem('Biogas Unit', '₹${summary['biogasExpenses'] ?? 0}', Colors.teal),
        ]);
      case ReportType.herd:
        return _buildKpiRow([
          _KpiItem('Total Headcount', '${summary['totalHeadCount'] ?? 0}', Colors.blueGrey),
          _KpiItem('Lactating Cows', '${summary['lactatingCount'] ?? 0}', Colors.green),
          _KpiItem('Dry Cows', '${summary['dryCount'] ?? 0}', Colors.amber),
          _KpiItem('Medical Withholding', '${summary['withheldCount'] ?? 0}', Colors.red),
        ]);
      case ReportType.inventory:
        return _buildKpiRow([
          _KpiItem('Total Valuation', '₹${summary['totalValuation'] ?? 0}', Colors.teal),
          _KpiItem('Total Stock Items', '${summary['totalItems'] ?? 0}', Colors.blue),
          _KpiItem('Low Stock Warnings', '${summary['lowStockCount'] ?? 0}', Colors.red),
        ]);
      case ReportType.staffPayroll:
        return _buildKpiRow([
          _KpiItem('Permanent Headcount', '${summary['totalEmployees'] ?? 0}', Colors.blue),
          _KpiItem('Active Staff', '${summary['activeEmployees'] ?? 0}', Colors.green),
          _KpiItem('Monthly Salary Budget', '₹${summary['totalMonthlySalary'] ?? 0}', Colors.purple),
          _KpiItem('Daily Wage Liability', '₹${summary['totalDailyRate'] ?? 0}', Colors.indigo),
        ]);
      case ReportType.licences:
        return _buildKpiRow([
          _KpiItem('Total Licences', '${summary['totalLicences'] ?? 0}', Colors.blueGrey),
          _KpiItem('Active Permits', '${summary['activeLicences'] ?? 0}', Colors.green),
          _KpiItem('Expiring Soon', '${summary['expiringSoonLicences'] ?? 0}', Colors.amber),
          _KpiItem('Expired / Non-Compliant', '${summary['expiredLicences'] ?? 0}', Colors.red),
        ]);
    }
  }

  Widget _buildKpiRow(List<_KpiItem> items) {
    return Row(
      children: items
          .map(
            (item) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: item.color.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Text(
                      item.value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: item.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _KpiItem {
  final String label;
  final String value;
  final Color color;

  _KpiItem(this.label, this.value, this.color);
}
