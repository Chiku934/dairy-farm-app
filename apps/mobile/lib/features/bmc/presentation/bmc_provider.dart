import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/bmc_repository.dart';
import '../domain/bmc_models.dart';

final bmcRepositoryProvider = Provider<BmcRepository>((ref) {
  return BmcRepository();
});

class BmcFilterState {
  final String? date;
  final IntakeShift? shift;
  final MilkIntakeSource? source;
  final IntakeDecision? decision;
  final String? search;

  const BmcFilterState({
    this.date,
    this.shift,
    this.source,
    this.decision,
    this.search,
  });

  BmcFilterState copyWith({
    String? date,
    IntakeShift? shift,
    MilkIntakeSource? source,
    IntakeDecision? decision,
    String? search,
    bool clearDate = false,
    bool clearShift = false,
    bool clearSource = false,
    bool clearDecision = false,
  }) {
    return BmcFilterState(
      date: clearDate ? null : (date ?? this.date),
      shift: clearShift ? null : (shift ?? this.shift),
      source: clearSource ? null : (source ?? this.source),
      decision: clearDecision ? null : (decision ?? this.decision),
      search: search ?? this.search,
    );
  }
}

class BmcFilterNotifier extends Notifier<BmcFilterState> {
  @override
  BmcFilterState build() => const BmcFilterState();

  void setDate(String? date) => state = state.copyWith(date: date, clearDate: date == null);
  void setShift(IntakeShift? shift) => state = state.copyWith(shift: shift, clearShift: shift == null);
  void setSource(MilkIntakeSource? source) => state = state.copyWith(source: source, clearSource: source == null);
  void setDecision(IntakeDecision? decision) => state = state.copyWith(decision: decision, clearDecision: decision == null);
  void setSearch(String search) => state = state.copyWith(search: search);
  void reset() => state = const BmcFilterState();
}

final bmcFilterProvider =
    NotifierProvider<BmcFilterNotifier, BmcFilterState>(BmcFilterNotifier.new);

final bmcIntakeListProvider = FutureProvider<({List<BmcIntakeLogModel> items, int total, int totalPages})>((ref) async {
  final repo = ref.watch(bmcRepositoryProvider);
  final filter = ref.watch(bmcFilterProvider);

  return repo.fetchIntakes(
    date: filter.date,
    shift: filter.shift,
    source: filter.source,
    decision: filter.decision,
    search: filter.search,
  );
});

final bmcTankBalanceProvider = FutureProvider<BmcTankBalanceModel>((ref) async {
  final repo = ref.watch(bmcRepositoryProvider);
  return repo.fetchTankBalance();
});
