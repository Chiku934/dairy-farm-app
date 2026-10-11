import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../domain/production_models.dart';

class ProductionRepository {
  final ApiClient _apiClient;

  ProductionRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<({List<ProductionBatchModel> items, int total, int totalPages})> fetchBatches({
    int page = 1,
    int limit = 20,
    String? date,
    String? startDate,
    String? endDate,
    ProductType? productType,
    QualityReleaseStatus? qualityRelease,
    BatchStatus? status,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (date != null && date.isNotEmpty) queryParams['date'] = date;
      if (startDate != null && startDate.isNotEmpty) queryParams['startDate'] = startDate;
      if (endDate != null && endDate.isNotEmpty) queryParams['endDate'] = endDate;
      if (productType != null) queryParams['productType'] = productType.value;
      if (qualityRelease != null) queryParams['qualityRelease'] = qualityRelease.value;
      if (status != null) queryParams['status'] = status.value;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _apiClient.dio.get('/production/batches', queryParameters: queryParams);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      final itemsRaw = dataMap['items'] as List<dynamic>? ?? [];
      final items = itemsRaw.map((i) => ProductionBatchModel.fromJson(i as Map<String, dynamic>)).toList();
      final total = dataMap['total'] as int? ?? items.length;
      final totalPages = dataMap['totalPages'] as int? ?? 1;

      return (items: items, total: total, totalPages: totalPages);
    } catch (e) {
      rethrow;
    }
  }

  Future<ProductionBatchModel> fetchBatchDetail(String id) async {
    try {
      final response = await _apiClient.dio.get('/production/batches/$id');
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return ProductionBatchModel.fromJson(dataMap);
    } catch (e) {
      rethrow;
    }
  }

  Future<ProductionTraceabilityModel> fetchTraceability(String id) async {
    try {
      final response = await _apiClient.dio.get('/production/batches/$id/traceability');
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return ProductionTraceabilityModel.fromJson(dataMap);
    } catch (e) {
      rethrow;
    }
  }

  Future<ProductionBatchModel> createBatch(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/production/batches', data: data);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return ProductionBatchModel.fromJson(dataMap);
    } catch (e) {
      rethrow;
    }
  }

  Future<ProductionBatchModel> updateBatchStatus(
    String id, {
    QualityReleaseStatus? qualityRelease,
    BatchStatus? status,
    String? notes,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (qualityRelease != null) body['qualityRelease'] = qualityRelease.value;
      if (status != null) body['status'] = status.value;
      if (notes != null && notes.isNotEmpty) body['notes'] = notes;

      final response = await _apiClient.dio.patch('/production/batches/$id/status', data: body);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return ProductionBatchModel.fromJson(dataMap);
    } catch (e) {
      rethrow;
    }
  }
}
