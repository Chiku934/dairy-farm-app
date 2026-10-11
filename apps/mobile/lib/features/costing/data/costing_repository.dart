import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../domain/costing_models.dart';

class CostingRepository {
  final ApiClient _apiClient;

  CostingRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<DailyMilkCostingModel> fetchDailyMilkCosting({String? date}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (date != null && date.isNotEmpty) queryParams['date'] = date;

      final response = await _apiClient.dio.get('/costing/daily-milk', queryParameters: queryParams);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return DailyMilkCostingModel.fromJson(dataMap);
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final err = e.response!.data as Map;
        throw Exception(err['message'] ?? 'Failed to compute unit costing');
      }
      throw Exception('Network issue computing unit costing: ${e.message}');
    } catch (e) {
      throw Exception('Failed to calculate unit costing: $e');
    }
  }
}
