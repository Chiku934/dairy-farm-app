import '../../../core/network/api_client.dart';
import '../domain/biogas_models.dart';

class BiogasRepository {
  final ApiClient _apiClient;

  BiogasRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<({List<BiogasRunModel> items, int total, int totalPages, BiogasSummaryModel summary})> fetchRuns({
    int page = 1,
    int limit = 50,
    String? startDate,
    String? endDate,
    String? usageType,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (startDate != null && startDate.isNotEmpty) queryParams['startDate'] = startDate;
      if (endDate != null && endDate.isNotEmpty) queryParams['endDate'] = endDate;
      if (usageType != null && usageType.isNotEmpty) queryParams['usageType'] = usageType;

      final response = await _apiClient.dio.get('/biogas', queryParameters: queryParams);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      final itemsRaw = dataMap['items'] as List<dynamic>? ?? [];
      final items = itemsRaw.map((i) => BiogasRunModel.fromJson(i as Map<String, dynamic>)).toList();
      final total = dataMap['total'] as int? ?? items.length;
      final totalPages = dataMap['totalPages'] as int? ?? 1;
      final summary = dataMap['summary'] != null
          ? BiogasSummaryModel.fromJson(dataMap['summary'] as Map<String, dynamic>)
          : const BiogasSummaryModel();

      return (items: items, total: total, totalPages: totalPages, summary: summary);
    } catch (e) {
      rethrow;
    }
  }

  Future<BiogasRunModel> createRun(Map<String, dynamic> payload) async {
    try {
      final response = await _apiClient.dio.post('/biogas', data: payload);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return BiogasRunModel.fromJson(dataMap);
    } catch (e) {
      rethrow;
    }
  }
}
