import 'package:flutter/foundation.dart';

enum AnimalStatus {
  lactating('LACTATING', 'Lactating'),
  dry('DRY', 'Dry'),
  pregnant('PREGNANT', 'Pregnant'),
  heifer('HEIFER', 'Heifer'),
  calf('CALF', 'Calf'),
  bull('BULL', 'Bull'),
  sold('SOLD', 'Sold'),
  deceased('DECEASED', 'Deceased');

  final String apiValue;
  final String label;
  const AnimalStatus(this.apiValue, this.label);

  static AnimalStatus fromString(String? value) {
    if (value == null) return AnimalStatus.lactating;
    return AnimalStatus.values.firstWhere(
      (s) => s.apiValue.toUpperCase() == value.toUpperCase(),
      orElse: () => AnimalStatus.lactating,
    );
  }
}

enum AnimalSex {
  female('FEMALE', 'Female'),
  male('MALE', 'Male');

  final String apiValue;
  final String label;
  const AnimalSex(this.apiValue, this.label);

  static AnimalSex fromString(String? value) {
    if (value == null) return AnimalSex.female;
    return AnimalSex.values.firstWhere(
      (s) => s.apiValue.toUpperCase() == value.toUpperCase(),
      orElse: () => AnimalSex.female,
    );
  }
}

@immutable
class AnimalModel {
  final String id;
  final String earTag;
  final String? name;
  final String breed;
  final AnimalSex sex;
  final String? dateOfBirth;
  final AnimalStatus status;
  final double? bodyWeightKg;
  final String? damTag;
  final String? lastCalvingDate;
  final double? bodyConditionScore;
  final String? notes;
  final bool isArchived;
  final String? archivedAt;
  final String? archiveReason;
  final DateTime createdAt;

  const AnimalModel({
    required this.id,
    required this.earTag,
    this.name,
    required this.breed,
    this.sex = AnimalSex.female,
    this.dateOfBirth,
    this.status = AnimalStatus.lactating,
    this.bodyWeightKg,
    this.damTag,
    this.lastCalvingDate,
    this.bodyConditionScore,
    this.notes,
    this.isArchived = false,
    this.archivedAt,
    this.archiveReason,
    required this.createdAt,
  });

  factory AnimalModel.fromJson(Map<String, dynamic> json) {
    return AnimalModel(
      id: json['id'] as String,
      earTag: json['earTag'] ?? json['ear_tag'] ?? '',
      name: json['name'] as String?,
      breed: json['breed'] ?? 'GIR',
      sex: AnimalSex.fromString(json['sex'] as String?),
      dateOfBirth: json['dateOfBirth'] ?? json['date_of_birth'] as String?,
      status: AnimalStatus.fromString(json['status'] as String?),
      bodyWeightKg: json['bodyWeightKg'] != null
          ? (json['bodyWeightKg'] as num).toDouble()
          : (json['body_weight_kg'] != null ? (json['body_weight_kg'] as num).toDouble() : null),
      damTag: json['damTag'] ?? json['dam_tag'] as String?,
      lastCalvingDate: json['lastCalvingDate'] ?? json['last_calving_date'] as String?,
      bodyConditionScore: json['bodyConditionScore'] != null
          ? (json['bodyConditionScore'] as num).toDouble()
          : (json['body_condition_score'] != null ? (json['body_condition_score'] as num).toDouble() : null),
      notes: json['notes'] as String?,
      isArchived: json['isArchived'] ?? json['is_archived'] ?? false,
      archivedAt: json['archivedAt'] ?? json['archived_at'] as String?,
      archiveReason: json['archiveReason'] ?? json['archive_reason'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String get displayName => (name != null && name!.isNotEmpty) ? '$earTag · $name' : earTag;

  String get ageString {
    if (dateOfBirth == null) return 'Age unknown';
    final dob = DateTime.tryParse(dateOfBirth!);
    if (dob == null) return 'Age unknown';
    final now = DateTime.now();
    final months = (now.year - dob.year) * 12 + now.month - dob.month;
    if (months < 1) return '< 1 month';
    if (months < 12) return '$months mo';
    final years = months ~/ 12;
    final remainingMonths = months % 12;
    return remainingMonths > 0 ? '$years y $remainingMonths m' : '$years yrs';
  }
}

@immutable
class HerdSummaryCountsModel {
  final int totalActive;
  final int lactating;
  final int dry;
  final int pregnant;
  final int heifer;
  final int calf;
  final int bull;
  final int archived;

  const HerdSummaryCountsModel({
    required this.totalActive,
    required this.lactating,
    required this.dry,
    required this.pregnant,
    required this.heifer,
    required this.calf,
    required this.bull,
    required this.archived,
  });

  factory HerdSummaryCountsModel.fromJson(Map<String, dynamic> json) {
    return HerdSummaryCountsModel(
      totalActive: json['totalActive'] as int? ?? 0,
      lactating: json['lactating'] as int? ?? 0,
      dry: json['dry'] as int? ?? 0,
      pregnant: json['pregnant'] as int? ?? 0,
      heifer: json['heifer'] as int? ?? 0,
      calf: json['calf'] as int? ?? 0,
      bull: json['bull'] as int? ?? 0,
      archived: json['archived'] as int? ?? 0,
    );
  }

  factory HerdSummaryCountsModel.empty() {
    return const HerdSummaryCountsModel(
      totalActive: 0,
      lactating: 0,
      dry: 0,
      pregnant: 0,
      heifer: 0,
      calf: 0,
      bull: 0,
      archived: 0,
    );
  }
}

@immutable
class AnimalTimelineItemModel {
  final String id;
  final String date;
  final String type; // HEALTH, BREEDING, MILKING
  final String title;
  final String subtitle;
  final Map<String, dynamic>? details;
  final String? badge;

  const AnimalTimelineItemModel({
    required this.id,
    required this.date,
    required this.type,
    required this.title,
    required this.subtitle,
    this.details,
    this.badge,
  });

  factory AnimalTimelineItemModel.fromJson(Map<String, dynamic> json) {
    return AnimalTimelineItemModel(
      id: json['id'] as String? ?? '',
      date: json['date'] as String? ?? '',
      type: json['type'] as String? ?? 'OTHER',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      details: json['details'] as Map<String, dynamic>?,
      badge: json['badge'] as String?,
    );
  }
}
