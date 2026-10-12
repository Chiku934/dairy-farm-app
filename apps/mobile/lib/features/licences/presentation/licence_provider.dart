import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/licence_repository.dart';
import '../domain/licence_models.dart';

final licenceRepositoryProvider = Provider<LicenceRepository>((ref) {
  return LicenceRepository();
});

class LicenceFilterState {
  final String? search;
  final LicenceType? type;
  final LicenceStatus? status;
  final ReminderStatus? reminderStatus;
  final int page;

  const LicenceFilterState({
    this.search,
    this.type,
    this.status,
    this.reminderStatus,
    this.page = 1,
  });

  LicenceFilterState copyWith({
    String? search,
    LicenceType? type,
    LicenceStatus? status,
    ReminderStatus? reminderStatus,
    int? page,
    bool clearType = false,
    bool clearStatus = false,
    bool clearReminderStatus = false,
    bool clearSearch = false,
  }) {
    return LicenceFilterState(
      search: clearSearch ? null : (search ?? this.search),
      type: clearType ? null : (type ?? this.type),
      status: clearStatus ? null : (status ?? this.status),
      reminderStatus: clearReminderStatus ? null : (reminderStatus ?? this.reminderStatus),
      page: page ?? this.page,
    );
  }
}

class LicenceFilterNotifier extends Notifier<LicenceFilterState> {
  @override
  LicenceFilterState build() => const LicenceFilterState();

  void setSearch(String? q) =>
      state = state.copyWith(search: q, clearSearch: q == null || q.isEmpty);

  void setType(LicenceType? t) =>
      state = state.copyWith(type: t, clearType: t == null);

  void setStatus(LicenceStatus? s) =>
      state = state.copyWith(status: s, clearStatus: s == null);

  void setReminderStatus(ReminderStatus? rs) =>
      state = state.copyWith(reminderStatus: rs, clearReminderStatus: rs == null);

  void reset() => state = const LicenceFilterState();
}

final licenceFilterProvider =
    NotifierProvider<LicenceFilterNotifier, LicenceFilterState>(LicenceFilterNotifier.new);

final licencesListProvider = FutureProvider<
    ({List<RegulatoryLicenceModel> items, int total, int page, int limit})>((ref) async {
  final repo = ref.watch(licenceRepositoryProvider);
  final filter = ref.watch(licenceFilterProvider);

  return repo.fetchLicences(
    page: filter.page,
    search: filter.search,
    type: filter.type,
    status: filter.status,
    reminderStatus: filter.reminderStatus,
  );
});
