import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../domain/herd_models.dart';

class HerdRepository {
  final ApiClient _apiClient;

  HerdRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<({List<AnimalModel> items, int total, int totalPages})> fetchAnimals({
    int page = 1,
    int limit = 50,
    AnimalStatus? status,
    String? breed,
    String? search,
    bool includeArchived = false,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'includeArchived': includeArchived,
      };

      if (status != null) queryParams['status'] = status.apiValue;
      if (breed != null && breed.isNotEmpty) queryParams['breed'] = breed;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _apiClient.dio.get('/herd', queryParameters: queryParams);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      final itemsRaw = dataMap['items'] as List<dynamic>? ?? [];
      final items = itemsRaw.map((i) => AnimalModel.fromJson(i as Map<String, dynamic>)).toList();
      final total = dataMap['total'] as int? ?? items.length;
      final totalPages = dataMap['totalPages'] as int? ?? 1;

      return (items: items, total: total, totalPages: totalPages);
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final err = e.response!.data as Map;
        throw Exception(err['message'] ?? 'Failed to load cattle records');
      }
      throw Exception('Network issue while loading cattle records: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load herd: $e');
    }
  }

  Future<HerdSummaryCountsModel> fetchSummary() async {
    try {
      final response = await _apiClient.dio.get('/herd/summary');
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return HerdSummaryCountsModel.fromJson(dataMap);
    } catch (_) {
      return HerdSummaryCountsModel.empty();
    }
  }

  Future<AnimalModel> fetchAnimal(String id) async {
    try {
      final response = await _apiClient.dio.get('/herd/$id');
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return AnimalModel.fromJson(dataMap);
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final err = e.response!.data as Map;
        throw Exception(err['message'] ?? 'Failed to load animal');
      }
      throw Exception('Failed to load animal: ${e.message}');
    }
  }

  Future<({AnimalModel animal, List<AnimalTimelineItemModel> timeline})> fetchHistory(String id) async {
    try {
      final response = await _apiClient.dio.get('/herd/$id/history');
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      final animal = AnimalModel.fromJson(dataMap['animal'] as Map<String, dynamic>);
      final timelineRaw = dataMap['timeline'] as List<dynamic>? ?? [];
      final timeline = timelineRaw.map((t) => AnimalTimelineItemModel.fromJson(t as Map<String, dynamic>)).toList();

      return (animal: animal, timeline: timeline);
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final err = e.response!.data as Map;
        throw Exception(err['message'] ?? 'Failed to load animal history');
      }
      throw Exception('Failed to load animal history: ${e.message}');
    }
  }

  Future<AnimalModel> createAnimal(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/herd', data: data);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return AnimalModel.fromJson(dataMap);
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final err = e.response!.data as Map;
        throw Exception(err['message'] ?? 'Failed to create animal');
      }
      throw Exception('Failed to create animal: ${e.message}');
    }
  }

  Future<AnimalModel> updateAnimal(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.patch('/herd/$id', data: data);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return AnimalModel.fromJson(dataMap);
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final err = e.response!.data as Map;
        throw Exception(err['message'] ?? 'Failed to update animal');
      }
      throw Exception('Failed to update animal: ${e.message}');
    }
  }

  Future<AnimalModel> archiveAnimal(String id, {required String reason, AnimalStatus? status}) async {
    try {
      final payload = <String, dynamic>{
        'archiveReason': reason,
      };
      if (status != null) payload['status'] = status.apiValue;

      final response = await _apiClient.dio.post('/herd/$id/archive', data: payload);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return AnimalModel.fromJson(dataMap);
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final err = e.response!.data as Map;
        throw Exception(err['message'] ?? 'Failed to archive animal');
      }
      throw Exception('Failed to archive animal: ${e.message}');
    }
  }
}
