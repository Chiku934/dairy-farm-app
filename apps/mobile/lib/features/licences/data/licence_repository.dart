import '../../../core/network/api_client.dart';
import '../domain/licence_models.dart';

class LicenceRepository {
  final ApiClient _apiClient;

  LicenceRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<({List<RegulatoryLicenceModel> items, int total, int page, int limit})> fetchLicences({
    int page = 1,
    int limit = 50,
    String? search,
    LicenceType? type,
    LicenceStatus? status,
    ReminderStatus? reminderStatus,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (type != null) queryParams['licenceType'] = type.apiValue;
      if (status != null) queryParams['status'] = status.apiValue;
      if (reminderStatus != null) queryParams['reminderStatus'] = reminderStatus.apiValue;

      final response = await _apiClient.dio.get('/licences', queryParameters: queryParams);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      final dynamic listRaw = dataMap['data'] ?? dataMap['items'] ?? [];
      final List<dynamic> itemsList = listRaw is List ? listRaw : [];
      final items = itemsList
          .map((i) => RegulatoryLicenceModel.fromJson(i as Map<String, dynamic>))
          .toList();

      final total = dataMap['total'] as int? ?? items.length;
      final resPage = dataMap['page'] as int? ?? page;
      final resLimit = dataMap['limit'] as int? ?? limit;

      return (items: items, total: total, page: resPage, limit: resLimit);
    } catch (e) {
      rethrow;
    }
  }

  Future<RegulatoryLicenceModel> createLicence(Map<String, dynamic> payload) async {
    try {
      final response = await _apiClient.dio.post('/licences', data: payload);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return RegulatoryLicenceModel.fromJson(dataMap);
    } catch (e) {
      rethrow;
    }
  }

  Future<RegulatoryLicenceModel> updateLicence(String id, Map<String, dynamic> payload) async {
    try {
      final response = await _apiClient.dio.put('/licences/$id', data: payload);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return RegulatoryLicenceModel.fromJson(dataMap);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> processReminders() async {
    try {
      final response = await _apiClient.dio.post('/licences/process-reminders');
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return dataMap;
    } catch (e) {
      rethrow;
    }
  }

  Future<RegulatoryLicenceModel> dismissReminder(String id) async {
    try {
      final response = await _apiClient.dio.patch('/licences/$id/dismiss-reminder');
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return RegulatoryLicenceModel.fromJson(dataMap);
    } catch (e) {
      rethrow;
    }
  }
}
