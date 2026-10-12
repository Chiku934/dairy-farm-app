enum StockType {
  bmc('BMC', 'Raw BMC Milk'),
  bulkProduct('BULK_PRODUCT', 'Bulk Finished Product'),
  packagedProduct('PACKAGED_PRODUCT', 'Packaged Goods'),
  supply('SUPPLY', 'Consumables & Materials');

  final String apiValue;
  final String label;
  const StockType(this.apiValue, this.label);

  static StockType fromString(String? val) {
    return StockType.values.firstWhere(
      (e) => e.apiValue == val || e.name == val,
      orElse: () => StockType.supply,
    );
  }
}

enum WastageReason {
  spoilage('SPOILAGE', 'Spoilage / Souring'),
  handling('HANDLING', 'Handling / Physical Damage'),
  leakage('LEAKAGE', 'Leakage / Transfer Spill'),
  expiry('EXPIRY', 'Passed Expiry Date'),
  contamination('CONTAMINATION', 'Quality / Contamination'),
  equipmentFailure('EQUIPMENT_FAILURE', 'Equipment / Chiller Failure'),
  other('OTHER', 'Other Operational Loss');

  final String apiValue;
  final String label;
  const WastageReason(this.apiValue, this.label);

  static WastageReason fromString(String? val) {
    return WastageReason.values.firstWhere(
      (e) => e.apiValue == val || e.name == val,
      orElse: () => WastageReason.other,
    );
  }
}

class WastageRecordModel {
  final String id;
  final String? wastageNumber;
  final String recordDate;
  final StockType stockType;
  final String? stockItemId;
  final String? stockItemName;
  final String? productionBatchId;
  final String? batchNumber;
  final String referenceId;
  final double quantityLost;
  final String unit;
  final WastageReason reason;
  final double estimatedLossCost;
  final String? notes;
  final String? createdBy;
  final String? createdAt;

  WastageRecordModel({
    required this.id,
    this.wastageNumber,
    required this.recordDate,
    required this.stockType,
    this.stockItemId,
    this.stockItemName,
    this.productionBatchId,
    this.batchNumber,
    required this.referenceId,
    required this.quantityLost,
    required this.unit,
    required this.reason,
    required this.estimatedLossCost,
    this.notes,
    this.createdBy,
    this.createdAt,
  });

  factory WastageRecordModel.fromJson(Map<String, dynamic> json) {
    return WastageRecordModel(
      id: json['id'] as String? ?? '',
      wastageNumber: json['wastage_number'] as String?,
      recordDate: json['record_date'] != null
          ? json['record_date'].toString().split('T')[0]
          : DateTime.now().toIso8601String().split('T')[0],
      stockType: StockType.fromString(json['stock_type'] as String?),
      stockItemId: json['stock_item_id'] as String?,
      stockItemName: json['stock_item']?['name'] as String?,
      productionBatchId: json['production_batch_id'] as String?,
      batchNumber: json['production_batch']?['batch_number'] as String?,
      referenceId: json['reference_id'] as String? ?? '',
      quantityLost: (json['quantity_lost'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? '',
      reason: WastageReason.fromString(json['reason'] as String?),
      estimatedLossCost: (json['estimated_loss_cost'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (wastageNumber != null && wastageNumber!.isNotEmpty) 'wastageNumber': wastageNumber,
      'recordDate': recordDate,
      'stockType': stockType.apiValue,
      if (stockItemId != null) 'stockItemId': stockItemId,
      if (productionBatchId != null) 'productionBatchId': productionBatchId,
      'referenceId': referenceId,
      'quantityLost': quantityLost,
      'unit': unit,
      'reason': reason.apiValue,
      'estimatedLossCost': estimatedLossCost,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}

class WastageSummaryModel {
  final int totalIncidents;
  final double totalEstimatedLoss;
  final double bmcLossLitres;
  final double supplyLossValue;

  const WastageSummaryModel({
    this.totalIncidents = 0,
    this.totalEstimatedLoss = 0.0,
    this.bmcLossLitres = 0.0,
    this.supplyLossValue = 0.0,
  });

  factory WastageSummaryModel.fromJson(Map<String, dynamic> json) {
    return WastageSummaryModel(
      totalIncidents: (json['totalIncidents'] as num?)?.toInt() ?? 0,
      totalEstimatedLoss: (json['totalEstimatedLoss'] as num?)?.toDouble() ?? 0.0,
      bmcLossLitres: (json['bmcLossLitres'] as num?)?.toDouble() ?? 0.0,
      supplyLossValue: (json['supplyLossValue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
