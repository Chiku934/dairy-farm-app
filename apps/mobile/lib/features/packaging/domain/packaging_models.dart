class PackagingRunModel {
  final String id;
  final String recordDate;
  final String productionBatchId;
  final String? batchNumber;
  final double packSize;
  final String packUnit;
  final int numberOfPacks;
  final double totalPackagedQuantity;
  final String packagingItemId;
  final String? packagingItemName;
  final double materialConsumed;
  final int scrapUnits;
  final String? notes;
  final String? createdBy;
  final DateTime? createdAt;

  PackagingRunModel({
    required this.id,
    required this.recordDate,
    required this.productionBatchId,
    this.batchNumber,
    required this.packSize,
    required this.packUnit,
    required this.numberOfPacks,
    required this.totalPackagedQuantity,
    required this.packagingItemId,
    this.packagingItemName,
    required this.materialConsumed,
    required this.scrapUnits,
    this.notes,
    this.createdBy,
    this.createdAt,
  });

  factory PackagingRunModel.fromJson(Map<String, dynamic> json) {
    return PackagingRunModel(
      id: json['id'] as String? ?? '',
      recordDate: json['record_date'] as String? ?? json['recordDate'] as String? ?? '',
      productionBatchId: json['production_batch_id'] as String? ?? json['productionBatchId'] as String? ?? '',
      batchNumber: json['production_batch'] != null
          ? (json['production_batch']['batch_number'] ?? json['production_batch']['batchNumber']) as String?
          : json['batchNumber'] as String?,
      packSize: (json['pack_size'] ?? json['packSize'] ?? 0.0) is num
          ? (json['pack_size'] ?? json['packSize'] as num).toDouble()
          : 0.0,
      packUnit: json['pack_unit'] as String? ?? json['packUnit'] as String? ?? 'LITRE',
      numberOfPacks: (json['number_of_packs'] ?? json['numberOfPacks'] ?? 0) is num
          ? (json['number_of_packs'] ?? json['numberOfPacks'] as num).toInt()
          : 0,
      totalPackagedQuantity: (json['total_packaged_quantity'] ?? json['totalPackagedQuantity'] ?? 0.0) is num
          ? (json['total_packaged_quantity'] ?? json['totalPackagedQuantity'] as num).toDouble()
          : 0.0,
      packagingItemId: json['packaging_item_id'] as String? ?? json['packagingItemId'] as String? ?? '',
      packagingItemName: json['packaging_item'] != null
          ? json['packaging_item']['name'] as String?
          : json['packagingItemName'] as String?,
      materialConsumed: (json['material_consumed'] ?? json['materialConsumed'] ?? 0.0) is num
          ? (json['material_consumed'] ?? json['materialConsumed'] as num).toDouble()
          : 0.0,
      scrapUnits: (json['scrap_units'] ?? json['scrapUnits'] ?? 0) is num
          ? (json['scrap_units'] ?? json['scrapUnits'] as num).toInt()
          : 0,
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String? ?? json['createdBy'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }
}
