import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/costing_repository.dart';
import '../domain/costing_models.dart';

final costingRepositoryProvider = Provider<CostingRepository>((ref) {
  return CostingRepository();
});

class CostingSelectedDateNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void setDate(String? date) => state = date;
}

final costingSelectedDateProvider =
    NotifierProvider<CostingSelectedDateNotifier, String?>(CostingSelectedDateNotifier.new);

final dailyMilkCostingProvider = FutureProvider<DailyMilkCostingModel>((ref) async {
  final repo = ref.watch(costingRepositoryProvider);
  final date = ref.watch(costingSelectedDateProvider);

  return repo.fetchDailyMilkCosting(date: date);
});
