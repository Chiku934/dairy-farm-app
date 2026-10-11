import '../../../core/network/api_client.dart';
import '../domain/inventory_models.dart';

class InventoryRepository {
  final ApiClient _apiClient;

  InventoryRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<({List<StockItemModel> items, int total, int totalPages})> fetchItems({
    int page = 1,
    int limit = 50,
    StockCategory? category,
    String? usedBy,
    bool? lowStockOnly,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (category != null) queryParams['category'] = category.apiValue;
      if (usedBy != null && usedBy.isNotEmpty) queryParams['usedBy'] = usedBy;
      if (lowStockOnly == true) queryParams['lowStockOnly'] = true;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _apiClient.dio.get('/inventory/items', queryParameters: queryParams);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      final itemsRaw = dataMap['items'] as List<dynamic>? ?? [];
      final items = itemsRaw.map((i) => StockItemModel.fromJson(i as Map<String, dynamic>)).toList();
      final total = dataMap['total'] as int? ?? items.length;
      final totalPages = dataMap['totalPages'] as int? ?? 1;

      return (items: items, total: total, totalPages: totalPages);
    } catch (e) {
      rethrow;
    }
  }

  Future<StockItemModel> createItem(Map<String, dynamic> payload) async {
    try {
      final response = await _apiClient.dio.post('/inventory/items', data: payload);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return StockItemModel.fromJson(dataMap);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<SupplierModel>> fetchSuppliers() async {
    try {
      final response = await _apiClient.dio.get('/inventory/suppliers');
      final raw = response.data;
      final List<dynamic> listRaw = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as List<dynamic>
          : (raw is List<dynamic> ? raw : []);

      return listRaw.map((s) => SupplierModel.fromJson(s as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<SupplierModel> createSupplier(Map<String, dynamic> payload) async {
    try {
      final response = await _apiClient.dio.post('/inventory/suppliers', data: payload);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return SupplierModel.fromJson(dataMap);
    } catch (e) {
      rethrow;
    }
  }

  Future<({List<StockReceiptModel> items, int total, int totalPages})> fetchReceipts({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get('/inventory/receipts', queryParameters: {
        'page': page,
        'limit': limit,
      });
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      final itemsRaw = dataMap['items'] as List<dynamic>? ?? [];
      final items = itemsRaw.map((i) => StockReceiptModel.fromJson(i as Map<String, dynamic>)).toList();
      final total = dataMap['total'] as int? ?? items.length;
      final totalPages = dataMap['totalPages'] as int? ?? 1;

      return (items: items, total: total, totalPages: totalPages);
    } catch (e) {
      rethrow;
    }
  }

  Future<StockReceiptModel> createReceipt(Map<String, dynamic> payload) async {
    try {
      final response = await _apiClient.dio.post('/inventory/receipts', data: payload);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return StockReceiptModel.fromJson(dataMap);
    } catch (e) {
      rethrow;
    }
  }
}
