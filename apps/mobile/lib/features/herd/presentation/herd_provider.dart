import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/herd_repository.dart';
import '../data/animal_health_repository.dart';
import '../data/breeding_repository.dart';
import '../domain/herd_models.dart';
import '../domain/health_models.dart';
import '../domain/breeding_models.dart';

// Repositories
final herdRepositoryProvider = Provider<HerdRepository>((ref) {
  return HerdRepository();
});

final animalHealthRepositoryProvider = Provider<AnimalHealthRepository>((ref) {
  return AnimalHealthRepository();
});

final breedingRepositoryProvider = Provider<BreedingRepository>((ref) {
  return BreedingRepository();
});

// Filters
class StatusFilterNotifier extends Notifier<AnimalStatus?> {
  @override
  AnimalStatus? build() => null; // null = all active

  void setFilter(AnimalStatus? status) => state = status;
}

final herdStatusFilterProvider =
    NotifierProvider<StatusFilterNotifier, AnimalStatus?>(StatusFilterNotifier.new);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

final herdSearchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

class IncludeArchivedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void set(bool val) => state = val;
}

final herdIncludeArchivedProvider =
    NotifierProvider<IncludeArchivedNotifier, bool>(IncludeArchivedNotifier.new);

// Summaries & Lists
final herdSummaryProvider = FutureProvider.autoDispose<HerdSummaryCountsModel>((ref) async {
  final repo = ref.watch(herdRepositoryProvider);
  return repo.fetchSummary();
});

final animalsListProvider = FutureProvider.autoDispose<List<AnimalModel>>((ref) async {
  final repo = ref.watch(herdRepositoryProvider);
  final status = ref.watch(herdStatusFilterProvider);
  final search = ref.watch(herdSearchQueryProvider);
  final includeArchived = ref.watch(herdIncludeArchivedProvider);

  final result = await repo.fetchAnimals(
    status: status,
    search: search.isNotEmpty ? search : null,
    includeArchived: includeArchived,
    limit: 100,
  );
  return result.items;
});

final animalDetailProvider = FutureProvider.family.autoDispose<AnimalModel, String>((ref, id) async {
  final repo = ref.watch(herdRepositoryProvider);
  return repo.fetchAnimal(id);
});

final animalHistoryProvider = FutureProvider.family.autoDispose<
    ({AnimalModel animal, List<AnimalTimelineItemModel> timeline}),
    String>((ref, id) async {
  final repo = ref.watch(herdRepositoryProvider);
  return repo.fetchHistory(id);
});

// Health & Reminders
final healthRemindersProvider = FutureProvider.autoDispose<List<HealthReminderModel>>((ref) async {
  final repo = ref.watch(animalHealthRepositoryProvider);
  return repo.fetchReminders();
});

final activeWithdrawalsProvider = FutureProvider.autoDispose<List<ActiveWithdrawalModel>>((ref) async {
  final repo = ref.watch(animalHealthRepositoryProvider);
  return repo.fetchWithdrawals();
});

final animalHealthRecordsProvider = FutureProvider.family.autoDispose<List<HealthRecordModel>, String?>((ref, animalId) async {
  final repo = ref.watch(animalHealthRepositoryProvider);
  final res = await repo.fetchRecords(animalId: animalId, limit: 50);
  return res.items;
});

// Breeding & Reminders
final breedingRemindersProvider = FutureProvider.autoDispose<List<BreedingReminderModel>>((ref) async {
  final repo = ref.watch(breedingRepositoryProvider);
  return repo.fetchReminders();
});

final animalBreedingRecordsProvider = FutureProvider.family.autoDispose<List<BreedingRecordModel>, String?>((ref, animalId) async {
  final repo = ref.watch(breedingRepositoryProvider);
  final res = await repo.fetchRecords(animalId: animalId, limit: 50);
  return res.items;
});
