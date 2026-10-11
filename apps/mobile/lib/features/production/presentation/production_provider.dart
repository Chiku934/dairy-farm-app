import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/production_repository.dart';
import '../domain/production_models.dart';

final productionRepositoryProvider = Provider<ProductionRepository>((ref) {
  return ProductionRepository();
});

class ProductionFilterState {
  final String? date;
  final ProductType? productType;
  final QualityReleaseStatus? qualityRelease;
  final BatchStatus? status;
  final String? search;

  const ProductionFilterState({
    this.date,
    this.productType,
    this.qualityRelease,
    this.status,
    this.search,
  });

  ProductionFilterState copyWith({
    String? date,
    ProductType? productType,
    QualityReleaseStatus? qualityRelease,
    BatchStatus? status,
    String? search,
    bool clearDate = false,
    bool clearProductType = false,
    bool clearQualityRelease = false,
    bool clearStatus = false,
  }) {
    return ProductionFilterState(
      date: clearDate ? null : (date ?? this.date),
      productType: clearProductType ? null : (productType ?? this.productType),
      qualityRelease: clearQualityRelease ? null : (qualityRelease ?? this.qualityRelease),
      status: clearStatus ? null : (status ?? this.status),
      search: search ?? this.search,
    );
  }
}

class ProductionFilterNotifier extends Notifier<ProductionFilterState> {
  @override
  ProductionFilterState build() => const ProductionFilterState();

  void setDate(String? date) => state = state.copyWith(date: date, clearDate: date == null);
  void setProductType(ProductType? type) => state = state.copyWith(productType: type, clearProductType: type == null);
  void setQualityRelease(QualityReleaseStatus? release) => state = state.copyWith(qualityRelease: release, clearQualityRelease: release == null);
  void setStatus(BatchStatus? status) => state = state.copyWith(status: status, clearStatus: status == null);
  void setSearch(String search) => state = state.copyWith(search: search);
  void reset() => state = const ProductionFilterState();
}

final productionFilterProvider =
    NotifierProvider<ProductionFilterNotifier, ProductionFilterState>(ProductionFilterNotifier.new);

final productionBatchesProvider = FutureProvider<({List<ProductionBatchModel> items, int total, int totalPages})>((ref) async {
  final repo = ref.watch(productionRepositoryProvider);
  final filter = ref.watch(productionFilterProvider);

  return repo.fetchBatches(
    date: filter.date,
    productType: filter.productType,
    qualityRelease: filter.qualityRelease,
    status: filter.status,
    search: filter.search,
  );
});

final productionBatchDetailProvider = FutureProvider.family<ProductionBatchModel, String>((ref, id) async {
  final repo = ref.watch(productionRepositoryProvider);
  return repo.fetchBatchDetail(id);
});

final productionTraceabilityProvider = FutureProvider.family<ProductionTraceabilityModel, String>((ref, id) async {
  final repo = ref.watch(productionRepositoryProvider);
  return repo.fetchTraceability(id);
});
