enum ProductType {
  milk('MILK', 'Fresh Pouch Milk', 'LITRE'),
  paneer('PANEER', 'Malai Paneer', 'KG'),
  khoya('KHOYA', 'Mawa / Khoya', 'KG'),
  ghee('GHEE', 'Pure Desi Ghee', 'KG'),
  dahi('DAHI', 'Fresh Curd / Dahi', 'KG'),
  butter('BUTTER', 'Table Butter', 'KG'),
  biogasFertiliser('BIOGAS_FERTILISER', 'Dry Bio-Fertiliser', 'KG');

  final String value;
  final String label;
  final String defaultUnit;
  const ProductType(this.value, this.label, this.defaultUnit);

  static ProductType fromString(String val) {
    return ProductType.values.firstWhere(
      (e) => e.value.toUpperCase() == val.toUpperCase(),
      orElse: () => ProductType.paneer,
    );
  }
}

enum QualityReleaseStatus {
  hold('HOLD', 'On Hold'),
  approved('APPROVED', 'Approved & Cleared'),
  rejected('REJECTED', 'Rejected');

  final String value;
  final String label;
  const QualityReleaseStatus(this.value, this.label);

  static QualityReleaseStatus fromString(String val) {
    return QualityReleaseStatus.values.firstWhere(
      (e) => e.value.toUpperCase() == val.toUpperCase(),
      orElse: () => QualityReleaseStatus.hold,
    );
  }
}

enum BatchStatus {
  planned('PLANNED', 'Planned'),
  inProgress('IN_PROGRESS', 'In Progress'),
  completed('COMPLETED', 'Completed'),
  cancelled('CANCELLED', 'Cancelled');

  final String value;
  final String label;
  const BatchStatus(this.value, this.label);

  static BatchStatus fromString(String val) {
    return BatchStatus.values.firstWhere(
      (e) => e.value.toUpperCase() == val.toUpperCase(),
      orElse: () => BatchStatus.completed,
    );
  }
}

class ProductionBatchModel {
  final String id;
  final String batchNumber;
  final String recordDate;
  final String shift;
  final ProductType productType;
  final BatchStatus status;
  final double bmcMilkConsumedL;
  final double finishedQuantity;
  final double yieldPercentage;
  final String unitOfMeasure;
  final double lpgUsedKg;
  final double byproductQuantityKg;
  final String expiryDate;
  final QualityReleaseStatus qualityRelease;
  final String? notes;
  final String? operatorName;
  final DateTime createdAt;
  final int linkedIntakesCount;

  const ProductionBatchModel({
    required this.id,
    required this.batchNumber,
    required this.recordDate,
    required this.shift,
    required this.productType,
    required this.status,
    required this.bmcMilkConsumedL,
    required this.finishedQuantity,
    required this.yieldPercentage,
    required this.unitOfMeasure,
    required this.lpgUsedKg,
    required this.byproductQuantityKg,
    required this.expiryDate,
    required this.qualityRelease,
    this.notes,
    this.operatorName,
    required this.createdAt,
    this.linkedIntakesCount = 0,
  });

  factory ProductionBatchModel.fromJson(Map<String, dynamic> json) {
    final intakeLinks = json['intakeLinks'] as List<dynamic>? ?? [];

    return ProductionBatchModel(
      id: json['id'] as String,
      batchNumber: json['batchNumber'] ?? json['batch_number'] ?? '',
      recordDate: json['recordDate'] ?? json['record_date'] ?? '',
      shift: json['shift'] ?? 'AM',
      productType: ProductType.fromString(json['productType'] ?? json['product_type'] ?? 'PANEER'),
      status: BatchStatus.fromString(json['status'] ?? 'COMPLETED'),
      bmcMilkConsumedL: (json['bmcMilkConsumedL'] ?? json['bmc_milk_consumed_l'] ?? 0).toDouble(),
      finishedQuantity: (json['finishedQuantity'] ?? json['finished_quantity'] ?? 0).toDouble(),
      yieldPercentage: (json['yieldPercentage'] ?? json['yield_percentage'] ?? 0).toDouble(),
      unitOfMeasure: json['unitOfMeasure'] ?? json['unit_of_measure'] ?? 'KG',
      lpgUsedKg: (json['lpgUsedKg'] ?? json['lpg_used_kg'] ?? 0).toDouble(),
      byproductQuantityKg: (json['byproductQuantityKg'] ?? json['byproduct_quantity_kg'] ?? 0).toDouble(),
      expiryDate: json['expiryDate'] ?? json['expiry_date'] ?? '',
      qualityRelease: QualityReleaseStatus.fromString(json['qualityRelease'] ?? json['quality_release'] ?? 'HOLD'),
      notes: json['notes'],
      operatorName: json['operatorName'] ?? json['operator_name'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now()),
      linkedIntakesCount: intakeLinks.length,
    );
  }
}

