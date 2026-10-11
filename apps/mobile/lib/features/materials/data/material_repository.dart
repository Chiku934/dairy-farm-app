import '../../../core/network/api_client.dart';
import '../domain/material_models.dart';

class MaterialRepository {
  final ApiClient _apiClient;

  MaterialRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<({List<MaterialIssueModel> items, int total, int totalPages})> fetchIssues({
    int page = 1,
    int limit = 20,
    IssueDepartment? department,
    String? stockItemId,
    String? batchId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (department != null) queryParams['department'] = department.value;
      if (stockItemId != null && stockItemId.isNotEmpty) queryParams['stockItemId'] = stockItemId;
      if (batchId != null && batchId.isNotEmpty) queryParams['batchId'] = batchId;
      if (startDate != null && startDate.isNotEmpty) queryParams['startDate'] = startDate;
      if (endDate != null && endDate.isNotEmpty) queryParams['endDate'] = endDate;

      final response = await _apiClient.dio.get('/materials/issues', queryParameters: queryParams);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      final itemsRaw = dataMap['items'] as List<dynamic>? ?? [];
      final items = itemsRaw.map((i) => MaterialIssueModel.fromJson(i as Map<String, dynamic>)).toList();
      final total = dataMap['total'] as int? ?? items.length;
      final totalPages = dataMap['totalPages'] as int? ?? 1;

      return (items: items, total: total, totalPages: totalPages);
    } catch (e) {
      rethrow;
    }
  }

  Future<MaterialIssueModel> createIssue(Map<String, dynamic> payload) async {
    try {
      final response = await _apiClient.dio.post('/materials/issues', data: payload);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return MaterialIssueModel.fromJson(dataMap);
    } catch (e) {
      rethrow;
    }
  }
}
