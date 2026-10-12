import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/employee_repository.dart';
import '../domain/employee_models.dart';

final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  return EmployeeRepository();
});

class EmployeeFilterState {
  final String? search;
  final Department? department;
  final EmploymentStatus? status;
  final bool? isActive;
  final int page;

  const EmployeeFilterState({
    this.search,
    this.department,
    this.status,
    this.isActive,
    this.page = 1,
  });

  EmployeeFilterState copyWith({
    String? search,
    Department? department,
    EmploymentStatus? status,
    bool? isActive,
    int? page,
    bool clearDepartment = false,
    bool clearStatus = false,
    bool clearSearch = false,
  }) {
    return EmployeeFilterState(
      search: clearSearch ? null : (search ?? this.search),
      department: clearDepartment ? null : (department ?? this.department),
      status: clearStatus ? null : (status ?? this.status),
      isActive: isActive ?? this.isActive,
      page: page ?? this.page,
    );
  }
}

class EmployeeFilterNotifier extends Notifier<EmployeeFilterState> {
  @override
  EmployeeFilterState build() => const EmployeeFilterState();

  void setSearch(String? query) =>
      state = state.copyWith(search: query, clearSearch: query == null || query.isEmpty);

  void setDepartment(Department? dept) =>
      state = state.copyWith(department: dept, clearDepartment: dept == null);

  void setStatus(EmploymentStatus? st) =>
      state = state.copyWith(status: st, clearStatus: st == null);

  void setIsActive(bool? active) =>
      state = state.copyWith(isActive: active);

  void reset() => state = const EmployeeFilterState();
}

final employeeFilterProvider =
    NotifierProvider<EmployeeFilterNotifier, EmployeeFilterState>(EmployeeFilterNotifier.new);

final employeesListProvider = FutureProvider<
    ({List<EmployeeModel> items, int total, int page, int limit})>((ref) async {
  final repo = ref.watch(employeeRepositoryProvider);
  final filter = ref.watch(employeeFilterProvider);

  return repo.fetchEmployees(
    page: filter.page,
    search: filter.search,
    department: filter.department,
    status: filter.status,
    isActive: filter.isActive,
  );
});
