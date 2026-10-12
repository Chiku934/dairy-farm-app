import '../../../core/network/api_client.dart';
import '../domain/expense_models.dart';

class ExpenseRepository {
  final ApiClient _apiClient;

  ExpenseRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<({List<OperatingExpenseModel> items, int total, int totalPages, ExpenseSummaryModel summary})> fetchExpenses({
    int page = 1,
    int limit = 50,
    String? startDate,
    String? endDate,
    String? costCentre,
    String? category,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (startDate != null && startDate.isNotEmpty) queryParams['startDate'] = startDate;
      if (endDate != null && endDate.isNotEmpty) queryParams['endDate'] = endDate;
      if (costCentre != null && costCentre.isNotEmpty) queryParams['costCentre'] = costCentre;
      if (category != null && category.isNotEmpty) queryParams['category'] = category;

      final response = await _apiClient.dio.get('/expenses', queryParameters: queryParams);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      final itemsRaw = dataMap['items'] as List<dynamic>? ?? [];
      final items = itemsRaw.map((i) => OperatingExpenseModel.fromJson(i as Map<String, dynamic>)).toList();
      final total = dataMap['total'] as int? ?? items.length;
      final totalPages = dataMap['totalPages'] as int? ?? 1;
      final summary = dataMap['summary'] != null
          ? ExpenseSummaryModel.fromJson(dataMap['summary'] as Map<String, dynamic>)
          : const ExpenseSummaryModel();

      return (items: items, total: total, totalPages: totalPages, summary: summary);
    } catch (e) {
      rethrow;
    }
  }

  Future<OperatingExpenseModel> createExpense(Map<String, dynamic> payload) async {
    try {
      final response = await _apiClient.dio.post('/expenses', data: payload);
      final raw = response.data;
      final Map<String, dynamic> dataMap = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      return OperatingExpenseModel.fromJson(dataMap);
    } catch (e) {
      rethrow;
    }
  }
}
