import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../domain/bmc_models.dart';

class BmcRepository {
  final ApiClient _apiClient;

  BmcRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<({List<BmcIntakeLogModel> items, int total, int totalPages})> fetchIntakes({
    int page = 1,
    int limit = 20,
    String? date,
    String? startDate,
    String? endDate,
    IntakeShift? shift,
    MilkIntakeSource? source,
    IntakeDecision? decision,
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
      if (shift != null) queryParams['shift'] = shift.value;
      if (source != null) queryParams['source'] = source.value;
      if (decision != null) queryParams['decision'] = decision.value;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _apiClient.dio.get('/bmc/intake', queryParameters: queryParams);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      final itemsRaw = dataMap['items'] as List<dynamic>? ?? [];
      final items = itemsRaw.map((i) => BmcIntakeLogModel.fromJson(i as Map<String, dynamic>)).toList();
      final total = dataMap['total'] as int? ?? items.length;
      final totalPages = dataMap['totalPages'] as int? ?? 1;

      return (items: items, total: total, totalPages: totalPages);
    } catch (e) {
      rethrow;
    }
  }

  Future<BmcTankBalanceModel> fetchTankBalance() async {
    try {
      final response = await _apiClient.dio.get('/bmc/balance');
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return BmcTankBalanceModel.fromJson(dataMap);
    } catch (e) {
      rethrow;
    }
  }

  Future<BmcIntakeLogModel> createIntake(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/bmc/intake', data: data);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return BmcIntakeLogModel.fromJson(dataMap);
    } catch (e) {
      rethrow;
    }
  }

  Future<BmcIntakeLogModel> fetchIntakeDetail(String id) async {
    try {
      final response = await _apiClient.dio.get('/bmc/intake/$id');
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return BmcIntakeLogModel.fromJson(dataMap);
    } catch (e) {
      rethrow;
    }
  }
}
