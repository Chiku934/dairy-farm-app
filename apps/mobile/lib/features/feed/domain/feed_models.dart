import 'package:flutter/foundation.dart';

enum FeedType {
  concentrate('CONCENTRATE', 'Concentrate Pellets'),
  greenFodder('GREEN_FODDER', 'Green Fodder (Napier/Maize)'),
  dryFodder('DRY_FODDER', 'Dry Fodder (Bhusa/Straw)'),
  mineralMixture('MINERAL_MIXTURE', 'Mineral Mixture'),
  salt('SALT', 'Feed Salt'),
  maize('MAIZE', 'Crushed Maize Grain'),
  calfStarter('CALF_STARTER', 'Calf Starter Formula');

  final String apiValue;
  final String label;
  const FeedType(this.apiValue, this.label);

  static FeedType fromString(String? value) {
    if (value == null) return FeedType.concentrate;
    return FeedType.values.firstWhere(
      (f) => f.apiValue.toUpperCase() == value.toUpperCase(),
      orElse: () => FeedType.concentrate,
    );
  }
}

enum FeedShift {
  morning('MORNING', 'Morning'),
  evening('EVENING', 'Evening'),
  allDay('ALL_DAY', 'All Day / Total');

  final String apiValue;
  final String label;
  const FeedShift(this.apiValue, this.label);

  static FeedShift fromString(String? value) {
    if (value == null) return FeedShift.allDay;
    return FeedShift.values.firstWhere(
      (s) => s.apiValue.toUpperCase() == value.toUpperCase(),
      orElse: () => FeedShift.allDay,
    );
  }
}

enum TargetAnimalStage {
  lactating('LACTATING', 'Lactating Cows'),
  dry('DRY', 'Dry Period Cows'),
  pregnant('PREGNANT', 'Pregnant / Transition'),
  heifer('HEIFER', 'Growing Heifers'),
  calf('CALF', 'Young Calves'),
  bull('BULL', 'Bulls'),
  all('ALL', 'All Herd Stages');

  final String apiValue;
  final String label;
  const TargetAnimalStage(this.apiValue, this.label);

  static TargetAnimalStage fromString(String? value) {
    if (value == null) return TargetAnimalStage.lactating;
    return TargetAnimalStage.values.firstWhere(
      (s) => s.apiValue.toUpperCase() == value.toUpperCase(),
      orElse: () => TargetAnimalStage.lactating,
    );
  }
}

@immutable
class FeedEntryModel {
  final String id;
  final String? animalId;
  final String? animalEarTag;
  final String? groupName;
  final String? rationId;
  final String? rationName;
  final String recordDate;
  final String stockItemId;
  final String stockItemName;
  final double quantityKg;
  final double unitCost;
  final double totalCost;
  final FeedShift shift;
  final FeedType feedType;
  final String? notes;
  final DateTime createdAt;

  const FeedEntryModel({
    required this.id,
    this.animalId,
    this.animalEarTag,
    this.groupName,
    this.rationId,
    this.rationName,
    required this.recordDate,
    required this.stockItemId,
    required this.stockItemName,
    required this.quantityKg,
    required this.unitCost,
    required this.totalCost,
    required this.shift,
    required this.feedType,
    this.notes,
    required this.createdAt,
  });

  String get targetTitle => animalEarTag != null ? 'Cow #$animalEarTag' : (groupName ?? 'General Herd');