class TraceabilityIntakeLot {
  final String intakeId;
  final String intakeBatchNumber;
  final String recordDate;
  final String shift;
  final String source;
  final String? supplierRoute;
  final double totalIntakeLitres;
  final double litresUsedInBatch;
  final String decision;
  final double? fatPercentage;
  final double? snfPercentage;
  final double? temperatureC;
  final double? clr;
  final double? ph;
  final String? intakeOperator;

  const TraceabilityIntakeLot({
    required this.intakeId,
    required this.intakeBatchNumber,
    required this.recordDate,
    required this.shift,
    required this.source,
    this.supplierRoute,
    required this.totalIntakeLitres,
    required this.litresUsedInBatch,
    required this.decision,
    this.fatPercentage,
    this.snfPercentage,
    this.temperatureC,
    this.clr,
    this.ph,
    this.intakeOperator,
  });

  factory TraceabilityIntakeLot.fromJson(Map<String, dynamic> json) {
    final qm = json['qualityMetrics'] as Map<String, dynamic>? ?? {};

    return TraceabilityIntakeLot(
      intakeId: json['intakeId'] ?? '',
      intakeBatchNumber: json['intakeBatchNumber'] ?? '',
      recordDate: json['recordDate'] ?? '',
      shift: json['shift'] ?? 'AM',
      source: json['source'] ?? 'FARM',
      supplierRoute: json['supplierRoute'],
      totalIntakeLitres: (json['totalIntakeLitres'] ?? 0).toDouble(),
      litresUsedInBatch: (json['litresUsedInBatch'] ?? 0).toDouble(),
      decision: json['decision'] ?? 'ACCEPTED',
      fatPercentage: qm['fatPercentage'] != null ? (qm['fatPercentage'] as num).toDouble() : null,
      snfPercentage: qm['snfPercentage'] != null ? (qm['snfPercentage'] as num).toDouble() : null,
      temperatureC: qm['temperatureC'] != null ? (qm['temperatureC'] as num).toDouble() : null,
      clr: qm['clr'] != null ? (qm['clr'] as num).toDouble() : null,
      ph: qm['ph'] != null ? (qm['ph'] as num).toDouble() : null,
      intakeOperator: json['intakeOperator'],
    );
  }
}

class ProductionTraceabilityModel {
  final String batchId;
  final String batchNumber;
  final String recordDate;
  final String shift;
  final ProductType productType;
  final BatchStatus status;
  final QualityReleaseStatus qualityRelease;
  final String expiryDate;
  final double bmcMilkConsumedL;
  final double finishedQuantity;
  final String unitOfMeasure;
  final double yieldPercentage;
  final double lpgUsedKg;
  final double byproductQuantityKg;
  final String? processOperator;
  final String? notes;
  final DateTime createdAt;
  final List<TraceabilityIntakeLot> intakeLots;

  const ProductionTraceabilityModel({
    required this.batchId,
    required this.batchNumber,
    required this.recordDate,
    required this.shift,
    required this.productType,
    required this.status,
    required this.qualityRelease,
    required this.expiryDate,
    required this.bmcMilkConsumedL,
    required this.finishedQuantity,
    required this.unitOfMeasure,
    required this.yieldPercentage,
    required this.lpgUsedKg,
    required this.byproductQuantityKg,
    this.processOperator,
    this.notes,
    required this.createdAt,
    required this.intakeLots,
  });

  factory ProductionTraceabilityModel.fromJson(Map<String, dynamic> json) {
    final lineage = json['lineage'] as Map<String, dynamic>? ?? {};
    final lotsRaw = lineage['intakeLots'] as List<dynamic>? ?? [];

    return ProductionTraceabilityModel(
      batchId: json['batchId'] ?? '',
      batchNumber: json['batchNumber'] ?? '',
      recordDate: json['recordDate'] ?? '',
      shift: json['shift'] ?? 'AM',
      productType: ProductType.fromString(json['productType'] ?? 'PANEER'),
      status: BatchStatus.fromString(json['status'] ?? 'COMPLETED'),
      qualityRelease: QualityReleaseStatus.fromString(json['qualityRelease'] ?? 'HOLD'),
      expiryDate: json['expiryDate'] ?? '',
      bmcMilkConsumedL: (json['bmcMilkConsumedL'] ?? 0).toDouble(),
      finishedQuantity: (json['finishedQuantity'] ?? 0).toDouble(),
      unitOfMeasure: json['unitOfMeasure'] ?? 'KG',
      yieldPercentage: (json['yieldPercentage'] ?? 0).toDouble(),
      lpgUsedKg: (json['lpgUsedKg'] ?? 0).toDouble(),
      byproductQuantityKg: (json['byproductQuantityKg'] ?? 0).toDouble(),
      processOperator: json['processOperator'],
      notes: json['notes'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      intakeLots: lotsRaw.map((l) => TraceabilityIntakeLot.fromJson(l as Map<String, dynamic>)).toList(),
    );
  }
}
