enum QualityTargetType {
  intake('INTAKE', 'Milk Intake'),
  productionBatch('PRODUCTION_BATCH', 'Production Batch'),
  bmc('BMC', 'BMC Tank');

  final String value;
  final String label;
  const QualityTargetType(this.value, this.label);

  static QualityTargetType fromString(String val) {
    return QualityTargetType.values.firstWhere(
      (e) => e.value.toUpperCase() == val.toUpperCase(),
      orElse: () => QualityTargetType.productionBatch,
    );
  }
}

enum QualityDecision {
  approved('APPROVED', 'Approved'),
  rejected('REJECTED', 'Rejected'),
  pending('PENDING', 'Pending');

  final String value;
  final String label;
  const QualityDecision(this.value, this.label);

  static QualityDecision fromString(String val) {
    return QualityDecision.values.firstWhere(
      (e) => e.value.toUpperCase() == val.toUpperCase(),
      orElse: () => QualityDecision.pending,
    );
  }
}

class QualityRecordModel {
  final String id;
  final String recordDate;
  final QualityTargetType targetType;
  final String targetId;
  final double? fatPercentage;
  final double? snfPercentage;
  final double? clr;
  final double? ph;
  final double? temperatureC;
  final QualityDecision decision;
  final String? testedBy;
  final String? notes;
  final DateTime? createdAt;

  QualityRecordModel({
    required this.id,
    required this.recordDate,
    required this.targetType,
    required this.targetId,
    this.fatPercentage,
    this.snfPercentage,
    this.clr,
    this.ph,
    this.temperatureC,
    required this.decision,
    this.testedBy,
    this.notes,
    this.createdAt,
  });

  factory QualityRecordModel.fromJson(Map<String, dynamic> json) {
    return QualityRecordModel(
      id: json['id'] as String? ?? '',
      recordDate: json['record_date'] as String? ?? json['recordDate'] as String? ?? '',
      targetType: QualityTargetType.fromString(
        json['target_type'] as String? ?? json['targetType'] as String? ?? 'PRODUCTION_BATCH',
      ),
      targetId: json['target_id'] as String? ?? json['targetId'] as String? ?? '',
      fatPercentage: (json['fat_percentage'] ?? json['fatPercentage']) is num
          ? (json['fat_percentage'] ?? json['fatPercentage'] as num).toDouble()
          : null,
      snfPercentage: (json['snf_percentage'] ?? json['snfPercentage']) is num
          ? (json['snf_percentage'] ?? json['snfPercentage'] as num).toDouble()
          : null,
      clr: (json['clr']) is num ? (json['clr'] as num).toDouble() : null,
      ph: (json['ph']) is num ? (json['ph'] as num).toDouble() : null,
      temperatureC: (json['temperature_c'] ?? json['temperatureC']) is num
          ? (json['temperature_c'] ?? json['temperatureC'] as num).toDouble()
          : null,
      decision: QualityDecision.fromString(
        json['decision'] as String? ?? 'PENDING',
      ),
      testedBy: json['tested_by'] as String? ?? json['testedBy'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }
}
