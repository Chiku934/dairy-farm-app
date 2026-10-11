import 'package:flutter/material.dart';

enum DashboardPeriodFilter {
  today('today', 'Today'),
  week('week', 'Last 7 Days'),
  month('month', 'This Month'),
  custom('custom', 'Custom Range');

  final String apiValue;
  final String label;
  const DashboardPeriodFilter(this.apiValue, this.label);
}

class KpiMetricModel {
  final double value;
  final String? unit;
  final String? currency;
  final String label;
  final double? priorValue;
  final double? deltaPercent;
  final double? amYield;
  final double? pmYield;
  final bool isRestricted;

  const KpiMetricModel({
    required this.value,
    this.unit,
    this.currency,
    required this.label,
    this.priorValue,
    this.deltaPercent,
    this.amYield,
    this.pmYield,
    this.isRestricted = false,
  });

  factory KpiMetricModel.fromJson(Map<String, dynamic> json) {
    return KpiMetricModel(
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String?,
      currency: json['currency'] as String?,
      label: json['label'] as String? ?? '',
      priorValue: (json['priorValue'] as num?)?.toDouble(),
      deltaPercent: (json['deltaPercent'] as num?)?.toDouble(),
      amYield: (json['amYield'] as num?)?.toDouble(),
      pmYield: (json['pmYield'] as num?)?.toDouble(),
      isRestricted: json['isRestricted'] as bool? ?? false,
    );
  }
}

class CostPerLitreModel {
  final double? value;
  final String currency;
  final String label;
  final String status; // 'CALCULATED', 'INCOMPLETE', 'RESTRICTED'
  final String formulaExplanation;

  const CostPerLitreModel({
    this.value,
    this.currency = '₹',
    required this.label,
    required this.status,
    required this.formulaExplanation,
  });

