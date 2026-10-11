import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dashboard_repository.dart';
import '../domain/dashboard_models.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository();
});

class PeriodFilterNotifier extends Notifier<DashboardPeriodFilter> {
  @override
  DashboardPeriodFilter build() => DashboardPeriodFilter.today;

  void setFilter(DashboardPeriodFilter filter) {
    state = filter;
  }
}

final dashboardPeriodFilterProvider =
    NotifierProvider<PeriodFilterNotifier, DashboardPeriodFilter>(PeriodFilterNotifier.new);

class DateRangeNotifier extends Notifier<DateTimeRange?> {
  @override
  DateTimeRange? build() => null;

  void setRange(DateTimeRange? range) {
    state = range;
  }
}

final customDateRangeProvider =
    NotifierProvider<DateRangeNotifier, DateTimeRange?>(DateRangeNotifier.new);

final dashboardOverviewProvider =
    FutureProvider.autoDispose<DashboardOverviewModel>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  final period = ref.watch(dashboardPeriodFilterProvider);
  final customRange = ref.watch(customDateRangeProvider);

  String? startDate;
  String? endDate;

  if (period == DashboardPeriodFilter.custom && customRange != null) {
    startDate = customRange.start.toIso8601String().substring(0, 10);
    endDate = customRange.end.toIso8601String().substring(0, 10);
  }

  return repository.fetchOverview(
    period: period,
    startDate: startDate,
    endDate: endDate,
  );
});
