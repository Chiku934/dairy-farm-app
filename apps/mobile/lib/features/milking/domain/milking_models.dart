import 'package:flutter/foundation.dart';

enum MilkingSession {
  morning('MORNING', 'Morning'),
  evening('EVENING', 'Evening');

  final String apiValue;
  final String label;
  const MilkingSession(this.apiValue, this.label);

  static MilkingSession fromString(String? value) {
    if (value == null) return MilkingSession.morning;
    return MilkingSession.values.firstWhere(
      (s) => s.apiValue.toUpperCase() == value.toUpperCase(),
      orElse: () => MilkingSession.morning,
    );
  }
}

enum MilkDisposition {
  eligible('ELIGIBLE', 'Eligible for BMC', 'Eligible for bulk tank collection pool'),
  withheld('WITHHELD', 'Withheld (Safety)', 'Excluded from collection due to health/withdrawal'),
  calfFeeding('CALF_FEEDING', 'Calf Feeding', 'Diverted for calf nursery nutrition');

  final String apiValue;
  final String label;
  final String description;
  const MilkDisposition(this.apiValue, this.label, this.description);

  static MilkDisposition fromString(String? value) {
    if (value == null) return MilkDisposition.eligible;
    return MilkDisposition.values.firstWhere(
      (d) => d.apiValue.toUpperCase() == value.toUpperCase(),
      orElse: () => MilkDisposition.eligible,
    );
  }
}

@immutable
class MilkingLogModel {
  final String id;
  final String? animalId;
  final String? animalEarTag;
  final String? animalBreed;
  final String? groupName;
  final String recordDate;
  final MilkingSession session;
  final double yieldLitres;
  final MilkDisposition disposition;
  final String? withheldReason;
  final String? operatorId;
  final String? operatorName;
  final String? notes;
  final DateTime createdAt;

  const MilkingLogModel({
    required this.id,
    this.animalId,
    this.animalEarTag,
    this.animalBreed,
    this.groupName,
    required this.recordDate,
    required this.session,
    required this.yieldLitres,
    required this.disposition,
    this.withheldReason,
    this.operatorId,
    this.operatorName,
    this.notes,
    required this.createdAt,
  });

  String get targetTitle => animalEarTag != null ? 'Cow #$animalEarTag' : (groupName ?? 'General Herd');

  factory MilkingLogModel.fromJson(Map<String, dynamic> json) {
    final animalJson = json['animal'] as Map<String, dynamic>?;
    return MilkingLogModel(
      id: json['id'] as String,
      animalId: json['animal_id'] as String?,
      animalEarTag: animalJson != null ? animalJson['ear_tag'] as String? : null,
      animalBreed: animalJson != null ? animalJson['breed'] as String? : null,
      groupName: json['group_name'] as String?,
      recordDate: json['record_date'] as String,
      session: MilkingSession.fromString(json['session'] as String?),
      yieldLitres: (json['yield_litres'] is num)
          ? (json['yield_litres'] as num).toDouble()
          : double.tryParse(json['yield_litres']?.toString() ?? '0') ?? 0.0,
      disposition: MilkDisposition.fromString(json['disposition'] as String?),
      withheldReason: json['withheld_reason'] as String?,
      operatorId: json['operator_id'] as String?,
      operatorName: json['operator_name'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

@immutable
class MilkingSummaryModel {
  final double totalLitres;
  final double eligibleLitres;
  final double withheldLitres;
  final double calfFeedingLitres;
  final double morningLitres;
  final double eveningLitres;
  final int activeCowsMilked;
  final double avgLitresPerCow;

  const MilkingSummaryModel({
    required this.totalLitres,
    required this.eligibleLitres,
    required this.withheldLitres,
    required this.calfFeedingLitres,
    required this.morningLitres,
    required this.eveningLitres,
    required this.activeCowsMilked,
    required this.avgLitresPerCow,
  });

  factory MilkingSummaryModel.fromJson(Map<String, dynamic> json) {
    return MilkingSummaryModel(
      totalLitres: (json['totalLitres'] is num) ? (json['totalLitres'] as num).toDouble() : 0.0,
      eligibleLitres: (json['eligibleLitres'] is num) ? (json['eligibleLitres'] as num).toDouble() : 0.0,
      withheldLitres: (json['withheldLitres'] is num) ? (json['withheldLitres'] as num).toDouble() : 0.0,
      calfFeedingLitres: (json['calfFeedingLitres'] is num) ? (json['calfFeedingLitres'] as num).toDouble() : 0.0,
      morningLitres: (json['morningLitres'] is num) ? (json['morningLitres'] as num).toDouble() : 0.0,
      eveningLitres: (json['eveningLitres'] is num) ? (json['eveningLitres'] as num).toDouble() : 0.0,
      activeCowsMilked: (json['activeCowsMilked'] is num) ? (json['activeCowsMilked'] as num).toInt() : 0,
      avgLitresPerCow: (json['avgLitresPerCow'] is num) ? (json['avgLitresPerCow'] as num).toDouble() : 0.0,
    );
  }
}