  factory CostPerLitreModel.fromJson(Map<String, dynamic> json) {
    return CostPerLitreModel(
      value: (json['value'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? '₹',
      label: json['label'] as String? ?? 'Cost per Litre',
      status: json['status'] as String? ?? 'INCOMPLETE',
      formulaExplanation: json['formulaExplanation'] as String? ?? '',
    );
  }
}

class HerdSummaryModel {
  final int totalActive;
  final int lactating;
  final int dry;
  final int pregnant;
  final int heifersCalves;
  final int bulls;

  const HerdSummaryModel({
    required this.totalActive,
    required this.lactating,
    required this.dry,
    required this.pregnant,
    required this.heifersCalves,
    required this.bulls,
  });

  factory HerdSummaryModel.fromJson(Map<String, dynamic> json) {
    return HerdSummaryModel(
      totalActive: json['totalActive'] as int? ?? 0,
      lactating: json['lactating'] as int? ?? 0,
      dry: json['dry'] as int? ?? 0,
      pregnant: json['pregnant'] as int? ?? 0,
      heifersCalves: json['heifersCalves'] as int? ?? 0,
      bulls: json['bulls'] as int? ?? 0,
    );
  }
}

class BmcStatusModel {
  final double capacityLitres;
  final double currentBalanceLitres;
  final double utilizationPercent;
  final String status; // 'NORMAL', 'WARNING', 'CRITICAL'

  const BmcStatusModel({
    required this.capacityLitres,
    required this.currentBalanceLitres,
    required this.utilizationPercent,
    required this.status,
  });

  factory BmcStatusModel.fromJson(Map<String, dynamic> json) {
    return BmcStatusModel(
      capacityLitres: (json['capacityLitres'] as num?)?.toDouble() ?? 2000.0,
      currentBalanceLitres: (json['currentBalanceLitres'] as num?)?.toDouble() ?? 0.0,
      utilizationPercent: (json['utilizationPercent'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'NORMAL',
    );
  }
}

class DashboardAlertModel {
  final String id;
  final String type;
  final String severity; // 'INFO', 'WARNING', 'CRITICAL'
  final String title;
  final String description;
  final int? daysRemaining;

  const DashboardAlertModel({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    this.daysRemaining,
  });

  factory DashboardAlertModel.fromJson(Map<String, dynamic> json) {
    return DashboardAlertModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      severity: json['severity'] as String? ?? 'INFO',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      daysRemaining: json['daysRemaining'] as int?,
    );
  }
}

class DailyYieldTrendModel {
  final String date;
  final double morningYield;
  final double eveningYield;
  final double totalYield;

  const DailyYieldTrendModel({
    required this.date,
    required this.morningYield,
    required this.eveningYield,
    required this.totalYield,
  });

  factory DailyYieldTrendModel.fromJson(Map<String, dynamic> json) {
    return DailyYieldTrendModel(
      date: json['date'] as String? ?? '',
      morningYield: (json['morningYield'] as num?)?.toDouble() ?? 0.0,
      eveningYield: (json['eveningYield'] as num?)?.toDouble() ?? 0.0,
      totalYield: (json['totalYield'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DailyRevenueTrendModel {
  final String date;
  final double amount;

  const DailyRevenueTrendModel({
    required this.date,
    required this.amount,
  });

  factory DailyRevenueTrendModel.fromJson(Map<String, dynamic> json) {
    return DailyRevenueTrendModel(
      date: json['date'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class RecentActivityModel {
  final String id;
  final DateTime timestamp;
  final String category; // 'MILKING', 'BMC', 'SALES', 'HEALTH', 'QUALITY', 'AUDIT'
  final String title;
  final String description;
  final String? badge;

  const RecentActivityModel({
    required this.id,
    required this.timestamp,
    required this.category,
    required this.title,
    required this.description,
    this.badge,
  });

  factory RecentActivityModel.fromJson(Map<String, dynamic> json) {
    return RecentActivityModel(
      id: json['id'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      category: json['category'] as String? ?? 'AUDIT',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      badge: json['badge'] as String?,
    );
  }
}

class DashboardOverviewModel {
  final String periodType;
  final String startDate;
  final String endDate;
  final String periodLabel;
  final KpiMetricModel milkRecorded;
  final KpiMetricModel dryFertiliser;
  final KpiMetricModel? salesRevenue;
  final KpiMetricModel? operatingCost;
  final CostPerLitreModel costPerLitre;
  final HerdSummaryModel herd;
  final BmcStatusModel bmcTank;
  final int totalAlertsCount;
  final List<DashboardAlertModel> alerts;
  final List<DailyYieldTrendModel> dailyYields;
  final List<DailyRevenueTrendModel>? dailyRevenue;
  final List<RecentActivityModel> recentActivity;

  const DashboardOverviewModel({
    required this.periodType,
    required this.startDate,
    required this.endDate,
    required this.periodLabel,
    required this.milkRecorded,
    required this.dryFertiliser,
    this.salesRevenue,
    this.operatingCost,
    required this.costPerLitre,
    required this.herd,
    required this.bmcTank,
    required this.totalAlertsCount,
    required this.alerts,
    required this.dailyYields,
    this.dailyRevenue,
    required this.recentActivity,
  });

  factory DashboardOverviewModel.fromJson(Map<String, dynamic> json) {
    final period = json['period'] as Map<String, dynamic>? ?? {};
    final kpis = json['kpis'] as Map<String, dynamic>? ?? {};
    final herdJson = json['herd'] as Map<String, dynamic>? ?? {};
    final bmcJson = json['bmcTank'] as Map<String, dynamic>? ?? {};
    final alertsJson = json['alerts'] as Map<String, dynamic>? ?? {};
    final trendsJson = json['trends'] as Map<String, dynamic>? ?? {};

    return DashboardOverviewModel(
      periodType: period['type'] as String? ?? 'today',
      startDate: period['startDate'] as String? ?? '',
      endDate: period['endDate'] as String? ?? '',
      periodLabel: period['label'] as String? ?? 'Today',
      milkRecorded: KpiMetricModel.fromJson(kpis['milkRecorded'] as Map<String, dynamic>? ?? {}),
      dryFertiliser: KpiMetricModel.fromJson(kpis['dryFertiliser'] as Map<String, dynamic>? ?? {}),
      salesRevenue: kpis['salesRevenue'] != null
          ? KpiMetricModel.fromJson(kpis['salesRevenue'] as Map<String, dynamic>)
          : null,
      operatingCost: kpis['operatingCost'] != null
          ? KpiMetricModel.fromJson(kpis['operatingCost'] as Map<String, dynamic>)
          : null,
      costPerLitre: CostPerLitreModel.fromJson(kpis['costPerLitre'] as Map<String, dynamic>? ?? {}),
      herd: HerdSummaryModel.fromJson(herdJson),
      bmcTank: BmcStatusModel.fromJson(bmcJson),
      totalAlertsCount: alertsJson['totalCount'] as int? ?? 0,
      alerts: (alertsJson['items'] as List<dynamic>? ?? [])
          .map((item) => DashboardAlertModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      dailyYields: (trendsJson['dailyYields'] as List<dynamic>? ?? [])
          .map((item) => DailyYieldTrendModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      dailyRevenue: trendsJson['dailyRevenue'] != null
          ? (trendsJson['dailyRevenue'] as List<dynamic>)
              .map((item) => DailyRevenueTrendModel.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
      recentActivity: (json['recentActivity'] as List<dynamic>? ?? [])
          .map((item) => RecentActivityModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
