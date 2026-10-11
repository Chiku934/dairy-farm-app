enum StockCategory {
  feed('FEED', 'Feed & Concentrate'),
  medicine('MEDICINE', 'Veterinary Medicine'),
  packaging('PACKAGING', 'Packaging Material'),
  lpg('LPG', 'LPG Fuel'),
  cleaning('CLEANING', 'CIP & Cleaning'),
  processingIngredient('PROCESSING_INGREDIENT', 'Processing Ingredient'),
  consumable('CONSUMABLE', 'Consumable'),
  sparePart('SPARE_PART', 'Spare Part'),
  other('OTHER', 'Other');

  final String apiValue;
  final String label;
  const StockCategory(this.apiValue, this.label);

  static StockCategory fromString(String val) {
    return StockCategory.values.firstWhere(
      (e) => e.apiValue == val || e.name.toUpperCase() == val.toUpperCase(),
      orElse: () => StockCategory.other,
    );
  }
}

enum SupplierCategory {
  feed('FEED', 'Feed Supplier'),
  medicine('MEDICINE', 'Veterinary Supplier'),
  packaging('PACKAGING', 'Packaging Supplier'),
  lpg('LPG', 'Fuel / LPG'),
  cleaning('CLEANING', 'Cleaning Chemicals'),
  processingIngredient('PROCESSING_INGREDIENT', 'Dairy Ingredients'),
  equipment('EQUIPMENT', 'Farm Machinery'),
  general('GENERAL', 'General Vendor');

  final String apiValue;
  final String label;
  const SupplierCategory(this.apiValue, this.label);

  static SupplierCategory fromString(String val) {
    return SupplierCategory.values.firstWhere(
      (e) => e.apiValue == val || e.name.toUpperCase() == val.toUpperCase(),
      orElse: () => SupplierCategory.general,
    );
  }
}

class StockItemModel {
  final String id;
  final String name;
  final String usedBy;
  final StockCategory category;
  final String unit;
  final double currentStock;
  final double weightedAvgPrice;
  final double reorderLevel;
  final bool isLowStock;
  final String? notes;

  StockItemModel({
    required this.id,
    required this.name,
    required this.usedBy,
    required this.category,
    required this.unit,
    required this.currentStock,
    required this.weightedAvgPrice,
    required this.reorderLevel,
    required this.isLowStock,
    this.notes,
  });

  factory StockItemModel.fromJson(Map<String, dynamic> json) {
    final currentStock = (json['current_stock'] as num?)?.toDouble() ?? 0.0;
    final reorderLevel = (json['reorder_level'] as num?)?.toDouble() ?? 0.0;
    final isLowStock = json['isLowStock'] as bool? ?? (currentStock <= reorderLevel);

    return StockItemModel(
      id: json['id'] as String,
      name: json['name'] as String,
      usedBy: json['used_by'] as String? ?? 'BOTH',
      category: StockCategory.fromString(json['category'] as String? ?? 'OTHER'),
      unit: json['unit'] as String? ?? 'units',
      currentStock: currentStock,
      weightedAvgPrice: (json['weighted_avg_price'] as num?)?.toDouble() ?? 0.0,
      reorderLevel: reorderLevel,
      isLowStock: isLowStock,
      notes: json['notes'] as String?,
    );
  }
}

class SupplierModel {
  final String id;
  final String name;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? address;
  final SupplierCategory category;
  final bool isActive;

  SupplierModel({
    required this.id,
    required this.name,
    this.contactPerson,
    this.phone,
    this.email,
    this.address,
    required this.category,
    required this.isActive,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id'] as String,
      name: json['name'] as String,
      contactPerson: json['contactPerson'] as String? ?? json['contact_person'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      category: SupplierCategory.fromString(json['category'] as String? ?? 'GENERAL'),
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
    );
  }
}

class StockReceiptModel {
  final String id;
  final String receiptNumber;
  final String recordDate;
  final String stockItemId;
  final String? stockItemName;
  final String? supplierId;
  final String? supplierName;
  final String? supplierLot;
  final double quantity;
  final double unitPrice;
  final double totalCost;
  final String? expiryDate;
  final String? notes;

  StockReceiptModel({
    required this.id,
    required this.receiptNumber,
    required this.recordDate,
    required this.stockItemId,
    this.stockItemName,
    this.supplierId,
    this.supplierName,
    this.supplierLot,
    required this.quantity,
    required this.unitPrice,
    required this.totalCost,
    this.expiryDate,
    this.notes,
  });

  factory StockReceiptModel.fromJson(Map<String, dynamic> json) {
    return StockReceiptModel(
      id: json['id'] as String,
      receiptNumber: json['receiptNumber'] as String? ?? json['receipt_number'] as String? ?? '',
      recordDate: (json['recordDate'] as String? ?? json['record_date'] as String? ?? '').split('T')[0],
      stockItemId: json['stockItemId'] as String? ?? json['stock_item_id'] as String? ?? '',
      stockItemName: json['stockItemName'] as String?,
      supplierId: json['supplierId'] as String? ?? json['supplier_id'] as String?,
      supplierName: json['supplierName'] as String? ?? json['supplier_name'] as String?,
      supplierLot: json['supplierLot'] as String? ?? json['supplier_lot'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (json['unitPrice'] as num? ?? json['unit_price'] as num?)?.toDouble() ?? 0.0,
      totalCost: (json['totalCost'] as num? ?? json['total_cost'] as num?)?.toDouble() ?? 0.0,
      expiryDate: json['expiryDate'] as String? ?? json['expiry_date'] as String?,
      notes: json['notes'] as String?,
    );
  }
}
