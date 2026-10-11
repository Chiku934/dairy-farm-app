import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_drawer.dart';
import '../domain/herd_models.dart';
import 'herd_provider.dart';
import 'animal_detail_screen.dart';
import 'widgets/animal_card.dart';
import 'widgets/herd_filter_bar.dart';
import 'widgets/reminders_banner.dart';
import 'widgets/animal_form_modal.dart';

class HerdScreen extends ConsumerStatefulWidget {
  const HerdScreen({super.key});

  @override
  ConsumerState<HerdScreen> createState() => _HerdScreenState();
}

class _HerdScreenState extends ConsumerState<HerdScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCreateModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AnimalFormModal(
        onSave: (data) async {
          final repo = ref.read(herdRepositoryProvider);
          await repo.createAnimal(data);
          ref.invalidate(herdSummaryProvider);
          ref.invalidate(animalsListProvider);
        },
      ),
    );
  }

  void _navigateToDetail(AnimalModel animal) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => AnimalDetailScreen(animalId: animal.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(herdSummaryProvider);
    final animalsAsync = ref.watch(animalsListProvider);
    final withdrawalsAsync = ref.watch(activeWithdrawalsProvider);
    final healthRemindersAsync = ref.watch(healthRemindersProvider);
    final breedingRemindersAsync = ref.watch(breedingRemindersProvider);

    final selectedStatus = ref.watch(herdStatusFilterProvider);
    final includeArchived = ref.watch(herdIncludeArchivedProvider);

    final isWide = MediaQuery.of(context).size.width >= 720;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Herd & Calves Registry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh cattle records',
            onPressed: () {
              ref.invalidate(herdSummaryProvider);
              ref.invalidate(animalsListProvider);
              ref.invalidate(activeWithdrawalsProvider);
              ref.invalidate(healthRemindersProvider);
              ref.invalidate(breedingRemindersProvider);
            },
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/herd'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateModal,
        backgroundColor: AppColors.primary700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Register Cattle', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(herdSummaryProvider);
          ref.invalidate(animalsListProvider);
          ref.invalidate(activeWithdrawalsProvider);
          ref.invalidate(healthRemindersProvider);
          ref.invalidate(breedingRemindersProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Field
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by ear tag, name, breed or dam...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(herdSearchQueryProvider.notifier).setQuery('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderSubtle),
                  ),
                ),
                onChanged: (val) {
                  ref.read(herdSearchQueryProvider.notifier).setQuery(val.trim());
                },
              ),
              const SizedBox(height: 12),

              // Filter Chips
              summaryAsync.when(
                loading: () => const SizedBox(height: 38),
                error: (_, __) => const SizedBox.shrink(),
                data: (summary) => HerdFilterBar(
                  selectedStatus: selectedStatus,
                  includeArchived: includeArchived,
                  summary: summary,
                  onStatusChanged: (status) {
                    ref.read(herdStatusFilterProvider.notifier).setFilter(status);
                  },
                  onIncludeArchivedChanged: (inc) {
                    ref.read(herdIncludeArchivedProvider.notifier).set(inc);
                  },
                ),
              ),
              const SizedBox(height: 14),

              // Reminders & Safety Alerts Banner
              RemindersBanner(
                withdrawals: withdrawalsAsync.value ?? [],
                healthReminders: healthRemindersAsync.value ?? [],
                breedingReminders: breedingRemindersAsync.value ?? [],
                onAnimalSelected: (id) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => AnimalDetailScreen(animalId: id),
                    ),
                  );
                },
              ),

              // Cattle List Section
              animalsAsync.when(
                loading: () => Column(
                  children: List.generate(
                    4,
                    (index) => Container(
                      height: 80,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                error: (err, _) => Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, size: 40, color: Colors.red),
                      const SizedBox(height: 8),
                      Text(
                        'Failed to load herd: ${err.toString().replaceFirst("Exception: ", "")}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.refresh(animalsListProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (animals) {
                  if (animals.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pets, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'No Cattle Found',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Try clearing search keywords or choosing another lifecycle status.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () {
                              _searchController.clear();
                              ref.read(herdSearchQueryProvider.notifier).setQuery('');
                              ref.read(herdStatusFilterProvider.notifier).setFilter(null);
                              ref.read(herdIncludeArchivedProvider.notifier).set(false);
                            },
                            child: const Text('Reset All Filters'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (isWide) {
                    // Wide tablet view: 2 columns
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: animals.length,
                      itemBuilder: (context, index) {
                        return AnimalCard(
                          animal: animals[index],
                          onTap: () => _navigateToDetail(animals[index]),
                        );
                      },
                    );
                  }

                  // Single column phone view
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: animals.length,
                    itemBuilder: (context, index) {
                      return AnimalCard(
                        animal: animals[index],
                        onTap: () => _navigateToDetail(animals[index]),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
