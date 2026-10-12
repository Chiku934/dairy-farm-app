enum LicenceType {
  fssai('FSSAI', 'FSSAI Food Safety'),
  pollutionControl('POLLUTION_CONTROL', 'Pollution Control (PCB)'),
  tradeLicense('TRADE_LICENSE', 'Municipal Trade Licence'),
  fireSafety('FIRE_SAFETY', 'Fire Safety NOC'),
  groundwater('GROUNDWATER', 'Groundwater Extraction'),
  dairyRegistration('DAIRY_REGISTRATION', 'Dairy Registration'),
  other('OTHER', 'General Compliance');

  final String apiValue;
  final String label;
  const LicenceType(this.apiValue, this.label);

  static LicenceType fromString(String? val) {
    return LicenceType.values.firstWhere(
      (e) => e.apiValue == val || e.name == val,
      orElse: () => LicenceType.other,
    );
  }
}

enum LicenceStatus {
  active('ACTIVE', 'Active'),
  expiringSoon('EXPIRING_SOON', 'Expiring Soon'),
  expired('EXPIRED', 'Expired'),
  suspended('SUSPENDED', 'Suspended');

  final String apiValue;
  final String label;
  const LicenceStatus(this.apiValue, this.label);

  static LicenceStatus fromString(String? val) {
    return LicenceStatus.values.firstWhere(
      (e) => e.apiValue == val || e.name == val,
      orElse: () => LicenceStatus.active,
    );
  }
}

enum ReminderStatus {
  pending('PENDING', 'Pending'),
  notified('NOTIFIED', 'Notified'),
  dismissed('DISMISSED', 'Dismissed');

  final String apiValue;
  final String label;
  const ReminderStatus(this.apiValue, this.label);

  static ReminderStatus fromString(String? val) {
    return ReminderStatus.values.firstWhere(
      (e) => e.apiValue == val || e.name == val,
      orElse: () => ReminderStatus.pending,
    );
  }
}

class RegulatoryLicenceModel {
  final String id;
  final String licenceName;
  final LicenceType licenceType;
  final String licenceNumber;
  final String issuingAuthority;
  final String licenceHolder;
  final String issueDate;
  final String expiryDate;
  final int reminderDaysBefore;
  final LicenceStatus status;
  final ReminderStatus reminderStatus;
  final String? reminderSentAt;
  final String? documentUrl;
  final String? notes;

  const RegulatoryLicenceModel({
    required this.id,
    required this.licenceName,
    required this.licenceType,
    required this.licenceNumber,
    required this.issuingAuthority,
    required this.licenceHolder,
    required this.issueDate,
    required this.expiryDate,
    this.reminderDaysBefore = 30,
    this.status = LicenceStatus.active,
    this.reminderStatus = ReminderStatus.pending,
    this.reminderSentAt,
    this.documentUrl,
    this.notes,
  });

  factory RegulatoryLicenceModel.fromJson(Map<String, dynamic> json) {
    return RegulatoryLicenceModel(
      id: json['id'] as String? ?? '',
      licenceName: json['licenceName'] as String? ?? json['licence_name'] as String? ?? '',
      licenceType: LicenceType.fromString(json['licenceType'] as String? ?? json['licence_type'] as String?),
      licenceNumber: json['licenceNumber'] as String? ?? json['licence_number'] as String? ?? '',
      issuingAuthority: json['issuingAuthority'] as String? ?? json['issuing_authority'] as String? ?? '',
      licenceHolder: json['licenceHolder'] as String? ?? json['licence_holder'] as String? ?? '',
      issueDate: json['issueDate'] as String? ?? json['issue_date'] as String? ?? '',
      expiryDate: json['expiryDate'] as String? ?? json['expiry_date'] as String? ?? '',
      reminderDaysBefore: json['reminderDaysBefore'] as int? ?? json['reminder_days_before'] as int? ?? 30,
      status: LicenceStatus.fromString(json['status'] as String?),
      reminderStatus: ReminderStatus.fromString(json['reminderStatus'] as String? ?? json['reminder_status'] as String?),
      reminderSentAt: json['reminderSentAt'] as String? ?? json['reminder_sent_at'] as String?,
      documentUrl: json['documentUrl'] as String? ?? json['document_url'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'licenceName': licenceName,
      'licenceType': licenceType.apiValue,
      'licenceNumber': licenceNumber,
      'issuingAuthority': issuingAuthority,
      'licenceHolder': licenceHolder,
      'issueDate': issueDate,
      'expiryDate': expiryDate,
      'reminderDaysBefore': reminderDaysBefore,
      'status': status.apiValue,
      'reminderStatus': reminderStatus.apiValue,
      if (documentUrl != null) 'documentUrl': documentUrl,
      if (notes != null) 'notes': notes,
    };
  }
}
