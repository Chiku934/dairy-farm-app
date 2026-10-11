import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../domain/breeding_models.dart';

class BreedingRepository {
  final ApiClient _apiClient;

  BreedingRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<({List<BreedingRecordModel> items, int total, int totalPages})> fetchRecords({
    int page = 1,
    int limit = 50,
    String? animalId,
    BreedingEventType? eventType,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (animalId != null && animalId.isNotEmpty) queryParams['animalId'] = animalId;
      if (eventType != null) queryParams['eventType'] = eventType.apiValue;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _apiClient.dio.get('/breeding', queryParameters: queryParams);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      final itemsRaw = dataMap['items'] as List<dynamic>? ?? [];
      final items = itemsRaw.map((i) => BreedingRecordModel.fromJson(i as Map<String, dynamic>)).toList();
      final total = dataMap['total'] as int? ?? items.length;
      final totalPages = dataMap['totalPages'] as int? ?? 1;

      return (items: items, total: total, totalPages: totalPages);
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final err = e.response!.data as Map;
        throw Exception(err['message'] ?? 'Failed to load breeding records');
      }
      throw Exception('Failed to load breeding records: ${e.message}');
    }
  }

  Future<List<BreedingReminderModel>> fetchReminders() async {
    try {
      final response = await _apiClient.dio.get('/breeding/reminders');
      final raw = response.data;
      final dynamic listRaw = raw is Map<String, dynamic> && raw.containsKey('data') ? raw['data'] : raw;

      if (listRaw is List) {
        return listRaw.map((i) => BreedingReminderModel.fromJson(i as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<BreedingRecordModel> createRecord(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/breeding', data: data);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return BreedingRecordModel.fromJson(dataMap);
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final err = e.response!.data as Map;
        throw Exception(err['message'] ?? 'Failed to record breeding event');
      }
      throw Exception('Failed to record breeding event: ${e.message}');
    }
  }
}
