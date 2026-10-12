import '../../../core/network/api_client.dart';
import '../domain/report_models.dart';

class ReportsRepository {
  final ApiClient _apiClient;

  ReportsRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<ReportResultModel> fetchReport(
    ReportType type, {
    String? startDate,
    String? endDate,
    String? filterKey,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (startDate != null && startDate.isNotEmpty) queryParams['startDate'] = startDate;
      if (endDate != null && endDate.isNotEmpty) queryParams['endDate'] = endDate;
      if (filterKey != null && filterKey.isNotEmpty) queryParams['filterKey'] = filterKey;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _apiClient.dio.get(
        '/reports/${type.apiEndpoint}',
        queryParameters: queryParams,
      );

      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return ReportResultModel.fromJson(dataMap);
    } catch (e) {
      rethrow;
    }
  }

  Future<String> exportReportCsv(
    ReportType type, {
    String? startDate,
    String? endDate,
    String? filterKey,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null && startDate.isNotEmpty) queryParams['startDate'] = startDate;
      if (endDate != null && endDate.isNotEmpty) queryParams['endDate'] = endDate;
      if (filterKey != null && filterKey.isNotEmpty) queryParams['filterKey'] = filterKey;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _apiClient.dio.get<String>(
        '/reports/${type.apiEndpoint}/export',
        queryParameters: queryParams,
      );

      return response.data ?? '';
    } catch (e) {
      rethrow;
    }
  }
}
