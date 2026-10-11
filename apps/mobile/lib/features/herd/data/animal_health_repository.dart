import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../domain/health_models.dart';

class AnimalHealthRepository {
  final ApiClient _apiClient;

  AnimalHealthRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<({List<HealthRecordModel> items, int total, int totalPages})> fetchRecords({
    int page = 1,
    int limit = 50,
    String? animalId,
    CareType? careType,
    bool activeWithdrawalOnly = false,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'activeWithdrawalOnly': activeWithdrawalOnly,
      };

      if (animalId != null && animalId.isNotEmpty) queryParams['animalId'] = animalId;
      if (careType != null) queryParams['careType'] = careType.apiValue;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _apiClient.dio.get('/health-records', queryParameters: queryParams);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      final itemsRaw = dataMap['items'] as List<dynamic>? ?? [];
      final items = itemsRaw.map((i) => HealthRecordModel.fromJson(i as Map<String, dynamic>)).toList();
      final total = dataMap['total'] as int? ?? items.length;
      final totalPages = dataMap['totalPages'] as int? ?? 1;

      return (items: items, total: total, totalPages: totalPages);
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final err = e.response!.data as Map;
        throw Exception(err['message'] ?? 'Failed to load health records');
      }
      throw Exception('Failed to load health records: ${e.message}');
    }
  }

  Future<List<HealthReminderModel>> fetchReminders() async {
    try {
      final response = await _apiClient.dio.get('/health-records/reminders');
      final raw = response.data;
      final dynamic listRaw = raw is Map<String, dynamic> && raw.containsKey('data') ? raw['data'] : raw;

      if (listRaw is List) {
        return listRaw.map((i) => HealthReminderModel.fromJson(i as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<ActiveWithdrawalModel>> fetchWithdrawals() async {
    try {
      final response = await _apiClient.dio.get('/health-records/withdrawals');
      final raw = response.data;
      final dynamic listRaw = raw is Map<String, dynamic> && raw.containsKey('data') ? raw['data'] : raw;

      if (listRaw is List) {
        return listRaw.map((i) => ActiveWithdrawalModel.fromJson(i as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<HealthRecordModel> createRecord(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/health-records', data: data);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return HealthRecordModel.fromJson(dataMap);
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final err = e.response!.data as Map;
        throw Exception(err['message'] ?? 'Failed to record health event');
      }
      throw Exception('Failed to record health event: ${e.message}');
    }
  }
}
