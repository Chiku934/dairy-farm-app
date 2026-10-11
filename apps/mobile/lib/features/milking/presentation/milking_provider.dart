import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/milking_repository.dart';
import '../domain/milking_models.dart';

final milkingRepositoryProvider = Provider<MilkingRepository>((ref) {
  return MilkingRepository();
});

class MilkingFilterState {
  final String? date;
  final MilkingSession? session;
  final MilkDisposition? disposition;
  final String? search;

  const MilkingFilterState({
    this.date,
    this.session,
    this.disposition,
    this.search,
  });

  MilkingFilterState copyWith({
    String? date,
    MilkingSession? session,
    MilkDisposition? disposition,
    String? search,
    bool clearDate = false,
    bool clearSession = false,
    bool clearDisposition = false,
  }) {
    return MilkingFilterState(
      date: clearDate ? null : (date ?? this.date),
      session: clearSession ? null : (session ?? this.session),
      disposition: clearDisposition ? null : (disposition ?? this.disposition),
      search: search ?? this.search,
    );
  }
}

class MilkingFilterNotifier extends Notifier<MilkingFilterState> {
  @override
  MilkingFilterState build() => const MilkingFilterState();

  void setDate(String? date) => state = state.copyWith(date: date, clearDate: date == null);
  void setSession(MilkingSession? session) => state = state.copyWith(session: session, clearSession: session == null);
  void setDisposition(MilkDisposition? disposition) => state = state.copyWith(disposition: disposition, clearDisposition: disposition == null);
  void setSearch(String search) => state = state.copyWith(search: search);
  void reset() => state = const MilkingFilterState();
}

final milkingFilterProvider =
    NotifierProvider<MilkingFilterNotifier, MilkingFilterState>(MilkingFilterNotifier.new);

final milkingLogsProvider = FutureProvider<({List<MilkingLogModel> items, int total, int totalPages})>((ref) async {
  final repo = ref.watch(milkingRepositoryProvider);
  final filter = ref.watch(milkingFilterProvider);

  return repo.fetchMilkingLogs(
    date: filter.date,
    session: filter.session,
    disposition: filter.disposition,
    search: filter.search,
  );
});

final milkingSummaryProvider = FutureProvider<MilkingSummaryModel>((ref) async {
  final repo = ref.watch(milkingRepositoryProvider);
  final filter = ref.watch(milkingFilterProvider);

  return repo.fetchSummary(
    startDate: filter.date,
    endDate: filter.date,
  );
});
