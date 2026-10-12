import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/expense_repository.dart';
import '../domain/expense_models.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository();
});

class ExpenseFilterState {
  final String? startDate;
  final String? endDate;
  final CostCentre? costCentre;
  final ExpenseCategory? category;
  final int page;

  const ExpenseFilterState({
    this.startDate,
    this.endDate,
    this.costCentre,
    this.category,
    this.page = 1,
  });

  ExpenseFilterState copyWith({
    String? startDate,
    String? endDate,
    CostCentre? costCentre,
    ExpenseCategory? category,
    int? page,
    bool clearCostCentre = false,
    bool clearCategory = false,
  }) {
    return ExpenseFilterState(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      costCentre: clearCostCentre ? null : (costCentre ?? this.costCentre),
      category: clearCategory ? null : (category ?? this.category),
      page: page ?? this.page,
    );
  }
}

class ExpenseFilterNotifier extends Notifier<ExpenseFilterState> {
  @override
  ExpenseFilterState build() => const ExpenseFilterState();

  void setCostCentre(CostCentre? centre) =>
      state = state.copyWith(costCentre: centre, clearCostCentre: centre == null);

  void setCategory(ExpenseCategory? cat) =>
      state = state.copyWith(category: cat, clearCategory: cat == null);

  void setDateRange(String? start, String? end) =>
      state = state.copyWith(startDate: start, endDate: end);

  void setPage(int p) => state = state.copyWith(page: p);

  void reset() => state = const ExpenseFilterState();
}

final expenseFilterProvider =
    NotifierProvider<ExpenseFilterNotifier, ExpenseFilterState>(ExpenseFilterNotifier.new);

final operatingExpensesProvider = FutureProvider<
    ({List<OperatingExpenseModel> items, int total, int totalPages, ExpenseSummaryModel summary})>((ref) async {
  final repo = ref.watch(expenseRepositoryProvider);
  final filter = ref.watch(expenseFilterProvider);

  return repo.fetchExpenses(
    page: filter.page,
    startDate: filter.startDate,
    endDate: filter.endDate,
    costCentre: filter.costCentre?.apiValue,
    category: filter.category?.apiValue,
  );
});
