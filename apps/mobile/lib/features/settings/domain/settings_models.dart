class FarmSettingsModel {
  final String farmName;
  final String address;
  final String district;
  final String state;
  final String pincode;
  final String contactPhone;
  final String contactEmail;
  final String currencyCode;
  final String currencySymbol;
  final double bmcCapacityLitres;
  final double feedBaseKg;
  final double feedRatePerLitre;
  final double feedMaxCapKg;
  final double electricityTariff;
  final double farmDefaultKwh;
  final double productionDefaultKwh;
  final double mgmtSalaryToFarmPct;
  final String operatorName;
  final String timezone;

  const FarmSettingsModel({
    this.farmName = 'Kaivalya Dairy',
    this.address = 'Dandiri',
    this.district = 'Koraput',
    this.state = 'Odisha',
    this.pincode = '764036',
    this.contactPhone = '+91 9876543210',
    this.contactEmail = 'contact@kaivalyadairy.com',
    this.currencyCode = 'INR',
    this.currencySymbol = '₹',
    this.bmcCapacityLitres = 2000.0,
    this.feedBaseKg = 1.0,
    this.feedRatePerLitre = 0.4,
    this.feedMaxCapKg = 8.0,
    this.electricityTariff = 1.4,
    this.farmDefaultKwh = 50.0,
    this.productionDefaultKwh = 200.0,
    this.mgmtSalaryToFarmPct = 50.0,
    this.operatorName = 'Kaivalya team',
    this.timezone = 'Asia/Kolkata',
  });

  factory FarmSettingsModel.fromJson(Map<String, dynamic> json) {
    return FarmSettingsModel(
      farmName: json['farmName'] as String? ?? json['farm_name'] as String? ?? 'Kaivalya Dairy',
      address: json['address'] as String? ?? 'Dandiri',
      district: json['district'] as String? ?? 'Koraput',
      state: json['state'] as String? ?? 'Odisha',
      pincode: json['pincode'] as String? ?? '764036',
      contactPhone: json['contactPhone'] as String? ?? json['contact_phone'] as String? ?? '+91 9876543210',
      contactEmail: json['contactEmail'] as String? ?? json['contact_email'] as String? ?? 'contact@kaivalyadairy.com',
      currencyCode: json['currencyCode'] as String? ?? json['currency_code'] as String? ?? 'INR',
      currencySymbol: json['currencySymbol'] as String? ?? json['currency_symbol'] as String? ?? '₹',
      bmcCapacityLitres: double.tryParse(json['bmcCapacityLitres']?.toString() ?? json['bmc_capacity_litres']?.toString() ?? '2000') ?? 2000.0,
      feedBaseKg: double.tryParse(json['feedBaseKg']?.toString() ?? json['feed_base_kg']?.toString() ?? '1.0') ?? 1.0,
      feedRatePerLitre: double.tryParse(json['feedRatePerLitre']?.toString() ?? json['feed_rate_per_litre']?.toString() ?? '0.4') ?? 0.4,
      feedMaxCapKg: double.tryParse(json['feedMaxCapKg']?.toString() ?? json['feed_max_cap_kg']?.toString() ?? '8.0') ?? 8.0,
      electricityTariff: double.tryParse(json['electricityTariff']?.toString() ?? json['electricity_tariff']?.toString() ?? '1.4') ?? 1.4,
      farmDefaultKwh: double.tryParse(json['farmDefaultKwh']?.toString() ?? json['farm_default_kwh']?.toString() ?? '50.0') ?? 50.0,
      productionDefaultKwh: double.tryParse(json['productionDefaultKwh']?.toString() ?? json['production_default_kwh']?.toString() ?? '200.0') ?? 200.0,
      mgmtSalaryToFarmPct: double.tryParse(json['mgmtSalaryToFarmPct']?.toString() ?? json['mgmt_salary_to_farm_pct']?.toString() ?? '50.0') ?? 50.0,
      operatorName: json['operatorName'] as String? ?? json['operator_name'] as String? ?? 'Kaivalya team',
      timezone: json['timezone'] as String? ?? 'Asia/Kolkata',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'farmName': farmName,
      'address': address,
      'district': district,
      'state': state,
      'pincode': pincode,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'currencyCode': currencyCode,
      'currencySymbol': currencySymbol,
      'bmcCapacityLitres': bmcCapacityLitres,
      'feedBaseKg': feedBaseKg,
      'feedRatePerLitre': feedRatePerLitre,
      'feedMaxCapKg': feedMaxCapKg,
      'electricityTariff': electricityTariff,
      'farmDefaultKwh': farmDefaultKwh,
      'productionDefaultKwh': productionDefaultKwh,
      'mgmtSalaryToFarmPct': mgmtSalaryToFarmPct,
      'operatorName': operatorName,
      'timezone': timezone,
    };
  }
}
