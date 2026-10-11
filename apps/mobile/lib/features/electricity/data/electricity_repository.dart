import '../../../core/network/api_client.dart';
import '../domain/electricity_models.dart';

class ElectricityRepository {
  final ApiClient _apiClient;

  ElectricityRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<({List<ElectricityReadingModel> items, int total, int totalPages})> fetchReadings({
    int page = 1,
    int limit = 20,
    ElectricityDepartment? department,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (department != null) queryParams['department'] = department.value;
      if (startDate != null && startDate.isNotEmpty) queryParams['startDate'] = startDate;
      if (endDate != null && endDate.isNotEmpty) queryParams['endDate'] = endDate;

      final response = await _apiClient.dio.get('/electricity/readings', queryParameters: queryParams);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      final itemsRaw = dataMap['items'] as List<dynamic>? ?? [];
      final items = itemsRaw.map((i) => ElectricityReadingModel.fromJson(i as Map<String, dynamic>)).toList();
      final total = dataMap['total'] as int? ?? items.length;
      final totalPages = dataMap['totalPages'] as int? ?? 1;

      return (items: items, total: total, totalPages: totalPages);
    } catch (e) {
      rethrow;
    }
  }

  Future<ElectricityReadingModel> createReading(Map<String, dynamic> payload) async {
    try {
      final response = await _apiClient.dio.post('/electricity/readings', data: payload);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return ElectricityReadingModel.fromJson(dataMap);
    } catch (e) {
      rethrow;
    }
  }
}
