import 'package:flutter/foundation.dart';

@immutable
class CostingBreakdownModel {
  final double feedCost;
  final double medicineCost;
  final double materialsCost;
  final double dailySalaries;
  final double electricityCost;
  final double otherExpenses;
  final bool isElectricityDefaulted;

  const CostingBreakdownModel({
    required this.feedCost,
    required this.medicineCost,
    required this.materialsCost,
    required this.dailySalaries,
    required this.electricityCost,
    required this.otherExpenses,
    required this.isElectricityDefaulted,
  });

  factory CostingBreakdownModel.fromJson(Map<String, dynamic> json) {
    return CostingBreakdownModel(
      feedCost: (json['feedCost'] is num) ? (json['feedCost'] as num).toDouble() : 0.0,
      medicineCost: (json['medicineCost'] is num) ? (json['medicineCost'] as num).toDouble() : 0.0,
      materialsCost: (json['materialsCost'] is num) ? (json['materialsCost'] as num).toDouble() : 0.0,
      dailySalaries: (json['dailySalaries'] is num) ? (json['dailySalaries'] as num).toDouble() : 0.0,
      electricityCost: (json['electricityCost'] is num) ? (json['electricityCost'] as num).toDouble() : 0.0,
      otherExpenses: (json['otherExpenses'] is num) ? (json['otherExpenses'] as num).toDouble() : 0.0,
      isElectricityDefaulted: json['isElectricityDefaulted'] == true,
    );
  }
}

@immutable
class DailyMilkCostingModel {
  final String date;
  final double totalDailyFarmCost;
  final double eligibleMilkLitres;
  final double totalMilkRecordedLitres;
  final double withheldMilkLitres;
  final double? costPerLitre;
  final String status;
  final String? warningMessage;
  final CostingBreakdownModel breakdown;
  final String currency;

  const DailyMilkCostingModel({
    required this.date,
    required this.totalDailyFarmCost,
    required this.eligibleMilkLitres,
    required this.totalMilkRecordedLitres,
    required this.withheldMilkLitres,
    this.costPerLitre,
    required this.status,
    this.warningMessage,
    required this.breakdown,
    required this.currency,
  });

  bool get isComplete => status.toUpperCase() == 'COMPLETE' && costPerLitre != null;

  factory DailyMilkCostingModel.fromJson(Map<String, dynamic> json) {
    return DailyMilkCostingModel(
      date: json['date'] as String,
      totalDailyFarmCost: (json['totalDailyFarmCost'] is num)
          ? (json['totalDailyFarmCost'] as num).toDouble()
          : 0.0,
      eligibleMilkLitres: (json['eligibleMilkLitres'] is num)
          ? (json['eligibleMilkLitres'] as num).toDouble()
          : 0.0,
      totalMilkRecordedLitres: (json['totalMilkRecordedLitres'] is num)
          ? (json['totalMilkRecordedLitres'] as num).toDouble()
          : 0.0,
      withheldMilkLitres: (json['withheldMilkLitres'] is num)
          ? (json['withheldMilkLitres'] as num).toDouble()
          : 0.0,
      costPerLitre: (json['costPerLitre'] is num) ? (json['costPerLitre'] as num).toDouble() : null,
      status: json['status'] as String? ?? 'INCOMPLETE',
      warningMessage: json['warningMessage'] as String?,
      breakdown: CostingBreakdownModel.fromJson(
        json['breakdown'] as Map<String, dynamic>? ?? {},
      ),
      currency: json['currency'] as String? ?? '₹',
    );
  }
}
