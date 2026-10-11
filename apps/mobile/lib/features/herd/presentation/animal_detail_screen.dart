import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/herd_models.dart';
import 'herd_provider.dart';
import 'widgets/animal_form_modal.dart';
import 'widgets/archive_animal_dialog.dart';
import 'widgets/record_health_dialog.dart';
import 'widgets/record_breeding_dialog.dart';

class AnimalDetailScreen extends ConsumerStatefulWidget {
  final String animalId;

  const AnimalDetailScreen({
    super.key,
    required this.animalId,
  });

  @override
  ConsumerState<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends ConsumerState<AnimalDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshAll() {
    ref.invalidate(animalDetailProvider(widget.animalId));
    ref.invalidate(animalHistoryProvider(widget.animalId));
    ref.invalidate(animalHealthRecordsProvider(widget.animalId));
    ref.invalidate(animalBreedingRecordsProvider(widget.animalId));
    ref.invalidate(herdSummaryProvider);
    ref.invalidate(animalsListProvider);
  }

  void _openEditModal(AnimalModel animal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AnimalFormModal(
        initialAnimal: animal,
        onSave: (data) async {
          final repo = ref.read(herdRepositoryProvider);
          await repo.updateAnimal(animal.id, data);
          _refreshAll();
        },
      ),
    );
  }

  void _openArchiveDialog(AnimalModel animal) {
    showDialog(
      context: context,
      builder: (ctx) => ArchiveAnimalDialog(
        animal: animal,
        onConfirmArchive: ({required reason, status}) async {
          final repo = ref.read(herdRepositoryProvider);
          await repo.archiveAnimal(animal.id, reason: reason, status: status);
          _refreshAll();
        },
      ),
    );
  }

  void _openRecordHealthModal(AnimalModel animal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RecordHealthDialog(
        animalId: animal.id,
        animalTag: animal.earTag,
        onSave: (data) async {
          final repo = ref.read(animalHealthRepositoryProvider);
          await repo.createRecord(data);
          _refreshAll();
        },
      ),
    );
  }

  void _openRecordBreedingModal(AnimalModel animal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RecordBreedingDialog(
        animalId: animal.id,
        animalTag: animal.earTag,
        onSave: (data) async {
          final repo = ref.read(breedingRepositoryProvider);
          await repo.createRecord(data);
          _refreshAll();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final animalAsync = ref.watch(animalDetailProvider(widget.animalId));

    return animalAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Loading Animal Details...')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to load animal: $err', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _refreshAll,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (animal) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(animal.displayName),
          actions: [
            if (!animal.isArchived) ...[
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit details',
                onPressed: () => _openEditModal(animal),
              ),
              IconButton(
                icon: const Icon(Icons.archive_outlined),
                tooltip: 'Archive animal',
                onPressed: () => _openArchiveDialog(animal),
              ),
            ],
          ],
        ),
        body: Column(
          children: [
            // Top Hero Banner
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: animal.isArchived ? Colors.grey.shade100 : AppColors.primary50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: animal.isArchived ? Colors.grey.shade300 : AppColors.primary200,
                      ),
                    ),
                    child: Icon(
                      animal.sex == AnimalSex.male ? Icons.male : Icons.pets,
                      color: animal.isArchived ? Colors.grey : AppColors.primary700,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              animal.earTag,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                            if (animal.name != null && animal.name!.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Text(
                                '· ${animal.name}',
                                style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${animal.breed.replaceAll('_', ' ')} · ${animal.ageString}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: animal.isArchived ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      animal.isArchived ? 'ARCHIVED' : animal.status.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: animal.isArchived ? const Color(0xFF991B1B) : const Color(0xFF166534),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary700,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary700,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Bio'),
                  Tab(text: 'Timeline'),
                  Tab(text: 'Health'),
                  Tab(text: 'Breeding'),
                ],
              ),
            ),
            const Divider(height: 1),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBioTab(animal),
                  _buildTimelineTab(animal),
                  _buildHealthTab(animal),
                  _buildBreedingTab(animal),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBioTab(AnimalModel animal) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.borderSubtle),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Physical & Vital Metrics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  _buildInfoRow('Body Weight', animal.bodyWeightKg != null ? '${animal.bodyWeightKg} kg' : '--'),
                  _buildInfoRow('Condition Score (BCS)', animal.bodyConditionScore != null ? '${animal.bodyConditionScore} / 5.0' : '--'),
                  _buildInfoRow('Sex', animal.sex.label),
                  _buildInfoRow('Breed', animal.breed.replaceAll('_', ' ')),
                  _buildInfoRow('Date of Birth', animal.dateOfBirth ?? '--'),
                  _buildInfoRow('Dam (Mother) Tag', animal.damTag ?? '--'),
                  _buildInfoRow('Last Calved Date', animal.lastCalvingDate ?? '--'),
                  if (animal.isArchived) ...[
                    const Divider(),
                    _buildInfoRow('Archive Status', 'Archived / Retired'),
                    _buildInfoRow('Archive Reason', animal.archiveReason ?? '--'),
                  ],
                ],
              ),
            ),
          ),
          if (animal.notes != null && animal.notes!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.borderSubtle),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Notes & Clinical History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    Text(animal.notes!, style: const TextStyle(fontSize: 14, height: 1.4)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTimelineTab(AnimalModel animal) {
    final historyAsync = ref.watch(animalHistoryProvider(animal.id));

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load history: $e')),
      data: (data) {
        if (data.timeline.isEmpty) {
          return const Center(child: Text('No historical events recorded yet.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: data.timeline.length,
          itemBuilder: (context, idx) {
            final item = data.timeline[idx];

            IconData icon = Icons.event;
            Color iconColor = AppColors.primary700;
            if (item.type == 'HEALTH') {
              icon = Icons.medical_services_outlined;
              iconColor = Colors.red.shade700;
            } else if (item.type == 'BREEDING') {
              icon = Icons.favorite_outline;
              iconColor = Colors.purple.shade700;
            } else if (item.type == 'MILKING') {
              icon = Icons.water_drop_outlined;
              iconColor = Colors.blue.shade700;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 20, color: iconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.date,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                            ),
                            if (item.badge != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  item.badge!,
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(item.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        if (item.subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(item.subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHealthTab(AnimalModel animal) {
    final healthAsync = ref.watch(animalHealthRecordsProvider(animal.id));

    return Column(
      children: [
        if (!animal.isArchived)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Record Health / Treatment Log'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _openRecordHealthModal(animal),
              ),
            ),
          ),
        Expanded(
          child: healthAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Failed to load health records: $e')),
            data: (records) {
              if (records.isEmpty) {
                return const Center(child: Text('No health records found for this animal.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: records.length,
                itemBuilder: (ctx, idx) {
                  final h = records[idx];
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.borderSubtle),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(h.careType.label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary800)),
                              Text(h.recordDate, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (h.diagnosis != null && h.diagnosis!.isNotEmpty) ...[
                            Text('Diagnosis: ${h.diagnosis}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.red)),
                            const SizedBox(height: 2),
                          ],
                          Text('Rx: ${h.medicineVaccine} (${h.prescribedDose})', style: const TextStyle(fontSize: 13)),
                          if (h.withdrawalUntil != null) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(6)),
                              child: Text('Milk Withheld Until: ${h.withdrawalUntil}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                            ),
                          ],
                          if (h.nextDueDate != null) ...[
                            const SizedBox(height: 2),
                            Text('Next Due: ${h.nextDueDate}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBreedingTab(AnimalModel animal) {
    final breedingAsync = ref.watch(animalBreedingRecordsProvider(animal.id));

    return Column(
      children: [
        if (!animal.isArchived && animal.sex == AnimalSex.female)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Record Breeding / Calving Event'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _openRecordBreedingModal(animal),
              ),
            ),
          ),
        Expanded(
          child: breedingAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Failed to load breeding records: $e')),
            data: (records) {
              if (records.isEmpty) {
                return const Center(child: Text('No breeding records found for this animal.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: records.length,
                itemBuilder: (ctx, idx) {
                  final b = records[idx];
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.borderSubtle),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(b.eventType.label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                              Text(b.recordDate, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (b.sireSemenId != null) Text('Sire / Semen: ${b.sireSemenId}', style: const TextStyle(fontSize: 13)),
                          if (b.expectedCalvingDate != null) Text('Exp. Calving: ${b.expectedCalvingDate}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal)),
                          if (b.nextCheckDate != null) Text('Next Check: ${b.nextCheckDate}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          if (b.calfTag != null) Text('Calf Tag: ${b.calfTag}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          if (b.notes != null) Text(b.notes!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
