import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../domain/milking_models.dart';

class MilkingRepository {
  final ApiClient _apiClient;

  MilkingRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<({List<MilkingLogModel> items, int total, int totalPages})> fetchMilkingLogs({
    int page = 1,
    int limit = 50,
    String? date,
    String? startDate,
    String? endDate,
    MilkingSession? session,
    MilkDisposition? disposition,
    String? animalId,
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
      if (session != null) queryParams['session'] = session.apiValue;
      if (disposition != null) queryParams['disposition'] = disposition.apiValue;
      if (animalId != null && animalId.isNotEmpty) queryParams['animalId'] = animalId;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _apiClient.dio.get('/milking', queryParameters: queryParams);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      final itemsRaw = dataMap['items'] as List<dynamic>? ?? [];
      final items = itemsRaw.map((i) => MilkingLogModel.fromJson(i as Map<String, dynamic>)).toList();
      final total = dataMap['total'] as int? ?? items.length;
      final totalPages = dataMap['totalPages'] as int? ?? 1;

      return (items: items, total: total, totalPages: totalPages);
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final err = e.response!.data as Map;
        throw Exception(err['message'] ?? 'Failed to load milking logs');
      }
      throw Exception('Network issue while loading milking logs: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load milking records: $e');
    }
  }

  Future<MilkingSummaryModel> fetchSummary({String? startDate, String? endDate}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null && startDate.isNotEmpty) queryParams['startDate'] = startDate;
      if (endDate != null && endDate.isNotEmpty) queryParams['endDate'] = endDate;

      final response = await _apiClient.dio.get('/milking/summary', queryParameters: queryParams);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return MilkingSummaryModel.fromJson(dataMap);
    } catch (e) {
      throw Exception('Failed to load milking summary: $e');
    }
  }

  Future<MilkingLogModel> createMilkingLog({
    String? animalId,
    String? groupName,
    required String recordDate,
    required MilkingSession session,
    required double yieldLitres,
    MilkDisposition disposition = MilkDisposition.eligible,
    String? withheldReason,
    String? operatorId,
    String? operatorName,
    String? notes,
  }) async {
    try {
      final body = <String, dynamic>{
        if (animalId != null && animalId.isNotEmpty) 'animalId': animalId,
        if (groupName != null && groupName.isNotEmpty) 'groupName': groupName,
        'recordDate': recordDate,
        'session': session.apiValue,
        'yieldLitres': yieldLitres,
        'disposition': disposition.apiValue,
        if (withheldReason != null && withheldReason.isNotEmpty) 'withheldReason': withheldReason,
        if (operatorId != null && operatorId.isNotEmpty) 'operatorId': operatorId,
        if (operatorName != null && operatorName.isNotEmpty) 'operatorName': operatorName,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      final response = await _apiClient.dio.post('/milking', data: body);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return MilkingLogModel.fromJson(dataMap);
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final err = e.response!.data as Map;
        throw Exception(err['message'] ?? 'Failed to record milking');
      }
      throw Exception('Network issue while recording milking: ${e.message}');
    } catch (e) {
      throw Exception('Failed to record milking session: $e');
    }
  }

  Future<void> deleteMilkingLog(String id) async {
    try {
      await _apiClient.dio.delete('/milking/$id');
    } catch (e) {
      throw Exception('Failed to delete milking record: $e');
    }
  }
}
