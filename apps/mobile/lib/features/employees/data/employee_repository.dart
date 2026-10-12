import '../../../core/network/api_client.dart';
import '../domain/employee_models.dart';

class EmployeeRepository {
  final ApiClient _apiClient;

  EmployeeRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<({List<EmployeeModel> items, int total, int page, int limit})> fetchEmployees({
    int page = 1,
    int limit = 50,
    String? search,
    Department? department,
    EmploymentStatus? status,
    bool? isActive,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (department != null) queryParams['department'] = department.apiValue;
      if (status != null) queryParams['status'] = status.apiValue;
      if (isActive != null) queryParams['isActive'] = isActive;

      final response = await _apiClient.dio.get('/employees', queryParameters: queryParams);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      final dynamic listRaw = dataMap['data'] ?? dataMap['items'] ?? [];
      final List<dynamic> itemsList = listRaw is List ? listRaw : [];
      final items = itemsList
          .map((i) => EmployeeModel.fromJson(i as Map<String, dynamic>))
          .toList();

      final total = dataMap['total'] as int? ?? items.length;
      final resPage = dataMap['page'] as int? ?? page;
      final resLimit = dataMap['limit'] as int? ?? limit;

      return (items: items, total: total, page: resPage, limit: resLimit);
    } catch (e) {
      rethrow;
    }
  }

  Future<EmployeeModel> createEmployee(Map<String, dynamic> payload) async {
    try {
      final response = await _apiClient.dio.post('/employees', data: payload);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return EmployeeModel.fromJson(dataMap);
    } catch (e) {
      rethrow;
    }
  }

  Future<EmployeeModel> updateEmployee(String id, Map<String, dynamic> payload) async {
    try {
      final response = await _apiClient.dio.put('/employees/$id', data: payload);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return EmployeeModel.fromJson(dataMap);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deactivateEmployee(String id) async {
    try {
      await _apiClient.dio.delete('/employees/$id');
    } catch (e) {
      rethrow;
    }
  }
}
