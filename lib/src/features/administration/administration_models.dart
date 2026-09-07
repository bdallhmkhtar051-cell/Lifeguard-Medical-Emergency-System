class AdminUser {
  const AdminUser({
    required this.id,
    required this.displayName,
    required this.email,
    required this.roles,
    required this.isActive,
    required this.createdAtUtc,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    final rawRoles = json['roles'];
    if (rawRoles is! List) throw const FormatException('Roles are missing.');
    return AdminUser(
      id: _requiredString(json, 'id'),
      displayName: _requiredString(json, 'displayName'),
      email: _requiredString(json, 'email'),
      roles: rawRoles.map((role) => role.toString()).toList(growable: false),
      isActive: json['isActive'] as bool? ?? false,
      createdAtUtc: DateTime.parse(_requiredString(json, 'createdAtUtc')),
    );
  }

  final String id;
  final String displayName;
  final String email;
  final List<String> roles;
  final bool isActive;
  final DateTime createdAtUtc;

  String get roleLabel => roles.join(', ');
}

class AccountAdministrationAudit {
  const AccountAdministrationAudit({
    required this.id,
    required this.administratorName,
    required this.targetUserName,
    required this.action,
    required this.occurredAtUtc,
  });

  factory AccountAdministrationAudit.fromJson(Map<String, dynamic> json) =>
      AccountAdministrationAudit(
        id: _requiredString(json, 'id'),
        administratorName: _requiredString(json, 'administratorName'),
        targetUserName: _requiredString(json, 'targetUserName'),
        action: _requiredString(json, 'action'),
        occurredAtUtc: DateTime.parse(_requiredString(json, 'occurredAtUtc')),
      );

  final String id;
  final String administratorName;
  final String targetUserName;
  final String action;
  final DateTime occurredAtUtc;
}

class SystemAccessAudit {
  const SystemAccessAudit({
    required this.id,
    required this.actorName,
    required this.patientName,
    required this.action,
    required this.accessType,
    required this.occurredAtUtc,
  });

  factory SystemAccessAudit.fromJson(Map<String, dynamic> json) =>
      SystemAccessAudit(
        id: _requiredString(json, 'id'),
        actorName: _requiredString(json, 'actorName'),
        patientName: _requiredString(json, 'patientName'),
        action: _requiredString(json, 'action'),
        accessType: _requiredString(json, 'accessType'),
        occurredAtUtc: DateTime.parse(_requiredString(json, 'occurredAtUtc')),
      );

  final String id;
  final String actorName;
  final String patientName;
  final String action;
  final String accessType;
  final DateTime occurredAtUtc;
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key is missing.');
  }
  return value.trim();
}
