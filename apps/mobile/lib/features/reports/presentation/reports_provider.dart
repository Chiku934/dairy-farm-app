import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/reports_repository.dart';
import '../domain/report_models.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository();
});

class ReportFilterState {
  final ReportType selectedType;
  final String? startDate;
  final String? endDate;
  final String? search;
  final String? filterKey;
  final int page;

  const ReportFilterState({
    this.selectedType = ReportType.milkProduction,
    this.startDate,
    this.endDate,
    this.search,
    this.filterKey,
    this.page = 1,
  });

  ReportFilterState copyWith({
    ReportType? selectedType,
    String? startDate,
    String? endDate,
    String? search,
    String? filterKey,
    int? page,
    bool clearDates = false,
    bool clearSearch = false,
    bool clearFilterKey = false,
  }) {
    return ReportFilterState(
      selectedType: selectedType ?? this.selectedType,
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      search: clearSearch ? null : (search ?? this.search),
      filterKey: clearFilterKey ? null : (filterKey ?? this.filterKey),
      page: page ?? this.page,
    );
  }
}

class ReportFilterNotifier extends Notifier<ReportFilterState> {
  @override
  ReportFilterState build() => const ReportFilterState();

  void setReportType(ReportType type) =>
      state = state.copyWith(selectedType: type, page: 1, clearSearch: true, clearFilterKey: true);

  void setDateRange(String? start, String? end) =>
      state = state.copyWith(startDate: start, endDate: end, page: 1);

  void setSearch(String? query) =>
      state = state.copyWith(search: query, clearSearch: query == null || query.isEmpty, page: 1);

  void setFilterKey(String? key) =>
      state = state.copyWith(filterKey: key, clearFilterKey: key == null || key.isEmpty, page: 1);

  void setPage(int p) => state = state.copyWith(page: p);

  void reset() => state = const ReportFilterState();
}

final reportFilterProvider =
    NotifierProvider<ReportFilterNotifier, ReportFilterState>(ReportFilterNotifier.new);

final activeReportDataProvider = FutureProvider<ReportResultModel>((ref) async {
  final repo = ref.watch(reportsRepositoryProvider);
  final filter = ref.watch(reportFilterProvider);

  return repo.fetchReport(
    filter.selectedType,
    startDate: filter.startDate,
    endDate: filter.endDate,
    search: filter.search,
    filterKey: filter.filterKey,
    page: filter.page,
  );
});