  factory FeedEntryModel.fromJson(Map<String, dynamic> json) {
    final animalJson = json['animal'] as Map<String, dynamic>?;
    final stockJson = json['stock_item'] as Map<String, dynamic>?;
    final rationJson = json['ration'] as Map<String, dynamic>?;

    return FeedEntryModel(
      id: json['id'] as String,
      animalId: json['animal_id'] as String?,
      animalEarTag: animalJson != null ? animalJson['ear_tag'] as String? : null,
      groupName: json['group_name'] as String?,
      rationId: json['ration_id'] as String?,
      rationName: rationJson != null ? rationJson['name'] as String? : null,
      recordDate: json['record_date'] as String,
      stockItemId: json['stock_item_id'] as String,
      stockItemName: stockJson != null ? stockJson['name'] as String? ?? 'Feed Item' : 'Feed Item',
      quantityKg: (json['quantity_kg'] is num)
          ? (json['quantity_kg'] as num).toDouble()
          : double.tryParse(json['quantity_kg']?.toString() ?? '0') ?? 0.0,
      unitCost: (json['unit_cost'] is num)
          ? (json['unit_cost'] as num).toDouble()
          : double.tryParse(json['unit_cost']?.toString() ?? '0') ?? 0.0,
      totalCost: (json['total_cost'] is num)
          ? (json['total_cost'] as num).toDouble()
          : double.tryParse(json['total_cost']?.toString() ?? '0') ?? 0.0,
      shift: FeedShift.fromString(json['shift'] as String?),
      feedType: FeedType.fromString(json['feed_type'] as String?),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

@immutable
class RationItemModel {
  final String id;
  final String stockItemId;
  final String stockItemName;
  final double unitPrice;
  final double quantityKg;
  final double itemCost;
  final String? notes;

  const RationItemModel({
    required this.id,
    required this.stockItemId,
    required this.stockItemName,
    required this.unitPrice,
    required this.quantityKg,
    required this.itemCost,
    this.notes,
  });

  factory RationItemModel.fromJson(Map<String, dynamic> json) {
    final stockJson = json['stock_item'] as Map<String, dynamic>?;
    final price = stockJson != null && stockJson['weighted_avg_price'] is num
        ? (stockJson['weighted_avg_price'] as num).toDouble()
        : double.tryParse(stockJson?['weighted_avg_price']?.toString() ?? '0') ?? 0.0;
    final qty = (json['quantity_kg'] is num)
        ? (json['quantity_kg'] as num).toDouble()
        : double.tryParse(json['quantity_kg']?.toString() ?? '0') ?? 0.0;

    return RationItemModel(
      id: json['id'] as String,
      stockItemId: json['stock_item_id'] as String,
      stockItemName: stockJson != null ? stockJson['name'] as String? ?? 'Feed Item' : 'Feed Item',
      unitPrice: price,
      quantityKg: qty,
      itemCost: (json['itemCost'] is num) ? (json['itemCost'] as num).toDouble() : (qty * price),
      notes: json['notes'] as String?,
    );
  }
}

@immutable
class RationDefinitionModel {
  final String id;
  final String name;
  final String code;
  final TargetAnimalStage targetStage;
  final String? description;
  final bool isActive;
  final List<RationItemModel> items;
  final double totalQuantityKg;
  final double totalCost;
  final double unitCostPerKg;

  const RationDefinitionModel({
    required this.id,
    required this.name,
    required this.code,
    required this.targetStage,
    this.description,
    required this.isActive,
    required this.items,
    required this.totalQuantityKg,
    required this.totalCost,
    required this.unitCostPerKg,
  });

  factory RationDefinitionModel.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'] as List<dynamic>? ?? [];
    final itemsList = itemsRaw.map((i) => RationItemModel.fromJson(i as Map<String, dynamic>)).toList();

    return RationDefinitionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      targetStage: TargetAnimalStage.fromString(json['target_stage'] as String?),
      description: json['description'] as String?,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      items: itemsList,
      totalQuantityKg: (json['totalQuantityKg'] is num)
          ? (json['totalQuantityKg'] as num).toDouble()
          : double.tryParse(json['totalQuantityKg']?.toString() ?? '0') ?? 0.0,
      totalCost: (json['totalCost'] is num)
          ? (json['totalCost'] as num).toDouble()
          : double.tryParse(json['totalCost']?.toString() ?? '0') ?? 0.0,
      unitCostPerKg: (json['unitCostPerKg'] is num)
          ? (json['unitCostPerKg'] as num).toDouble()
          : double.tryParse(json['unitCostPerKg']?.toString() ?? '0') ?? 0.0,
    );
  }
}

@immutable
class ConcentrateTargetModel {
  final String animalId;
  final String earTag;
  final String breed;
  final String status;
  final double feedBaseKg;
  final double feedRatePerLitre;
  final double feedMaxCapKg;
  final int daysEvaluated;
  final double avgDailyYieldLitres;
  final double targetConcentrateKg;
  final String calculationMethod;

  const ConcentrateTargetModel({
    required this.animalId,
    required this.earTag,
    required this.breed,
    required this.status,
    required this.feedBaseKg,
    required this.feedRatePerLitre,
    required this.feedMaxCapKg,
    required this.daysEvaluated,
    required this.avgDailyYieldLitres,
    required this.targetConcentrateKg,
    required this.calculationMethod,
  });

  factory ConcentrateTargetModel.fromJson(Map<String, dynamic> json) {
    return ConcentrateTargetModel(
      animalId: json['animalId'] as String,
      earTag: json['earTag'] as String,
      breed: json['breed'] as String? ?? 'Holstein Friesian',
      status: json['status'] as String? ?? 'LACTATING',
      feedBaseKg: (json['feedBaseKg'] is num) ? (json['feedBaseKg'] as num).toDouble() : 1.0,
      feedRatePerLitre: (json['feedRatePerLitre'] is num) ? (json['feedRatePerLitre'] as num).toDouble() : 0.4,
      feedMaxCapKg: (json['feedMaxCapKg'] is num) ? (json['feedMaxCapKg'] as num).toDouble() : 8.0,
      daysEvaluated: (json['daysEvaluated'] is num) ? (json['daysEvaluated'] as num).toInt() : 0,
      avgDailyYieldLitres: (json['avgDailyYieldLitres'] is num)
          ? (json['avgDailyYieldLitres'] as num).toDouble()
          : 0.0,
      targetConcentrateKg: (json['targetConcentrateKg'] is num)
          ? (json['targetConcentrateKg'] as num).toDouble()
          : 1.0,
      calculationMethod: json['calculationMethod'] as String? ?? 'STANDARD',
    );
  }
}
