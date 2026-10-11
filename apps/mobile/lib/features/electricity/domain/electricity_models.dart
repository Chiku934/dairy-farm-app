enum ElectricityDepartment {
  farm('FARM', 'Farm Meter'),
  production('PRODUCTION', 'Production Hall Meter'),
  biogas('BIOGAS', 'Biogas Plant Meter');

  final String value;
  final String label;
  const ElectricityDepartment(this.value, this.label);

  static ElectricityDepartment fromString(String val) {
    return ElectricityDepartment.values.firstWhere(
      (e) => e.value.toUpperCase() == val.toUpperCase(),
      orElse: () => ElectricityDepartment.farm,
    );
  }
}

class ElectricityReadingModel {
  final String id;
  final String recordDate;
  final ElectricityDepartment department;
  final double? openingReadingKwh;
  final double? closingReadingKwh;
  final double unitsKwh;
  final double tariffRate;
  final double totalCost;
  final String? notes;
  final String? createdBy;
  final DateTime? createdAt;

  ElectricityReadingModel({
    required this.id,
    required this.recordDate,
    required this.department,
    this.openingReadingKwh,
    this.closingReadingKwh,
    required this.unitsKwh,
    required this.tariffRate,
    required this.totalCost,
    this.notes,
    this.createdBy,
    this.createdAt,
  });

  factory ElectricityReadingModel.fromJson(Map<String, dynamic> json) {
    return ElectricityReadingModel(
      id: json['id'] as String? ?? '',
      recordDate: json['record_date'] as String? ?? json['recordDate'] as String? ?? '',
      department: ElectricityDepartment.fromString(
        json['department'] as String? ?? 'FARM',
      ),
      openingReadingKwh: (json['opening_reading_kwh'] ?? json['openingReadingKwh']) is num
          ? (json['opening_reading_kwh'] ?? json['openingReadingKwh'] as num).toDouble()
          : null,
      closingReadingKwh: (json['closing_reading_kwh'] ?? json['closingReadingKwh']) is num
          ? (json['closing_reading_kwh'] ?? json['closingReadingKwh'] as num).toDouble()
          : null,
      unitsKwh: (json['units_kwh'] ?? json['unitsKwh'] ?? 0.0) is num
          ? (json['units_kwh'] ?? json['unitsKwh'] as num).toDouble()
          : 0.0,
      tariffRate: (json['tariff_rate'] ?? json['tariffRate'] ?? 1.40) is num
          ? (json['tariff_rate'] ?? json['tariffRate'] as num).toDouble()
          : 1.40,
      totalCost: (json['total_cost'] ?? json['totalCost'] ?? 0.0) is num
          ? (json['total_cost'] ?? json['totalCost'] as num).toDouble()
          : 0.0,
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String? ?? json['createdBy'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }
}
