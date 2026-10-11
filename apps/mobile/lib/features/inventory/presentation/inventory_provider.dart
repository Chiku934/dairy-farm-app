import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/inventory_repository.dart';
import '../domain/inventory_models.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository();
});

class InventoryFilterState {
  final StockCategory? category;
  final bool? lowStockOnly;
  final String? search;
  final int page;

  const InventoryFilterState({
    this.category,
    this.lowStockOnly,
    this.search,
    this.page = 1,
  });

  InventoryFilterState copyWith({
    StockCategory? category,
    bool? lowStockOnly,
    String? search,
    int? page,
    bool clearCategory = false,
  }) {
    return InventoryFilterState(
      category: clearCategory ? null : (category ?? this.category),
      lowStockOnly: lowStockOnly ?? this.lowStockOnly,
      search: search ?? this.search,
      page: page ?? this.page,
    );
  }
}

class InventoryFilterNotifier extends Notifier<InventoryFilterState> {
  @override
  InventoryFilterState build() => const InventoryFilterState();

  void setCategory(StockCategory? c) => state = state.copyWith(category: c, clearCategory: c == null);
  void toggleLowStockOnly() => state = state.copyWith(lowStockOnly: !(state.lowStockOnly ?? false));
  void setSearch(String? q) => state = state.copyWith(search: q);
  void setPage(int p) => state = state.copyWith(page: p);
  void reset() => state = const InventoryFilterState();
}

final inventoryFilterProvider =
    NotifierProvider<InventoryFilterNotifier, InventoryFilterState>(InventoryFilterNotifier.new);

final inventoryItemsProvider = FutureProvider<({List<StockItemModel> items, int total, int totalPages})>((ref) async {
  final repo = ref.watch(inventoryRepositoryProvider);
  final filter = ref.watch(inventoryFilterProvider);

  return repo.fetchItems(
    page: filter.page,
    category: filter.category,
    lowStockOnly: filter.lowStockOnly,
    search: filter.search,
  );
});

final suppliersProvider = FutureProvider<List<SupplierModel>>((ref) async {
  final repo = ref.watch(inventoryRepositoryProvider);
  return repo.fetchSuppliers();
});

final stockReceiptsProvider = FutureProvider<({List<StockReceiptModel> items, int total, int totalPages})>((ref) async {
  final repo = ref.watch(inventoryRepositoryProvider);
  return repo.fetchReceipts();
});
