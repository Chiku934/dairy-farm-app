import 'package:flutter/foundation.dart';

enum CareType {
  treatment('TREATMENT', 'Treatment'),
  vaccination('VACCINATION', 'Vaccination'),
  deworming('DEWORMING', 'Deworming'),
  examination('EXAMINATION', 'Examination');

  final String apiValue;
  final String label;
  const CareType(this.apiValue, this.label);

  static CareType fromString(String? value) {
    if (value == null) return CareType.treatment;
    return CareType.values.firstWhere(
      (c) => c.apiValue.toUpperCase() == value.toUpperCase(),
      orElse: () => CareType.treatment,
    );
  }
}

@immutable
class HealthRecordModel {
  final String id;
  final String animalId;
  final String? earTag;
  final String? animalName;
  final String recordDate;
  final CareType careType;
  final String? diagnosis;
  final String medicineVaccine;
  final String prescribedDose;
  final String? veterinarian;
  final String? nextDueDate;
  final String? withdrawalUntil;
  final String? notes;
  final DateTime createdAt;

  const HealthRecordModel({
    required this.id,
    required this.animalId,
    this.earTag,
    this.animalName,
    required this.recordDate,
    required this.careType,
    this.diagnosis,
    required this.medicineVaccine,
    required this.prescribedDose,
    this.veterinarian,
    this.nextDueDate,
    this.withdrawalUntil,
    this.notes,
    required this.createdAt,
  });

  factory HealthRecordModel.fromJson(Map<String, dynamic> json) {
    final animal = json['animal'] as Map<String, dynamic>?;

    return HealthRecordModel(
      id: json['id'] as String,
      animalId: json['animalId'] ?? json['animal_id'] ?? '',
      earTag: animal?['earTag'] ?? animal?['ear_tag'] ?? json['earTag'] as String?,
      animalName: animal?['name'] ?? json['animalName'] as String?,
      recordDate: json['recordDate'] ?? json['record_date'] ?? '',
      careType: CareType.fromString(json['careType'] ?? json['care_type'] as String?),
      diagnosis: json['diagnosis'] as String?,
      medicineVaccine: json['medicineVaccine'] ?? json['medicine_vaccine'] ?? '',
      prescribedDose: json['prescribedDose'] ?? json['prescribed_dose'] ?? '',
      veterinarian: json['veterinarian'] as String?,
      nextDueDate: json['nextDueDate'] ?? json['next_due_date'] as String?,
      withdrawalUntil: json['withdrawalUntil'] ?? json['withdrawal_until'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

@immutable
class HealthReminderModel {
  final String id;
  final String animalId;
  final String earTag;
  final String? animalName;
  final CareType careType;
  final String medicineVaccine;
  final String nextDueDate;
  final int daysRemaining;
  final bool isOverdue;
  final String? notes;

  const HealthReminderModel({
    required this.id,
    required this.animalId,
    required this.earTag,
    this.animalName,
    required this.careType,
    required this.medicineVaccine,
    required this.nextDueDate,
    required this.daysRemaining,
    required this.isOverdue,
    this.notes,
  });

  factory HealthReminderModel.fromJson(Map<String, dynamic> json) {
    return HealthReminderModel(
      id: json['id'] as String,
      animalId: json['animalId'] as String,
      earTag: json['earTag'] as String,
      animalName: json['animalName'] as String?,
      careType: CareType.fromString(json['careType'] as String?),
      medicineVaccine: json['medicineVaccine'] as String,
      nextDueDate: json['nextDueDate'] as String,
      daysRemaining: json['daysRemaining'] as int? ?? 0,
      isOverdue: json['isOverdue'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }
}

@immutable
class ActiveWithdrawalModel {
  final String id;
  final String animalId;
  final String earTag;
  final String? animalName;
  final String medicineVaccine;
  final String prescribedDose;
  final String withdrawalUntil;
  final int daysRemaining;
  final String? notes;

  const ActiveWithdrawalModel({
    required this.id,
    required this.animalId,
    required this.earTag,
    this.animalName,
    required this.medicineVaccine,
    required this.prescribedDose,
    required this.withdrawalUntil,
    required this.daysRemaining,
    this.notes,
  });

  factory ActiveWithdrawalModel.fromJson(Map<String, dynamic> json) {
    return ActiveWithdrawalModel(
      id: json['id'] as String,
      animalId: json['animalId'] as String,
      earTag: json['earTag'] as String,
      animalName: json['animalName'] as String?,
      medicineVaccine: json['medicineVaccine'] as String,
      prescribedDose: json['prescribedDose'] as String,
      withdrawalUntil: json['withdrawalUntil'] as String,
      daysRemaining: json['daysRemaining'] as int? ?? 0,
      notes: json['notes'] as String?,
    );
  }
}
