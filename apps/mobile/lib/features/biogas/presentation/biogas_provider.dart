import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/biogas_repository.dart';
import '../domain/biogas_models.dart';

final biogasRepositoryProvider = Provider<BiogasRepository>((ref) {
  return BiogasRepository();
});

class BiogasFilterState {
  final String? startDate;
  final String? endDate;
  final BiogasUsageType? usageType;
  final int page;

  const BiogasFilterState({
    this.startDate,
    this.endDate,
    this.usageType,
    this.page = 1,
  });

  BiogasFilterState copyWith({
    String? startDate,
    String? endDate,
    BiogasUsageType? usageType,
    int? page,
    bool clearUsageType = false,
  }) {
    return BiogasFilterState(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      usageType: clearUsageType ? null : (usageType ?? this.usageType),
      page: page ?? this.page,
    );
  }
}

class BiogasFilterNotifier extends Notifier<BiogasFilterState> {
  @override
  BiogasFilterState build() => const BiogasFilterState();

  void setUsageType(BiogasUsageType? type) =>
      state = state.copyWith(usageType: type, clearUsageType: type == null);

  void setDateRange(String? start, String? end) =>
      state = state.copyWith(startDate: start, endDate: end);

  void setPage(int p) => state = state.copyWith(page: p);

  void reset() => state = const BiogasFilterState();
}

final biogasFilterProvider =
    NotifierProvider<BiogasFilterNotifier, BiogasFilterState>(BiogasFilterNotifier.new);

final biogasRunsProvider = FutureProvider<
    ({List<BiogasRunModel> items, int total, int totalPages, BiogasSummaryModel summary})>((ref) async {
  final repo = ref.watch(biogasRepositoryProvider);
  final filter = ref.watch(biogasFilterProvider);

  return repo.fetchRuns(
    page: filter.page,
    startDate: filter.startDate,
    endDate: filter.endDate,
    usageType: filter.usageType?.apiValue,
  );
});
