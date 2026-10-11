import '../../../core/network/api_client.dart';
import '../domain/packaging_models.dart';

class PackagingRepository {
  final ApiClient _apiClient;

  PackagingRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<({List<PackagingRunModel> items, int total, int totalPages})> fetchRuns({
    int page = 1,
    int limit = 20,
    String? batchId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (batchId != null && batchId.isNotEmpty) queryParams['batchId'] = batchId;
      if (startDate != null && startDate.isNotEmpty) queryParams['startDate'] = startDate;
      if (endDate != null && endDate.isNotEmpty) queryParams['endDate'] = endDate;

      final response = await _apiClient.dio.get('/packaging/runs', queryParameters: queryParams);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      final itemsRaw = dataMap['items'] as List<dynamic>? ?? [];
      final items = itemsRaw.map((i) => PackagingRunModel.fromJson(i as Map<String, dynamic>)).toList();
      final total = dataMap['total'] as int? ?? items.length;
      final totalPages = dataMap['totalPages'] as int? ?? 1;

      return (items: items, total: total, totalPages: totalPages);
    } catch (e) {
      rethrow;
    }
  }

  Future<PackagingRunModel> createRun(Map<String, dynamic> payload) async {
    try {
      final response = await _apiClient.dio.post('/packaging/runs', data: payload);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return PackagingRunModel.fromJson(dataMap);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<PackagingRunModel>> fetchRunsByBatch(String batchId) async {
    try {
      final response = await _apiClient.dio.get('/packaging/batch/$batchId');
      final raw = response.data;
      final List<dynamic> listRaw = raw is List
          ? raw
          : (raw is Map && raw.containsKey('data') && raw['data'] is List ? raw['data'] as List : []);

      return listRaw.map((i) => PackagingRunModel.fromJson(i as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }
}
