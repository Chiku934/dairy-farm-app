import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../domain/dashboard_models.dart';

class DashboardRepository {
  final ApiClient _apiClient;

  DashboardRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<DashboardOverviewModel> fetchOverview({
    DashboardPeriodFilter period = DashboardPeriodFilter.today,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'period': period.apiValue,
      };

      if (period == DashboardPeriodFilter.custom && startDate != null && endDate != null) {
        queryParams['startDate'] = startDate;
        queryParams['endDate'] = endDate;
      }

      final response = await _apiClient.dio.get(
        '/dashboard/overview',
        queryParameters: queryParams,
      );

      final dynamic responseData = response.data;
      Map<String, dynamic> dataMap;

      if (responseData is Map<String, dynamic>) {
        if (responseData.containsKey('data') && responseData['data'] is Map<String, dynamic>) {
          dataMap = responseData['data'] as Map<String, dynamic>;
        } else {
          dataMap = responseData;
        }
      } else {
        throw Exception('Invalid server response format');
      }

      return DashboardOverviewModel.fromJson(dataMap);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) {
        final err = e.response?.data as Map;
        throw Exception(err['message'] ?? 'Failed to load dashboard metrics');
      }
      throw Exception('Network connection issue. Please verify server connectivity.');
    } catch (e) {
      throw Exception('Failed to load dashboard: $e');
    }
  }

  Future<void> invalidateCache() async {
    try {
      await _apiClient.dio.post('/dashboard/invalidate-cache');
    } catch (_) {
      // Invalidation is best effort
    }
  }
}
