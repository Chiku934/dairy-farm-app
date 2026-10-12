import '../../../core/network/api_client.dart';
import '../domain/wastage_models.dart';

class WastageRepository {
  final ApiClient _apiClient;

  WastageRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<({List<WastageRecordModel> items, int total, int totalPages, WastageSummaryModel summary})> fetchRecords({
    int page = 1,
    int limit = 50,
    String? startDate,
    String? endDate,
    String? stockType,
    String? reason,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (startDate != null && startDate.isNotEmpty) queryParams['startDate'] = startDate;
      if (endDate != null && endDate.isNotEmpty) queryParams['endDate'] = endDate;
      if (stockType != null && stockType.isNotEmpty) queryParams['stockType'] = stockType;
      if (reason != null && reason.isNotEmpty) queryParams['reason'] = reason;

      final response = await _apiClient.dio.get('/wastage', queryParameters: queryParams);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      final itemsRaw = dataMap['items'] as List<dynamic>? ?? [];
      final items = itemsRaw.map((i) => WastageRecordModel.fromJson(i as Map<String, dynamic>)).toList();
      final total = dataMap['total'] as int? ?? items.length;
      final totalPages = dataMap['totalPages'] as int? ?? 1;
      final summary = dataMap['summary'] != null
          ? WastageSummaryModel.fromJson(dataMap['summary'] as Map<String, dynamic>)
          : const WastageSummaryModel();

      return (items: items, total: total, totalPages: totalPages, summary: summary);
    } catch (e) {
      rethrow;
    }
  }

  Future<WastageRecordModel> recordWastage(Map<String, dynamic> payload) async {
    try {
      final response = await _apiClient.dio.post('/wastage', data: payload);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return WastageRecordModel.fromJson(dataMap);
    } catch (e) {
      rethrow;
    }
  }
}
