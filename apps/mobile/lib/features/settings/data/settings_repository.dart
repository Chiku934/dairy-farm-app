import '../../../core/network/api_client.dart';
import '../domain/settings_models.dart';

class SettingsRepository {
  final ApiClient _apiClient;

  SettingsRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<FarmSettingsModel> fetchSettings() async {
    try {
      final response = await _apiClient.dio.get('/settings');
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return FarmSettingsModel.fromJson(dataMap);
    } catch (e) {
      rethrow;
    }
  }

  Future<FarmSettingsModel> updateSettings(Map<String, dynamic> payload) async {
    try {
      final response = await _apiClient.dio.put('/settings', data: payload);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return FarmSettingsModel.fromJson(dataMap);
    } catch (e) {
      rethrow;
    }
  }
}
