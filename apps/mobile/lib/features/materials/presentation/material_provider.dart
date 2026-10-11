import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/material_repository.dart';
import '../domain/material_models.dart';

final materialRepositoryProvider = Provider<MaterialRepository>((ref) {
  return MaterialRepository();
});

class MaterialFilterState {
  final IssueDepartment? department;
  final String? stockItemId;
  final String? batchId;
  final String? startDate;
  final String? endDate;
  final int page;

  const MaterialFilterState({
    this.department,
    this.stockItemId,
    this.batchId,
    this.startDate,
    this.endDate,
    this.page = 1,
  });

  MaterialFilterState copyWith({
    IssueDepartment? department,
    String? stockItemId,
    String? batchId,
    String? startDate,
    String? endDate,
    int? page,
    bool clearDepartment = false,
  }) {
    return MaterialFilterState(
      department: clearDepartment ? null : (department ?? this.department),
      stockItemId: stockItemId ?? this.stockItemId,
      batchId: batchId ?? this.batchId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      page: page ?? this.page,
    );
  }
}

class MaterialFilterNotifier extends Notifier<MaterialFilterState> {
  @override
  MaterialFilterState build() => const MaterialFilterState();

  void setDepartment(IssueDepartment? d) => state = state.copyWith(department: d, clearDepartment: d == null);
  void setStockItemId(String? id) => state = state.copyWith(stockItemId: id);
  void setBatchId(String? id) => state = state.copyWith(batchId: id);
  void setStartDate(String? d) => state = state.copyWith(startDate: d);
  void setEndDate(String? d) => state = state.copyWith(endDate: d);
  void setPage(int p) => state = state.copyWith(page: p);
  void reset() => state = const MaterialFilterState();
}

final materialFilterProvider =
    NotifierProvider<MaterialFilterNotifier, MaterialFilterState>(MaterialFilterNotifier.new);

final materialIssuesProvider = FutureProvider<({List<MaterialIssueModel> items, int total, int totalPages})>((ref) async {
  final repo = ref.watch(materialRepositoryProvider);
  final filter = ref.watch(materialFilterProvider);

  return repo.fetchIssues(
    page: filter.page,
    department: filter.department,
    stockItemId: filter.stockItemId,
    batchId: filter.batchId,
    startDate: filter.startDate,
    endDate: filter.endDate,
  );
});
