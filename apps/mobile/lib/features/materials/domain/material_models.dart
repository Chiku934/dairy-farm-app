enum IssueDepartment {
  farm('FARM', 'Farm / Herd Care'),
  production('PRODUCTION', 'Dairy Processing'),
  biogas('BIOGAS', 'Biogas Plant');

  final String value;
  final String label;
  const IssueDepartment(this.value, this.label);

  static IssueDepartment fromString(String val) {
    return IssueDepartment.values.firstWhere(
      (e) => e.value.toUpperCase() == val.toUpperCase(),
      orElse: () => IssueDepartment.production,
    );
  }
}

class MaterialIssueModel {
  final String id;
  final String recordDate;
  final IssueDepartment department;
  final String stockItemId;
  final String? stockItemName;
  final String? stockItemUnit;
  final double quantity;
  final double? unitCost;
  final double? totalCost;
  final String? productionBatchId;
  final String? batchNumber;
  final String? issuedTo;
  final String? notes;
  final String? createdBy;
  final DateTime? createdAt;

  MaterialIssueModel({
    required this.id,
    required this.recordDate,
    required this.department,
    required this.stockItemId,
    this.stockItemName,
    this.stockItemUnit,
    required this.quantity,
    this.unitCost,
    this.totalCost,
    this.productionBatchId,
    this.batchNumber,
    this.issuedTo,
    this.notes,
    this.createdBy,
    this.createdAt,
  });

  factory MaterialIssueModel.fromJson(Map<String, dynamic> json) {
    return MaterialIssueModel(
      id: json['id'] as String? ?? '',
      recordDate: json['record_date'] as String? ?? json['recordDate'] as String? ?? '',
      department: IssueDepartment.fromString(
        json['department'] as String? ?? 'PRODUCTION',
      ),
      stockItemId: json['stock_item_id'] as String? ?? json['stockItemId'] as String? ?? '',
      stockItemName: json['stock_item'] != null ? json['stock_item']['name'] as String? : null,
      stockItemUnit: json['stock_item'] != null ? json['stock_item']['unit'] as String? : null,
      quantity: (json['quantity'] ?? 0.0) is num ? (json['quantity'] as num).toDouble() : 0.0,
      unitCost: (json['unit_cost'] ?? json['unitCost']) is num
          ? (json['unit_cost'] ?? json['unitCost'] as num).toDouble()
          : null,
      totalCost: (json['total_cost'] ?? json['totalCost']) is num
          ? (json['total_cost'] ?? json['totalCost'] as num).toDouble()
          : null,
      productionBatchId: json['production_batch_id'] as String? ?? json['productionBatchId'] as String?,
      batchNumber: json['production_batch'] != null
          ? (json['production_batch']['batch_number'] ?? json['production_batch']['batchNumber']) as String?
          : null,
      issuedTo: json['issued_to'] as String? ?? json['issuedTo'] as String?,
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String? ?? json['createdBy'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }
}
