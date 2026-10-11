import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/sales_repository.dart';
import '../domain/sales_models.dart';

final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  return SalesRepository();
});

class SalesFilterState {
  final OrderStatus? orderStatus;
  final String? customerId;
  final ProductType? productType;
  final int page;

  const SalesFilterState({
    this.orderStatus,
    this.customerId,
    this.productType,
    this.page = 1,
  });

  SalesFilterState copyWith({
    OrderStatus? orderStatus,
    String? customerId,
    ProductType? productType,
    int? page,
    bool clearStatus = false,
    bool clearCustomer = false,
  }) {
    return SalesFilterState(
      orderStatus: clearStatus ? null : (orderStatus ?? this.orderStatus),
      customerId: clearCustomer ? null : (customerId ?? this.customerId),
      productType: productType ?? this.productType,
      page: page ?? this.page,
    );
  }
}

class SalesFilterNotifier extends Notifier<SalesFilterState> {
  @override
  SalesFilterState build() => const SalesFilterState();

  void setOrderStatus(OrderStatus? s) => state = state.copyWith(orderStatus: s, clearStatus: s == null);
  void setCustomerId(String? c) => state = state.copyWith(customerId: c, clearCustomer: c == null);
  void setProductType(ProductType? p) => state = state.copyWith(productType: p);
  void setPage(int p) => state = state.copyWith(page: p);
  void reset() => state = const SalesFilterState();
}

final salesFilterProvider =
    NotifierProvider<SalesFilterNotifier, SalesFilterState>(SalesFilterNotifier.new);

final customersProvider = FutureProvider<List<CustomerModel>>((ref) async {
  final repo = ref.watch(salesRepositoryProvider);
  return repo.fetchCustomers();
});

final salesOrdersProvider = FutureProvider<({List<SalesOrderModel> items, int total, int totalPages})>((ref) async {
  final repo = ref.watch(salesRepositoryProvider);
  final filter = ref.watch(salesFilterProvider);

  return repo.fetchOrders(
    page: filter.page,
    status: filter.orderStatus,
    customerId: filter.customerId,
  );
});

final salesDispatchesProvider = FutureProvider<({List<SalesDispatchModel> items, int total, int totalPages})>((ref) async {
  final repo = ref.watch(salesRepositoryProvider);
  final filter = ref.watch(salesFilterProvider);

  return repo.fetchDispatches(
    page: filter.page,
    productType: filter.productType,
    customerId: filter.customerId,
  );
});

final customerPaymentsProvider = FutureProvider<({List<CustomerPaymentModel> items, int total, int totalPages})>((ref) async {
  final repo = ref.watch(salesRepositoryProvider);
  final filter = ref.watch(salesFilterProvider);

  return repo.fetchPayments(
    page: filter.page,
    customerId: filter.customerId,
  );
});
