import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/chips/app_status_chip.dart';
import '../domain/feed_models.dart';
import 'feed_provider.dart';
import 'widgets/record_feed_dialog.dart';
import 'widgets/create_ration_dialog.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedAnimalForCalculator = 'c-01';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed & Ration Planning'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long), text: 'Feed Issuance'),
            Tab(icon: Icon(Icons.menu_book), text: 'Rations & Diets'),
            Tab(icon: Icon(Icons.calculate), text: 'Target Calculator'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(feedEntriesProvider);
              ref.invalidate(rationsProvider);
            },
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/feed'),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const RecordFeedDialog(),
                );
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Issue Feed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : (_tabController.index == 1
              ? FloatingActionButton.extended(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const CreateRationDialog(),
                    );
                  },
                  backgroundColor: AppColors.primary,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('New Ration', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
              : null),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFeedIssuanceTab(),
          _buildRationsTab(),
          _buildCalculatorTab(),
        ],
      ),
    );
  }

  Widget _buildFeedIssuanceTab() {
    final entriesAsync = ref.watch(feedEntriesProvider);

    return entriesAsync.when(
      data: (data) {
        if (data.items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textMuted),
                const SizedBox(height: 12),
                Text('No feed consumption logged', style: AppTypography.titleMedium),
                const SizedBox(height: 6),
                Text('Tap "Issue Feed" to record concentrate or fodder issues.', style: TextStyle(color: AppColors.textMuted)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: data.items.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text('Feed Issues (${data.total})', style: AppTypography.titleMedium),
              );
            }
            final item = data.items[index - 1];
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
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.grass, color: AppColors.primary, size: 24),
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
                                '${item.quantityKg.toStringAsFixed(1)} kg',
                                style: AppTypography.titleLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(item.stockItemName, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '${item.recordDate} • Cost: ₹${item.totalCost.toStringAsFixed(2)}',
                                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                              if (item.unitCost > 0) ...[
                                Text(
                                  ' (₹${item.unitCost.toStringAsFixed(2)}/kg)',
                                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppStatusChip(label: item.feedType.label, type: AppStatusType.neutral),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading feed: $err')),
    );
  }

  Widget _buildRationsTab() {
    final rationsAsync = ref.watch(rationsProvider);

    return rationsAsync.when(
      data: (rations) {
        if (rations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.menu_book, size: 48, color: AppColors.textMuted),
                const SizedBox(height: 12),
                Text('No ration formulations defined', style: AppTypography.titleMedium),
                const SizedBox(height: 6),
                Text('Tap "New Ration" to create your first standard diet.', style: TextStyle(color: AppColors.textMuted)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: rations.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final ration = rations[index];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(ration.name, style: AppTypography.titleMedium)),
                        AppStatusChip(label: ration.targetStage.label, type: AppStatusType.success),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(ration.code, style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    if (ration.description != null) ...[
                      const SizedBox(height: 4),
                      Text(ration.description!, style: AppTypography.bodySmall),
                    ],
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Daily Quantity', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text('${ration.totalQuantityKg.toStringAsFixed(1)} kg', style: AppTypography.titleMedium),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Formulation Cost', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text('₹${ration.totalCost.toStringAsFixed(2)}', style: AppTypography.titleMedium),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Unit Cost / kg', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(
                              '₹${ration.unitCostPerKg.toStringAsFixed(2)}',
                              style: AppTypography.titleMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Ingredients Breakdown:', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    ...ration.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('• ${item.stockItemName}', style: AppTypography.bodySmall),
                              Text('${item.quantityKg.toStringAsFixed(1)} kg @ ₹${item.unitPrice.toStringAsFixed(2)} = ₹${item.itemCost.toStringAsFixed(2)}',
                                  style: AppTypography.bodySmall),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading rations: $err')),
    );
  }

  Widget _buildCalculatorTab() {
    final targetAsync = ref.watch(concentrateTargetProvider(_selectedAnimalForCalculator));

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Selector Header
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select Cow for Calculation', style: AppTypography.titleMedium),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedAnimalForCalculator,
                  decoration: const InputDecoration(
                    labelText: 'Cattle Ear Tag',
                    prefixIcon: Icon(Icons.pets),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'c-01', child: Text('Cow #210385 (Lactating - High Yielder)')),
                    DropdownMenuItem(value: 'c-02', child: Text('Cow #210386 (Lactating - Average Yielder)')),
                    DropdownMenuItem(value: 'c-03', child: Text('Cow #210387 (Lactating - Under Treatment)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedAnimalForCalculator = val);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Formula Calculation Result
        targetAsync.when(
          data: (result) => Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Target Concentrate', style: AppTypography.titleLarge),
                      AppStatusChip(label: result.status, type: AppStatusType.success),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Daily Concentrate Target', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(
                              '${result.targetConcentrateKg.toStringAsFixed(2)} kg / day',
                              style: AppTypography.headlineMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Icon(Icons.check_circle, color: AppColors.primary, size: 36),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Calculation Details (REQ-YD-06):', style: AppTypography.titleMedium),
                  const SizedBox(height: 8),
                  Text('• 7-Day Average Daily Milk: ${result.avgDailyYieldLitres.toStringAsFixed(2)} L/day (${result.daysEvaluated} days evaluated)'),
                  const SizedBox(height: 4),
                  Text('• Base Allowance: ${result.feedBaseKg.toStringAsFixed(2)} kg'),
                  const SizedBox(height: 4),
                  Text('• Production Rate: ${result.feedRatePerLitre.toStringAsFixed(2)} kg per litre of milk yield'),
                  const SizedBox(height: 4),
                  Text('• Maximum Cap: ${result.feedMaxCapKg.toStringAsFixed(2)} kg/day ceiling'),
                  const SizedBox(height: 8),
                  Text(
                    'Formula: min(${result.feedBaseKg} + (${result.avgDailyYieldLitres} × ${result.feedRatePerLitre}), ${result.feedMaxCapKg}) = ${result.targetConcentrateKg} kg',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator())),
          error: (err, _) => Center(child: Text('Calculation error: $err')),
        ),
      ],
    );
  }
}
