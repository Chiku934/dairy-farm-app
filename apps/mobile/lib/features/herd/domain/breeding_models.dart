import 'package:flutter/foundation.dart';

enum BreedingEventType {
  heat('HEAT', 'Heat'),
  insemination('INSEMINATION', 'Artificial Insemination (AI)'),
  pregnancyConfirmed('PREGNANCY_CONFIRMED', 'Pregnancy Confirmed'),
  pregnancyCheck('PREGNANCY_CHECK', 'Pregnancy Check'),
  calving('CALVING', 'Calving / Birth'),
  dryOff('DRY_OFF', 'Dry Off');

  final String apiValue;
  final String label;
  const BreedingEventType(this.apiValue, this.label);

  static BreedingEventType fromString(String? value) {
    if (value == null) return BreedingEventType.heat;
    return BreedingEventType.values.firstWhere(
      (e) => e.apiValue.toUpperCase() == value.toUpperCase(),
      orElse: () => BreedingEventType.heat,
    );
  }
}

@immutable
class BreedingRecordModel {
  final String id;
  final String animalId;
  final String? earTag;
  final String? animalName;
  final String recordDate;
  final BreedingEventType eventType;
  final String? sireSemenId;
  final String? expectedCalvingDate;
  final String? nextCheckDate;
  final String? calfTag;
  final String? notes;
  final DateTime createdAt;

  const BreedingRecordModel({
    required this.id,
    required this.animalId,
    this.earTag,
    this.animalName,
    required this.recordDate,
    required this.eventType,
    this.sireSemenId,
    this.expectedCalvingDate,
    this.nextCheckDate,
    this.calfTag,
    this.notes,
    required this.createdAt,
  });

  factory BreedingRecordModel.fromJson(Map<String, dynamic> json) {
    final animal = json['animal'] as Map<String, dynamic>?;

    return BreedingRecordModel(
      id: json['id'] as String,
      animalId: json['animalId'] ?? json['animal_id'] ?? '',
      earTag: animal?['earTag'] ?? animal?['ear_tag'] ?? json['earTag'] as String?,
      animalName: animal?['name'] ?? json['animalName'] as String?,
      recordDate: json['recordDate'] ?? json['record_date'] ?? '',
      eventType: BreedingEventType.fromString(json['eventType'] ?? json['event_type'] as String?),
      sireSemenId: json['sireSemenId'] ?? json['sire_semen_id'] as String?,
      expectedCalvingDate: json['expectedCalvingDate'] ?? json['expected_calving_date'] as String?,
      nextCheckDate: json['nextCheckDate'] ?? json['next_check_date'] as String?,
      calfTag: json['calfTag'] ?? json['calf_tag'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

@immutable
class BreedingReminderModel {
  final String id;
  final String animalId;
  final String earTag;
  final String? animalName;
  final String reminderType; // UPCOMING_CALVING or PREGNANCY_CHECK
  final String targetDate;
  final int daysRemaining;
  final String? sireSemenId;
  final String? notes;

  const BreedingReminderModel({
    required this.id,
    required this.animalId,
    required this.earTag,
    this.animalName,
    required this.reminderType,
    required this.targetDate,
    required this.daysRemaining,
    this.sireSemenId,
    this.notes,
  });

  factory BreedingReminderModel.fromJson(Map<String, dynamic> json) {
    return BreedingReminderModel(
      id: json['id'] as String,
      animalId: json['animalId'] as String,
      earTag: json['earTag'] as String,
      animalName: json['animalName'] as String?,
      reminderType: json['reminderType'] as String? ?? 'UPCOMING_CALVING',
      targetDate: json['targetDate'] as String,
      daysRemaining: json['daysRemaining'] as int? ?? 0,
      sireSemenId: json['sireSemenId'] as String?,
      notes: json['notes'] as String?,
    );
  }

  bool get isCalving => reminderType == 'UPCOMING_CALVING';
}
