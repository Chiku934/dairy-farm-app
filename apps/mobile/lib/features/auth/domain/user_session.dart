import 'dart:convert';

class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final List<String> roles;
  final List<String> permissions;

  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.roles,
    required this.permissions,
  });

  bool hasPermission(String perm) {
    if (isOwner) return true;
    return permissions.contains(perm);
  }

  bool hasRole(String role) => roles.contains(role);

  bool get isOwner => roles.contains('FARM_OWNER') || roles.contains('SUPER_ADMIN');
  bool get isManager => isOwner || roles.contains('FARM_MANAGER');
  bool get isAccountant => isOwner || roles.contains('ACCOUNTANT');
  bool get isAuditor => roles.contains('AUDITOR');
  bool get isStorekeeper => isOwner || isManager || roles.contains('STOREKEEPER');
  bool get isAnimalCare => isOwner || isManager || roles.contains('ANIMAL_CARE');
  bool get isBmcOperator => isOwner || isManager || roles.contains('BMC_OPERATOR');
  bool get isProductionOperator => isOwner || isManager || roles.contains('PRODUCTION_OPERATOR');
  bool get isQcStaff => isOwner || isManager || roles.contains('QC_STAFF');
  bool get isSalesStaff => isOwner || isManager || roles.contains('SALES_STAFF');
  bool get isHrAdmin => isOwner || roles.contains('HR_ADMIN');

  String get primaryRoleDisplayName {
    if (roles.contains('FARM_OWNER')) return 'Farm Owner / Admin';
    if (roles.contains('FARM_MANAGER')) return 'Farm Manager';
    if (roles.contains('ACCOUNTANT')) return 'Accountant / Finance';
    if (roles.contains('AUDITOR')) return 'Read-only Auditor';
    if (roles.contains('STOREKEEPER')) return 'Storekeeper';
    if (roles.contains('ANIMAL_CARE')) return 'Herd / Animal Care';
    if (roles.contains('BMC_OPERATOR')) return 'BMC Operator';
    if (roles.contains('PRODUCTION_OPERATOR')) return 'Production Operator';
    if (roles.contains('QC_STAFF')) return 'QC Staff';
    if (roles.contains('SALES_STAFF')) return 'Sales Staff';
    if (roles.contains('HR_ADMIN')) return 'HR Admin';
    return roles.isNotEmpty ? roles.first : 'Staff';
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      roles: (json['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      permissions:
          (json['permissions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'roles': roles,
      'permissions': permissions,
    };
  }
}

class UserSession {
  final String accessToken;
  final String refreshToken;
  final int expiresInSeconds;
  final UserProfile user;

  const UserSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresInSeconds,
    required this.user,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      expiresInSeconds: json['expiresInSeconds'] as int? ?? 900,
      user: UserProfile.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresInSeconds': expiresInSeconds,
      'user': user.toJson(),
    };
  }

  String serialize() => jsonEncode(toJson());

  static UserSession? deserialize(String rawJson) {
    try {
      final map = jsonDecode(rawJson) as Map<String, dynamic>;
      return UserSession.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}
