enum CostCentre {
  farm('FARM', 'Dairy Farm Operations'),
  production('PRODUCTION', 'Processing & Packaging Plant'),
  biogas('BIOGAS', 'Biogas & Fertiliser Unit');

  final String apiValue;
  final String label;
  const CostCentre(this.apiValue, this.label);

  static CostCentre fromString(String? val) {
    return CostCentre.values.firstWhere(
      (e) => e.apiValue == val || e.name == val,
      orElse: () => CostCentre.farm,
    );
  }
}

enum ExpenseCategory {
  feed('FEED', 'Cattle Feed & Fodder'),
  vet('VET', 'Veterinary & Medicines'),
  maintenance('MAINTENANCE', 'Repairs & Maintenance'),
  utilities('UTILITIES', 'Electricity & Water Utilities'),
  labor('LABOR', 'Farm Labor & Wages'),
  cleaning('CLEANING', 'Chemicals & Sanitation'),
  packaging('PACKAGING', 'Packaging Supplies'),
  transport('TRANSPORT', 'Fuel & Logistics'),
  admin('ADMIN', 'Office & Compliance'),
  other('OTHER', 'General Overhead');

  final String apiValue;
  final String label;
  const ExpenseCategory(this.apiValue, this.label);

  static ExpenseCategory fromString(String? val) {
    return ExpenseCategory.values.firstWhere(
      (e) => e.apiValue == val || e.name == val,
      orElse: () => ExpenseCategory.other,
    );
  }
}

enum PaymentMethod {
  cash('CASH', 'Cash'),
  bankTransfer('BANK_TRANSFER', 'Bank Transfer / NEFT'),
  upi('UPI', 'UPI / QR'),
  cheque('CHEQUE', 'Cheque');

  final String apiValue;
  final String label;
  const PaymentMethod(this.apiValue, this.label);

  static PaymentMethod fromString(String? val) {
    return PaymentMethod.values.firstWhere(
      (e) => e.apiValue == val || e.name == val,
      orElse: () => PaymentMethod.cash,
    );
  }
}

class OperatingExpenseModel {
  final String id;
  final String? expenseNumber;
  final String recordDate;
  final CostCentre costCentre;
  final ExpenseCategory category;
  final double amount;
  final String? productionBatchId;
  final String? batchNumber;
  final String? payee;
  final String? invoiceNumber;
  final PaymentMethod paymentMethod;
  final String? notes;
  final String? createdBy;
  final String? createdAt;

  OperatingExpenseModel({
    required this.id,
    this.expenseNumber,
    required this.recordDate,
    required this.costCentre,
    required this.category,
    required this.amount,
    this.productionBatchId,
    this.batchNumber,
    this.payee,
    this.invoiceNumber,
    this.paymentMethod = PaymentMethod.cash,
    this.notes,
    this.createdBy,
    this.createdAt,
  });

  factory OperatingExpenseModel.fromJson(Map<String, dynamic> json) {
    return OperatingExpenseModel(
      id: json['id'] as String? ?? '',
      expenseNumber: json['expense_number'] as String?,
      recordDate: json['record_date'] != null
          ? json['record_date'].toString().split('T')[0]
          : DateTime.now().toIso8601String().split('T')[0],
      costCentre: CostCentre.fromString(json['cost_centre'] as String?),
      category: ExpenseCategory.fromString(json['category'] as String?),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      productionBatchId: json['production_batch_id'] as String?,
      batchNumber: json['production_batch']?['batch_number'] as String?,
      payee: json['payee'] as String?,
      invoiceNumber: json['invoice_number'] as String?,
      paymentMethod: PaymentMethod.fromString(json['payment_method'] as String?),
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (expenseNumber != null && expenseNumber!.isNotEmpty) 'expenseNumber': expenseNumber,
      'recordDate': recordDate,
      'costCentre': costCentre.apiValue,
      'category': category.apiValue,
      'amount': amount,
      if (productionBatchId != null) 'productionBatchId': productionBatchId,
      if (payee != null && payee!.isNotEmpty) 'payee': payee,
      if (invoiceNumber != null && invoiceNumber!.isNotEmpty) 'invoiceNumber': invoiceNumber,
      'paymentMethod': paymentMethod.apiValue,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}

class ExpenseSummaryModel {
  final double totalExpenses;
  final double farmExpenses;
  final double productionExpenses;
  final double biogasExpenses;

  const ExpenseSummaryModel({
    this.totalExpenses = 0.0,
    this.farmExpenses = 0.0,
    this.productionExpenses = 0.0,
    this.biogasExpenses = 0.0,
  });

  factory ExpenseSummaryModel.fromJson(Map<String, dynamic> json) {
    final byCentre = json['byCostCentre'] as Map<String, dynamic>? ?? {};
    return ExpenseSummaryModel(
      totalExpenses: (json['totalExpenses'] as num?)?.toDouble() ?? 0.0,
      farmExpenses: (byCentre['farm'] as num?)?.toDouble() ?? 0.0,
      productionExpenses: (byCentre['production'] as num?)?.toDouble() ?? 0.0,
      biogasExpenses: (byCentre['biogas'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
