import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/wastage_repository.dart';
import '../domain/wastage_models.dart';

final wastageRepositoryProvider = Provider<WastageRepository>((ref) {
  return WastageRepository();
});

class WastageFilterState {
  final String? startDate;
  final String? endDate;
  final StockType? stockType;
  final WastageReason? reason;
  final int page;

  const WastageFilterState({
    this.startDate,
    this.endDate,
    this.stockType,
    this.reason,
    this.page = 1,
  });

  WastageFilterState copyWith({
    String? startDate,
    String? endDate,
    StockType? stockType,
    WastageReason? reason,
    int? page,
    bool clearStockType = false,
    bool clearReason = false,
  }) {
    return WastageFilterState(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      stockType: clearStockType ? null : (stockType ?? this.stockType),
      reason: clearReason ? null : (reason ?? this.reason),
      page: page ?? this.page,
    );
  }
}

class WastageFilterNotifier extends Notifier<WastageFilterState> {
  @override
  WastageFilterState build() => const WastageFilterState();

  void setStockType(StockType? type) =>
      state = state.copyWith(stockType: type, clearStockType: type == null);

  void setReason(WastageReason? r) =>
      state = state.copyWith(reason: r, clearReason: r == null);

  void setDateRange(String? start, String? end) =>
      state = state.copyWith(startDate: start, endDate: end);

  void setPage(int p) => state = state.copyWith(page: p);

  void reset() => state = const WastageFilterState();
}

final wastageFilterProvider =
    NotifierProvider<WastageFilterNotifier, WastageFilterState>(WastageFilterNotifier.new);

final wastageRecordsProvider = FutureProvider<
    ({List<WastageRecordModel> items, int total, int totalPages, WastageSummaryModel summary})>((ref) async {
  final repo = ref.watch(wastageRepositoryProvider);
  final filter = ref.watch(wastageFilterProvider);

  return repo.fetchRecords(
    page: filter.page,
    startDate: filter.startDate,
    endDate: filter.endDate,
    stockType: filter.stockType?.apiValue,
    reason: filter.reason?.apiValue,
  );
});
