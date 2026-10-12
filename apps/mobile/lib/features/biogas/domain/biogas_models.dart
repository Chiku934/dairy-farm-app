enum BiogasUsageType {
  internalFarm('INTERNAL_FARM', 'Internal Farm Application'),
  directSale('DIRECT_SALE', 'Direct Commercial Sale'),
  storeStock('STORE_STOCK', 'Store in Farm Inventory');

  final String apiValue;
  final String label;
  const BiogasUsageType(this.apiValue, this.label);

  static BiogasUsageType fromString(String? val) {
    return BiogasUsageType.values.firstWhere(
      (e) => e.apiValue == val || e.name == val,
      orElse: () => BiogasUsageType.storeStock,
    );
  }
}

class BiogasRunModel {
  final String id;
  final String? runNumber;
  final String recordDate;
  final double slurryInputKg;
  final double dryFertiliserOutputKg;
  final double moisturePct;
  final String? stockItemId;
  final String? stockItemName;
  final BiogasUsageType usageType;
  final double? usageQuantityKg;
  final double? saleAmount;
  final String? buyerOrFarmPlot;
  final int bags1kg;
  final int bags5kg;
  final int bags25kg;
  final int bags50kg;
  final double yieldPct;
  final double totalPackedKg;
  final String? notes;
  final String? createdBy;
  final String? createdAt;

  BiogasRunModel({
    required this.id,
    this.runNumber,
    required this.recordDate,
    required this.slurryInputKg,
    required this.dryFertiliserOutputKg,
    required this.moisturePct,
    this.stockItemId,
    this.stockItemName,
    required this.usageType,
    this.usageQuantityKg,
    this.saleAmount,
    this.buyerOrFarmPlot,
    this.bags1kg = 0,
    this.bags5kg = 0,
    this.bags25kg = 0,
    this.bags50kg = 0,
    required this.yieldPct,
    required this.totalPackedKg,
    this.notes,
    this.createdBy,
    this.createdAt,
  });

  factory BiogasRunModel.fromJson(Map<String, dynamic> json) {
    final slurry = (json['slurry_input_kg'] as num?)?.toDouble() ?? 0.0;
    final dry = (json['dry_fertiliser_output_kg'] as num?)?.toDouble() ?? 0.0;
    final b1 = (json['bags_packed_1kg'] as num?)?.toInt() ?? 0;
    final b5 = (json['bags_packed_5kg'] as num?)?.toInt() ?? 0;
    final b25 = (json['bags_packed_25kg'] as num?)?.toInt() ?? 0;
    final b50 = (json['bags_packed_50kg'] as num?)?.toInt() ?? 0;
    final packed = (b1 * 1.0) + (b5 * 5.0) + (b25 * 25.0) + (b50 * 50.0);
    final yld = slurry > 0 ? ((dry / slurry) * 100) : 0.0;

    return BiogasRunModel(
      id: json['id'] as String? ?? '',
      runNumber: json['run_number'] as String?,
      recordDate: json['record_date'] != null
          ? json['record_date'].toString().split('T')[0]
          : DateTime.now().toIso8601String().split('T')[0],
      slurryInputKg: slurry,
      dryFertiliserOutputKg: dry,
      moisturePct: (json['moisture_pct'] as num?)?.toDouble() ?? 0.0,
      stockItemId: json['stock_item_id'] as String?,
      stockItemName: json['stock_item']?['name'] as String?,
      usageType: BiogasUsageType.fromString(json['usage_type'] as String?),
      usageQuantityKg: (json['usage_quantity_kg'] as num?)?.toDouble(),
      saleAmount: (json['sale_amount'] as num?)?.toDouble(),
      buyerOrFarmPlot: json['buyer_or_farm_plot'] as String?,
      bags1kg: b1,
      bags5kg: b5,
      bags25kg: b25,
      bags50kg: b50,
      yieldPct: double.parse(yld.toStringAsFixed(1)),
      totalPackedKg: packed,
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (runNumber != null && runNumber!.isNotEmpty) 'runNumber': runNumber,
      'recordDate': recordDate,
      'slurryInputKg': slurryInputKg,
      'dryFertiliserOutputKg': dryFertiliserOutputKg,
      'moisturePct': moisturePct,
      if (stockItemId != null) 'stockItemId': stockItemId,
      'usageType': usageType.apiValue,
      if (usageQuantityKg != null) 'usageQuantityKg': usageQuantityKg,
      if (saleAmount != null) 'saleAmount': saleAmount,
      if (buyerOrFarmPlot != null) 'buyerOrFarmPlot': buyerOrFarmPlot,
      'bagsPacked1kg': bags1kg,
      'bagsPacked5kg': bags5kg,
      'bagsPacked25kg': bags25kg,
      'bagsPacked50kg': bags50kg,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}

class BiogasSummaryModel {
  final double totalSlurryInputKg;
  final double totalDryFertiliserKg;
  final int totalPackedBags;
  final double overallYieldPct;
  final double internalFarmKg;
  final double directSaleKg;
  final double storeStockKg;

  const BiogasSummaryModel({
    this.totalSlurryInputKg = 0.0,
    this.totalDryFertiliserKg = 0.0,
    this.totalPackedBags = 0,
    this.overallYieldPct = 0.0,
    this.internalFarmKg = 0.0,
    this.directSaleKg = 0.0,
    this.storeStockKg = 0.0,
  });

  factory BiogasSummaryModel.fromJson(Map<String, dynamic> json) {
    final byUsage = json['byUsage'] as Map<String, dynamic>? ?? {};
    return BiogasSummaryModel(
      totalSlurryInputKg: (json['totalSlurryInputKg'] as num?)?.toDouble() ?? 0.0,
      totalDryFertiliserKg: (json['totalDryFertiliserKg'] as num?)?.toDouble() ?? 0.0,
      totalPackedBags: (json['totalPackedBags'] as num?)?.toInt() ?? 0,
      overallYieldPct: (json['overallYieldPct'] as num?)?.toDouble() ?? 0.0,
      internalFarmKg: (byUsage['internalFarmKg'] as num?)?.toDouble() ?? 0.0,
      directSaleKg: (byUsage['directSaleKg'] as num?)?.toDouble() ?? 0.0,
      storeStockKg: (byUsage['storeStockKg'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
