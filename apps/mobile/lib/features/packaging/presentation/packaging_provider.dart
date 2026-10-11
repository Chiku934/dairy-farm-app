import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/packaging_repository.dart';
import '../domain/packaging_models.dart';

final packagingRepositoryProvider = Provider<PackagingRepository>((ref) {
  return PackagingRepository();
});

class PackagingFilterState {
  final String? batchId;
  final String? startDate;
  final String? endDate;
  final int page;

  const PackagingFilterState({
    this.batchId,
    this.startDate,
    this.endDate,
    this.page = 1,
  });

  PackagingFilterState copyWith({
    String? batchId,
    String? startDate,
    String? endDate,
    int? page,
  }) {
    return PackagingFilterState(
      batchId: batchId ?? this.batchId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      page: page ?? this.page,
    );
  }
}

class PackagingFilterNotifier extends Notifier<PackagingFilterState> {
  @override
  PackagingFilterState build() => const PackagingFilterState();

  void setBatchId(String? id) => state = state.copyWith(batchId: id);
  void setStartDate(String? d) => state = state.copyWith(startDate: d);
  void setEndDate(String? d) => state = state.copyWith(endDate: d);
  void setPage(int p) => state = state.copyWith(page: p);
  void reset() => state = const PackagingFilterState();
}

final packagingFilterProvider =
    NotifierProvider<PackagingFilterNotifier, PackagingFilterState>(PackagingFilterNotifier.new);

final packagingRunsProvider = FutureProvider<({List<PackagingRunModel> items, int total, int totalPages})>((ref) async {
  final repo = ref.watch(packagingRepositoryProvider);
  final filter = ref.watch(packagingFilterProvider);

  return repo.fetchRuns(
    page: filter.page,
    batchId: filter.batchId,
    startDate: filter.startDate,
    endDate: filter.endDate,
  );
});

final batchPackagingRunsProvider = FutureProvider.family<List<PackagingRunModel>, String>((ref, batchId) async {
  final repo = ref.watch(packagingRepositoryProvider);
  return repo.fetchRunsByBatch(batchId);
});
