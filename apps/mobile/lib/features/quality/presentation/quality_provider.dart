import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/quality_repository.dart';
import '../domain/quality_models.dart';

final qualityRepositoryProvider = Provider<QualityRepository>((ref) {
  return QualityRepository();
});

class QualityFilterState {
  final QualityTargetType? targetType;
  final QualityDecision? decision;
  final String? targetId;
  final String? startDate;
  final String? endDate;
  final int page;

  const QualityFilterState({
    this.targetType,
    this.decision,
    this.targetId,
    this.startDate,
    this.endDate,
    this.page = 1,
  });

  QualityFilterState copyWith({
    QualityTargetType? targetType,
    QualityDecision? decision,
    String? targetId,
    String? startDate,
    String? endDate,
    int? page,
    bool clearDecision = false,
  }) {
    return QualityFilterState(
      targetType: targetType ?? this.targetType,
      decision: clearDecision ? null : (decision ?? this.decision),
      targetId: targetId ?? this.targetId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      page: page ?? this.page,
    );
  }
}

class QualityFilterNotifier extends Notifier<QualityFilterState> {
  @override
  QualityFilterState build() => const QualityFilterState();

  void setDecision(QualityDecision? d) => state = state.copyWith(decision: d, clearDecision: d == null);
  void setTargetType(QualityTargetType? t) => state = state.copyWith(targetType: t);
  void setTargetId(String? id) => state = state.copyWith(targetId: id);
  void setPage(int p) => state = state.copyWith(page: p);
  void reset() => state = const QualityFilterState();
}

final qualityFilterProvider =
    NotifierProvider<QualityFilterNotifier, QualityFilterState>(QualityFilterNotifier.new);

final qualityRecordsProvider = FutureProvider<({List<QualityRecordModel> items, int total, int totalPages})>((ref) async {
  final repo = ref.watch(qualityRepositoryProvider);
  final filter = ref.watch(qualityFilterProvider);

  return repo.fetchRecords(
    page: filter.page,
    targetType: filter.targetType,
    decision: filter.decision,
    targetId: filter.targetId,
    startDate: filter.startDate,
    endDate: filter.endDate,
  );
});

final targetQualityRecordsProvider = FutureProvider.family<List<QualityRecordModel>, ({String type, String id})>((ref, arg) async {
  final repo = ref.watch(qualityRepositoryProvider);
  return repo.fetchRecordsByTarget(arg.type, arg.id);
});
