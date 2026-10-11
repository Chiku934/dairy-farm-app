import '../../../core/network/api_client.dart';
import '../domain/quality_models.dart';

class QualityRepository {
  final ApiClient _apiClient;

  QualityRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<({List<QualityRecordModel> items, int total, int totalPages})> fetchRecords({
    int page = 1,
    int limit = 20,
    QualityTargetType? targetType,
    String? targetId,
    QualityDecision? decision,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (targetType != null) queryParams['targetType'] = targetType.value;
      if (targetId != null && targetId.isNotEmpty) queryParams['targetId'] = targetId;
      if (decision != null) queryParams['decision'] = decision.value;
      if (startDate != null && startDate.isNotEmpty) queryParams['startDate'] = startDate;
      if (endDate != null && endDate.isNotEmpty) queryParams['endDate'] = endDate;

      final response = await _apiClient.dio.get('/quality/records', queryParameters: queryParams);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      final itemsRaw = dataMap['items'] as List<dynamic>? ?? [];
      final items = itemsRaw.map((i) => QualityRecordModel.fromJson(i as Map<String, dynamic>)).toList();
      final total = dataMap['total'] as int? ?? items.length;
      final totalPages = dataMap['totalPages'] as int? ?? 1;

      return (items: items, total: total, totalPages: totalPages);
    } catch (e) {
      rethrow;
    }
  }

  Future<QualityRecordModel> createRecord(Map<String, dynamic> payload) async {
    try {
      final response = await _apiClient.dio.post('/quality/records', data: payload);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return QualityRecordModel.fromJson(dataMap);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<QualityRecordModel>> fetchRecordsByTarget(String targetType, String targetId) async {
    try {
      final response = await _apiClient.dio.get('/quality/target/$targetType/$targetId');
      final raw = response.data;
      final List<dynamic> listRaw = raw is List
          ? raw
          : (raw is Map && raw.containsKey('data') && raw['data'] is List ? raw['data'] as List : []);

      return listRaw.map((i) => QualityRecordModel.fromJson(i as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }
}
