import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/electricity_repository.dart';
import '../domain/electricity_models.dart';

final electricityRepositoryProvider = Provider<ElectricityRepository>((ref) {
  return ElectricityRepository();
});

class ElectricityFilterState {
  final ElectricityDepartment? department;
  final String? startDate;
  final String? endDate;
  final int page;

  const ElectricityFilterState({
    this.department,
    this.startDate,
    this.endDate,
    this.page = 1,
  });

  ElectricityFilterState copyWith({
    ElectricityDepartment? department,
    String? startDate,
    String? endDate,
    int? page,
    bool clearDepartment = false,
  }) {
    return ElectricityFilterState(
      department: clearDepartment ? null : (department ?? this.department),
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      page: page ?? this.page,
    );
  }
}

class ElectricityFilterNotifier extends Notifier<ElectricityFilterState> {
  @override
  ElectricityFilterState build() => const ElectricityFilterState();

  void setDepartment(ElectricityDepartment? d) => state = state.copyWith(department: d, clearDepartment: d == null);
  void setStartDate(String? d) => state = state.copyWith(startDate: d);
  void setEndDate(String? d) => state = state.copyWith(endDate: d);
  void setPage(int p) => state = state.copyWith(page: p);
  void reset() => state = const ElectricityFilterState();
}

final electricityFilterProvider =
    NotifierProvider<ElectricityFilterNotifier, ElectricityFilterState>(ElectricityFilterNotifier.new);

final electricityReadingsProvider = FutureProvider<({List<ElectricityReadingModel> items, int total, int totalPages})>((ref) async {
  final repo = ref.watch(electricityRepositoryProvider);
  final filter = ref.watch(electricityFilterProvider);

  return repo.fetchReadings(
    page: filter.page,
    department: filter.department,
    startDate: filter.startDate,
    endDate: filter.endDate,
  );
});
