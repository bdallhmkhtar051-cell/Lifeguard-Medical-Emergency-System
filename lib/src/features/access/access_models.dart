import '../patient_profile/emergency_profile.dart';

class DoctorProfessionalProfile {
  const DoctorProfessionalProfile({
    required this.displayName,
    required this.email,
    this.professionalTitle = '',
    this.hospitalName = '',
    this.department = '',
    this.licenseNumber = '',
    this.phoneNumber = '',
    this.licenseVerified = false,
  });
  factory DoctorProfessionalProfile.fromJson(Map<String, dynamic> json) =>
      DoctorProfessionalProfile(
        displayName: json['displayName'].toString(),
        email: json['email'].toString(),
        professionalTitle: json['professionalTitle']?.toString() ?? '',
        hospitalName: json['hospitalName']?.toString() ?? '',
        department: json['department']?.toString() ?? '',
        licenseNumber: json['licenseNumber']?.toString() ?? '',
        phoneNumber: json['phoneNumber']?.toString() ?? '',
        licenseVerified: json['licenseVerified'] == true,
      );
  final String displayName,
      email,
      professionalTitle,
      hospitalName,
      department,
      licenseNumber,
      phoneNumber;
  final bool licenseVerified;
}

enum EmergencyAccessKind {
  consented,
  qrConsented,
  breakGlass;

  static EmergencyAccessKind fromJson(Object? value) => switch (value) {
    'Consented' => EmergencyAccessKind.consented,
    'QrConsented' => EmergencyAccessKind.qrConsented,
    'BreakGlass' => EmergencyAccessKind.breakGlass,
    _ => throw const FormatException('Unknown emergency access type.'),
  };
}

/// Raw QR tokens are short-lived and kept only in memory while displayed.
class MedicalQrAccess {
  const MedicalQrAccess({required this.token, required this.expiresAt});

  factory MedicalQrAccess.fromJson(Map<String, dynamic> json) =>
      MedicalQrAccess(
        token: json['token'].toString(),
        expiresAt: DateTime.parse(json['expiresAtUtc'].toString()),
      );

  final String token;
  final DateTime expiresAt;
}

class DoctorPatient {
  const DoctorPatient({required this.id, required this.name});
  factory DoctorPatient.fromJson(Map<String, dynamic> json) => DoctorPatient(
    id: json['patientProfileId'].toString(),
    name: json['patientName'].toString(),
  );
  final String id;
  final String name;
}

class DoctorOption {
  const DoctorOption({
    required this.id,
    required this.name,
    required this.email,
  });
  factory DoctorOption.fromJson(Map<String, dynamic> json) => DoctorOption(
    id: json['userId'].toString(),
    name: json['displayName'].toString(),
    email: json['email'].toString(),
  );
  final String id;
  final String name;
  final String email;
}

class AccessGrant {
  const AccessGrant({
    required this.id,
    required this.doctorName,
    required this.doctorEmail,
    required this.expiresAt,
    required this.active,
    required this.accessType,
    this.emergencyReason,
  });
  factory AccessGrant.fromJson(Map<String, dynamic> json) => AccessGrant(
    id: json['id'].toString(),
    doctorName: json['doctorName'].toString(),
    doctorEmail: json['doctorEmail'].toString(),
    expiresAt: DateTime.parse(json['expiresAtUtc'].toString()),
    active: json['isActive'] == true,
    accessType: EmergencyAccessKind.fromJson(json['accessType']),
    emergencyReason: _optional(json['emergencyReason']),
  );
  final String id;
  final String doctorName;
  final String doctorEmail;
  final DateTime expiresAt;
  final bool active;
  final EmergencyAccessKind accessType;
  final String? emergencyReason;
}

class AccessAudit {
  const AccessAudit({
    required this.actor,
    required this.action,
    required this.time,
  });
  factory AccessAudit.fromJson(Map<String, dynamic> json) => AccessAudit(
    actor: json['actorName'].toString(),
    action: json['action'].toString(),
    time: DateTime.parse(json['occurredAtUtc'].toString()),
  );
  final String actor;
  final String action;
  final DateTime time;
}

class PatientAccessDashboard {
  const PatientAccessDashboard({
    required this.doctors,
    required this.grants,
    required this.audit,
  });
  factory PatientAccessDashboard.fromJson(Map<String, dynamic> json) =>
      PatientAccessDashboard(
        doctors: _list(json['doctors'], DoctorOption.fromJson),
        grants: _list(json['grants'], AccessGrant.fromJson),
        audit: _list(json['auditHistory'], AccessAudit.fromJson),
      );
  final List<DoctorOption> doctors;
  final List<AccessGrant> grants;
  final List<AccessAudit> audit;
}

class DoctorAccess {
  const DoctorAccess({
    required this.id,
    required this.patientProfileId,
    required this.patientName,
    required this.expiresAt,
    required this.accessType,
    this.emergencyReason,
  });
  factory DoctorAccess.fromJson(Map<String, dynamic> json) => DoctorAccess(
    id: json['grantId'].toString(),
    patientProfileId: json['patientProfileId'].toString(),
    patientName: json['patientName'].toString(),
    expiresAt: DateTime.parse(json['expiresAtUtc'].toString()),
    accessType: EmergencyAccessKind.fromJson(json['accessType']),
    emergencyReason: _optional(json['emergencyReason']),
  );
  final String id;
  final String patientProfileId;
  final String patientName;
  final DateTime expiresAt;
  final EmergencyAccessKind accessType;
  final String? emergencyReason;
}

class DoctorSnapshot {
  const DoctorSnapshot({
    required this.expiresAt,
    required this.profile,
    required this.accessType,
    this.emergencyReason,
  });
  factory DoctorSnapshot.fromJson(Map<String, dynamic> json) => DoctorSnapshot(
    expiresAt: DateTime.parse(json['expiresAtUtc'].toString()),
    profile: EmergencyProfile.fromJson(json['profile'] as Map<String, dynamic>),
    accessType: EmergencyAccessKind.fromJson(json['accessType']),
    emergencyReason: _optional(json['emergencyReason']),
  );
  final DateTime expiresAt;
  final EmergencyProfile profile;
  final EmergencyAccessKind accessType;
  final String? emergencyReason;
}

/// A temporary, clinician-facing summary generated from the authorized record.
class AiMedicalSummary {
  const AiMedicalSummary({
    required this.summary,
    required this.generatedAt,
    required this.model,
    required this.disclaimer,
  });

  factory AiMedicalSummary.fromJson(Map<String, dynamic> json) =>
      AiMedicalSummary(
        summary: json['summary'].toString(),
        generatedAt: DateTime.parse(json['generatedAtUtc'].toString()),
        model: json['model'].toString(),
        disclaimer: json['disclaimer'].toString(),
      );

  final String summary;
  final DateTime generatedAt;
  final String model;
  final String disclaimer;
}

List<T> _list<T>(Object? value, T Function(Map<String, dynamic>) parse) =>
    (value as List<dynamic>).cast<Map<String, dynamic>>().map(parse).toList();

String? _optional(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}
