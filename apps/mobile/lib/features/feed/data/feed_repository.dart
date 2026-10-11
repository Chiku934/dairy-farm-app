import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../domain/feed_models.dart';

class FeedRepository {
  final ApiClient _apiClient;

  FeedRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<({List<FeedEntryModel> items, int total, int totalPages})> fetchFeedEntries({
    int page = 1,
    int limit = 50,
    String? date,
    String? startDate,
    String? endDate,
    String? animalId,
    FeedType? feedType,
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
      if (animalId != null && animalId.isNotEmpty) queryParams['animalId'] = animalId;
      if (feedType != null) queryParams['feedType'] = feedType.apiValue;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _apiClient.dio.get('/feed', queryParameters: queryParams);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      final itemsRaw = dataMap['items'] as List<dynamic>? ?? [];
      final items = itemsRaw.map((i) => FeedEntryModel.fromJson(i as Map<String, dynamic>)).toList();
      final total = dataMap['total'] as int? ?? items.length;
      final totalPages = dataMap['totalPages'] as int? ?? 1;

      return (items: items, total: total, totalPages: totalPages);
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final err = e.response!.data as Map;
        throw Exception(err['message'] ?? 'Failed to load feed entries');
      }
      throw Exception('Network issue loading feed: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load feed entries: $e');
    }
  }

  Future<FeedEntryModel> recordFeedConsumption({
    String? animalId,
    String? groupName,
    String? rationId,
    required String recordDate,
    required String stockItemId,
    required double quantityKg,
    required FeedType feedType,
    FeedShift shift = FeedShift.allDay,
    String? notes,
  }) async {
    try {
      final body = <String, dynamic>{
        if (animalId != null && animalId.isNotEmpty) 'animalId': animalId,
        if (groupName != null && groupName.isNotEmpty) 'groupName': groupName,
        if (rationId != null && rationId.isNotEmpty) 'rationId': rationId,
        'recordDate': recordDate,
        'stockItemId': stockItemId,
        'quantityKg': quantityKg,
        'feedType': feedType.apiValue,
        'shift': shift.apiValue,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      final response = await _apiClient.dio.post('/feed', data: body);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return FeedEntryModel.fromJson(dataMap);
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final err = e.response!.data as Map;
        throw Exception(err['message'] ?? 'Failed to issue feed');
      }
      throw Exception('Network issue while issuing feed: ${e.message}');
    } catch (e) {
      throw Exception('Failed to record feed issuance: $e');
    }
  }

  Future<ConcentrateTargetModel> calculateConcentrateTarget(String animalId) async {
    try {
      final response = await _apiClient.dio.get('/feed/rules/$animalId');
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return ConcentrateTargetModel.fromJson(dataMap);
    } catch (e) {
      throw Exception('Failed to calculate target concentrate: $e');
    }
  }

  Future<List<RationDefinitionModel>> fetchRations() async {
    try {
      final response = await _apiClient.dio.get('/feed/rations');
      final raw = response.data;
      final List<dynamic> listRaw = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as List<dynamic>
          : (raw is List ? raw : []);

      return listRaw.map((r) => RationDefinitionModel.fromJson(r as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to load ration definitions: $e');
    }
  }

  Future<RationDefinitionModel> createRation({
    required String name,
    required String code,
    required TargetAnimalStage targetStage,
    String? description,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'code': code,
        'targetStage': targetStage.apiValue,
        if (description != null && description.isNotEmpty) 'description': description,
        'items': items,
      };

      final response = await _apiClient.dio.post('/feed/rations', data: body);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return RationDefinitionModel.fromJson(dataMap);
    } catch (e) {
      throw Exception('Failed to create ration formulation: $e');
    }
  }
}
