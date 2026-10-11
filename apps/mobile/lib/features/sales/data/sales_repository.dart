import '../../../core/network/api_client.dart';
import '../domain/sales_models.dart';

class SalesRepository {
  final ApiClient _apiClient;

  SalesRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<CustomerModel>> fetchCustomers() async {
    try {
      final response = await _apiClient.dio.get('/sales/customers');
      final raw = response.data;
      final List<dynamic> listRaw = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as List<dynamic>
          : (raw is List<dynamic> ? raw : []);

      return listRaw.map((c) => CustomerModel.fromJson(c as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<CustomerModel> createCustomer(Map<String, dynamic> payload) async {
    try {
      final response = await _apiClient.dio.post('/sales/customers', data: payload);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return CustomerModel.fromJson(dataMap);
    } catch (e) {
      rethrow;
    }
  }

  Future<({List<SalesOrderModel> items, int total, int totalPages})> fetchOrders({
    int page = 1,
    int limit = 20,
    OrderStatus? status,
    String? customerId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (status != null) queryParams['status'] = status.apiValue;
      if (customerId != null && customerId.isNotEmpty) queryParams['customerId'] = customerId;

      final response = await _apiClient.dio.get('/sales/orders', queryParameters: queryParams);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      final itemsRaw = dataMap['items'] as List<dynamic>? ?? [];
      final items = itemsRaw.map((i) => SalesOrderModel.fromJson(i as Map<String, dynamic>)).toList();
      final total = dataMap['total'] as int? ?? items.length;
      final totalPages = dataMap['totalPages'] as int? ?? 1;

      return (items: items, total: total, totalPages: totalPages);
    } catch (e) {
      rethrow;
    }
  }

  Future<SalesOrderModel> createOrder(Map<String, dynamic> payload) async {
    try {
      final response = await _apiClient.dio.post('/sales/orders', data: payload);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return SalesOrderModel.fromJson(dataMap);
    } catch (e) {
      rethrow;
    }
  }

  Future<SalesOrderModel> cancelOrder(String id) async {
    try {
      final response = await _apiClient.dio.post('/sales/orders/$id/cancel');
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return SalesOrderModel.fromJson(dataMap);
    } catch (e) {
      rethrow;
    }
  }

  Future<({List<SalesDispatchModel> items, int total, int totalPages})> fetchDispatches({
    int page = 1,
    int limit = 20,
    ProductType? productType,
    String? customerId,
    String? orderId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (productType != null) queryParams['productType'] = productType.apiValue;
      if (customerId != null && customerId.isNotEmpty) queryParams['customerId'] = customerId;
      if (orderId != null && orderId.isNotEmpty) queryParams['orderId'] = orderId;

      final response = await _apiClient.dio.get('/sales/dispatches', queryParameters: queryParams);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      final itemsRaw = dataMap['items'] as List<dynamic>? ?? [];
      final items = itemsRaw.map((i) => SalesDispatchModel.fromJson(i as Map<String, dynamic>)).toList();
      final total = dataMap['total'] as int? ?? items.length;
      final totalPages = dataMap['totalPages'] as int? ?? 1;

      return (items: items, total: total, totalPages: totalPages);
    } catch (e) {
      rethrow;
    }
  }

  Future<SalesDispatchModel> createDispatch(Map<String, dynamic> payload) async {
    try {
      final response = await _apiClient.dio.post('/sales/dispatches', data: payload);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return SalesDispatchModel.fromJson(dataMap);
    } catch (e) {
      rethrow;
    }
  }

  Future<({List<CustomerPaymentModel> items, int total, int totalPages})> fetchPayments({
    int page = 1,
    int limit = 20,
    String? customerId,
    String? dispatchId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (customerId != null && customerId.isNotEmpty) queryParams['customerId'] = customerId;
      if (dispatchId != null && dispatchId.isNotEmpty) queryParams['dispatchId'] = dispatchId;

      final response = await _apiClient.dio.get('/sales/payments', queryParameters: queryParams);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      final itemsRaw = dataMap['items'] as List<dynamic>? ?? [];
      final items = itemsRaw.map((i) => CustomerPaymentModel.fromJson(i as Map<String, dynamic>)).toList();
      final total = dataMap['total'] as int? ?? items.length;
      final totalPages = dataMap['totalPages'] as int? ?? 1;

      return (items: items, total: total, totalPages: totalPages);
    } catch (e) {
      rethrow;
    }
  }

  Future<CustomerPaymentModel> createPayment(Map<String, dynamic> payload) async {
    try {
      final response = await _apiClient.dio.post('/sales/payments', data: payload);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return CustomerPaymentModel.fromJson(dataMap);
    } catch (e) {
      rethrow;
    }
  }
}
