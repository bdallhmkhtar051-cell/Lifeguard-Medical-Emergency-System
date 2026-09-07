enum UserRole {
  patient('Patient'),
  doctor('Doctor'),
  administrator('Administrator');

  const UserRole(this.label);

  final String label;

  static UserRole? tryParse(Object? value) {
    if (value is! String) {
      return null;
    }
    final normalized = value.trim().toLowerCase();
    return switch (normalized) {
      'patient' => UserRole.patient,
      'doctor' || 'clinician' => UserRole.doctor,
      'administrator' || 'admin' => UserRole.administrator,
      _ => null,
    };
  }
}

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.roles,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final rawRoles = json['roles'];
    if (rawRoles is! List) {
      throw const FormatException('User roles are missing.');
    }
    final roles = rawRoles.map(UserRole.tryParse).whereType<UserRole>().toSet();
    if (roles.isEmpty) {
      // Unknown roles never inherit a default or a privileged screen.
      throw const FormatException('No supported role was returned.');
    }
    return AppUser(
      id: _requiredString(json, 'id'),
      email: _requiredString(json, 'email'),
      displayName: _requiredString(json, 'displayName'),
      roles: Set<UserRole>.unmodifiable(roles),
    );
  }

  final String id;
  final String email;
  final String displayName;
  final Set<UserRole> roles;

  bool hasRole(UserRole role) => roles.contains(role);

  /// First-slice accounts intentionally have one role. If a future account has
  /// several roles, the UI safely lands on a non-clinical role selector.
  UserRole? get singleRole => roles.length == 1 ? roles.single : null;

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('$key is missing.');
    }
    return value.trim();
  }
}

class LoginResult {
  const LoginResult({
    required this.accessToken,
    required this.tokenType,
    required this.expiresInSeconds,
    required this.user,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    final expires = json['expiresInSeconds'];
    if (expires is! num || expires.toInt() <= 0) {
      throw const FormatException('Token expiry is invalid.');
    }
    final user = json['user'];
    if (user is! Map<String, dynamic>) {
      throw const FormatException('User is missing.');
    }
    return LoginResult(
      accessToken: AppUser._requiredString(json, 'accessToken'),
      tokenType: AppUser._requiredString(json, 'tokenType'),
      expiresInSeconds: expires.toInt(),
      user: AppUser.fromJson(user),
    );
  }

  final String accessToken;
  final String tokenType;
  final int expiresInSeconds;
  final AppUser user;
}
