enum MilkIntakeSource {
  farm('FARM', 'Internal Farm'),
  external('EXTERNAL', 'External Supplier');

  final String value;
  final String label;
  const MilkIntakeSource(this.value, this.label);

  static MilkIntakeSource fromString(String val) {
    return MilkIntakeSource.values.firstWhere(
      (e) => e.value.toUpperCase() == val.toUpperCase(),
      orElse: () => MilkIntakeSource.farm,
    );
  }
}

enum IntakeShift {
  am('AM', 'Morning (AM)'),
  pm('PM', 'Evening (PM)');

  final String value;
  final String label;
  const IntakeShift(this.value, this.label);

  static IntakeShift fromString(String val) {
    return IntakeShift.values.firstWhere(
      (e) => e.value.toUpperCase() == val.toUpperCase(),
      orElse: () => IntakeShift.am,
    );
  }
}

enum IntakeDecision {
  accepted('ACCEPTED', 'Accepted'),
  rejected('REJECTED', 'Rejected');

  final String value;
  final String label;
  const IntakeDecision(this.value, this.label);

  static IntakeDecision fromString(String val) {
    return IntakeDecision.values.firstWhere(
      (e) => e.value.toUpperCase() == val.toUpperCase(),
      orElse: () => IntakeDecision.accepted,
    );
  }
}

class BmcIntakeLogModel {
  final String id;
  final String batchNumber;
  final String recordDate;
  final IntakeShift shift;
  final MilkIntakeSource source;
  final String? supplierRoute;
  final double quantityLitres;
  final double externalTotalCost;
  final IntakeDecision decision;
  final String? rejectionReason;
  final double? temperatureC;
  final double? fatPercentage;
  final double? snfPercentage;
  final double? clr;
  final double? ph;
  final String? notes;
  final String? operatorName;
  final DateTime createdAt;

  const BmcIntakeLogModel({
    required this.id,
    required this.batchNumber,
    required this.recordDate,
    required this.shift,
    required this.source,
    this.supplierRoute,
    required this.quantityLitres,
    required this.externalTotalCost,
    required this.decision,
    this.rejectionReason,
    this.temperatureC,
    this.fatPercentage,
    this.snfPercentage,
    this.clr,
    this.ph,
    this.notes,
    this.operatorName,
    required this.createdAt,
  });

  factory BmcIntakeLogModel.fromJson(Map<String, dynamic> json) {
    return BmcIntakeLogModel(
      id: json['id'] as String,
      batchNumber: json['batchNumber'] ?? json['batch_number'] ?? '',
      recordDate: json['recordDate'] ?? json['record_date'] ?? '',
      shift: IntakeShift.fromString(json['shift'] ?? 'AM'),
      source: MilkIntakeSource.fromString(json['source'] ?? 'FARM'),
      supplierRoute: json['supplierRoute'] ?? json['supplier_route'],
      quantityLitres: (json['quantityLitres'] ?? json['quantity_litres'] ?? 0).toDouble(),
      externalTotalCost: (json['externalTotalCost'] ?? json['external_total_cost'] ?? 0).toDouble(),
      decision: IntakeDecision.fromString(json['decision'] ?? 'ACCEPTED'),
      rejectionReason: json['rejectionReason'] ?? json['rejection_reason'],
      temperatureC: json['temperatureC'] != null ? (json['temperatureC'] as num).toDouble() : (json['temperature_c'] != null ? (json['temperature_c'] as num).toDouble() : null),
      fatPercentage: json['fatPercentage'] != null ? (json['fatPercentage'] as num).toDouble() : (json['fat_percentage'] != null ? (json['fat_percentage'] as num).toDouble() : null),
      snfPercentage: json['snfPercentage'] != null ? (json['snfPercentage'] as num).toDouble() : (json['snf_percentage'] != null ? (json['snf_percentage'] as num).toDouble() : null),
      clr: json['clr'] != null ? (json['clr'] as num).toDouble() : null,
      ph: json['ph'] != null ? (json['ph'] as num).toDouble() : null,
      notes: json['notes'],
      operatorName: json['operatorName'] ?? json['operator_name'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now()),
    );
  }
}

class BmcTankBalanceModel {
  final double capacityLitres;
  final double currentBalanceLitres;
  final double availableCapacityLitres;
  final double utilizationPercentage;
  final String status;
  final double totalAcceptedIntake;
  final double totalProductionConsumed;
  final double totalWastageLost;
  final double todayFarmAccepted;
  final double todayExternalAccepted;
  final double todayRejected;

  const BmcTankBalanceModel({
    required this.capacityLitres,
    required this.currentBalanceLitres,
    required this.availableCapacityLitres,
    required this.utilizationPercentage,
    required this.status,
    required this.totalAcceptedIntake,
    required this.totalProductionConsumed,
    required this.totalWastageLost,
    required this.todayFarmAccepted,
    required this.todayExternalAccepted,
    required this.todayRejected,
  });

  factory BmcTankBalanceModel.fromJson(Map<String, dynamic> json) {
    final ledger = json['ledger'] as Map<String, dynamic>? ?? {};
    final today = json['today'] as Map<String, dynamic>? ?? {};

    return BmcTankBalanceModel(
      capacityLitres: (json['capacityLitres'] ?? 2000.0).toDouble(),
      currentBalanceLitres: (json['currentBalanceLitres'] ?? 0.0).toDouble(),
      availableCapacityLitres: (json['availableCapacityLitres'] ?? 0.0).toDouble(),
      utilizationPercentage: (json['utilizationPercentage'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'NORMAL',
      totalAcceptedIntake: (ledger['totalAcceptedIntake'] ?? 0.0).toDouble(),
      totalProductionConsumed: (ledger['totalProductionConsumed'] ?? 0.0).toDouble(),
      totalWastageLost: (ledger['totalWastageLost'] ?? 0.0).toDouble(),
      todayFarmAccepted: (today['farmAcceptedLitres'] ?? 0.0).toDouble(),
      todayExternalAccepted: (today['externalAcceptedLitres'] ?? 0.0).toDouble(),
      todayRejected: (today['rejectedLitres'] ?? 0.0).toDouble(),
    );
  }
}
