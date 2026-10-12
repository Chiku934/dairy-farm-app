enum Department {
  farm('FARM', 'Dairy Farm Operations'),
  production('PRODUCTION', 'Dairy Processing & Plant'),
  biogas('BIOGAS', 'Biogas & Bio-Fertiliser'),
  management('MANAGEMENT', 'General Management & Admin');

  final String apiValue;
  final String label;
  const Department(this.apiValue, this.label);

  static Department fromString(String? val) {
    return Department.values.firstWhere(
      (e) => e.apiValue == val || e.name == val,
      orElse: () => Department.farm,
    );
  }
}

enum EmploymentStatus {
  active('ACTIVE', 'Active'),
  onLeave('ON_LEAVE', 'On Leave'),
  terminated('TERMINATED', 'Terminated'),
  resigned('RESIGNED', 'Resigned');

  final String apiValue;
  final String label;
  const EmploymentStatus(this.apiValue, this.label);

  static EmploymentStatus fromString(String? val) {
    return EmploymentStatus.values.firstWhere(
      (e) => e.apiValue == val || e.name == val,
      orElse: () => EmploymentStatus.active,
    );
  }
}

class EmployeeModel {
  final String id;
  final String employeeCode;
  final String fullName;
  final Department department;
  final String jobTitle;
  final String joiningDate;
  final String? leavingDate;
  final double? monthlySalary;
  final double? dailySalaryRate;
  final bool isActive;
  final EmploymentStatus status;
  final String? phone;
  final String? email;
  final String? notes;

  const EmployeeModel({
    required this.id,
    required this.employeeCode,
    required this.fullName,
    required this.department,
    required this.jobTitle,
    required this.joiningDate,
    this.leavingDate,
    this.monthlySalary,
    this.dailySalaryRate,
    this.isActive = true,
    this.status = EmploymentStatus.active,
    this.phone,
    this.email,
    this.notes,
  });

  bool get hasSalaryClearance => monthlySalary != null;

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'] as String? ?? '',
      employeeCode: json['employeeCode'] as String? ?? json['employee_code'] as String? ?? '',
      fullName: json['fullName'] as String? ?? json['full_name'] as String? ?? '',
      department: Department.fromString(json['department'] as String?),
      jobTitle: json['jobTitle'] as String? ?? json['job_title'] as String? ?? '',
      joiningDate: json['joiningDate'] as String? ?? json['joining_date'] as String? ?? '',
      leavingDate: json['leavingDate'] as String? ?? json['leaving_date'] as String?,
      monthlySalary: json['monthlySalary'] != null
          ? double.tryParse(json['monthlySalary'].toString())
          : (json['monthly_salary'] != null
              ? double.tryParse(json['monthly_salary'].toString())
              : null),
      dailySalaryRate: json['dailySalaryRate'] != null
          ? double.tryParse(json['dailySalaryRate'].toString())
          : (json['daily_salary_rate'] != null
              ? double.tryParse(json['daily_salary_rate'].toString())
              : null),
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
      status: EmploymentStatus.fromString(json['status'] as String?),
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeCode': employeeCode,
      'fullName': fullName,
      'department': department.apiValue,
      'jobTitle': jobTitle,
      'joiningDate': joiningDate,
      if (leavingDate != null) 'leavingDate': leavingDate,
      if (monthlySalary != null) 'monthlySalary': monthlySalary,
      'isActive': isActive,
      'status': status.apiValue,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (notes != null) 'notes': notes,
    };
  }
}
