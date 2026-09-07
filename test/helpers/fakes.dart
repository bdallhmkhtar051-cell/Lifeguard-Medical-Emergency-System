import 'package:emergency_system/src/core/network/api_exception.dart';
import 'package:emergency_system/src/features/auth/auth_models.dart';
import 'package:emergency_system/src/features/auth/auth_repository.dart';
import 'package:emergency_system/src/features/access/access_models.dart';
import 'package:emergency_system/src/features/access/access_repository.dart';
import 'package:emergency_system/src/features/health/health_repository.dart';
import 'package:emergency_system/src/features/clinical/clinical_models.dart';
import 'package:emergency_system/src/features/clinical/clinical_repository.dart';
import 'package:emergency_system/src/features/patient_profile/emergency_profile.dart';
import 'package:emergency_system/src/features/patient_profile/patient_profile_repository.dart';

const samplePatient = AppUser(
  id: 'patient-user-id',
  email: 'patient@example.test',
  displayName: 'Amina Yusuf',
  roles: <UserRole>{UserRole.patient},
);

const sampleDoctor = AppUser(
  id: 'doctor-user-id',
  email: 'doctor@example.test',
  displayName: 'Dr. Ali Hassan',
  roles: <UserRole>{UserRole.doctor},
);

const sampleAdministrator = AppUser(
  id: 'admin-user-id',
  email: 'admin@example.test',
  displayName: 'System Administrator',
  roles: <UserRole>{UserRole.administrator},
);

final sampleProfile = EmergencyProfile(
  id: 'profile-id',
  fullName: 'Amina Yusuf',
  dateOfBirth: DateTime.utc(1997, 4, 12),
  bloodGroup: 'OPositive',
  allergies: const <Allergy>[
    Allergy(
      id: 'allergy-id',
      name: 'Penicillin',
      severity: 'Severe',
      reaction: 'Anaphylaxis',
    ),
  ],
  medicalConditions: const <MedicalCondition>[
    MedicalCondition(id: 'condition-id', name: 'Asthma', notes: 'Controlled'),
  ],
  medications: const <Medication>[
    Medication(
      id: 'medication-id',
      name: 'Salbutamol',
      dosage: '100 mcg',
      frequency: 'As needed',
    ),
  ],
  emergencyContacts: const <EmergencyContact>[
    EmergencyContact(
      id: 'contact-id',
      name: 'Hodan Yusuf',
      relationship: 'Sister',
      phoneNumber: '+252610000000',
      isPrimary: true,
    ),
  ],
  updatedAtUtc: DateTime.utc(2026, 7, 28, 12),
);

class FakeHealthRepository implements HealthRepository {
  FakeHealthRepository({this.error});

  Object? error;
  int checks = 0;

  @override
  Future<void> check() async {
    checks++;
    if (error case final failure?) {
      throw failure;
    }
  }
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.user = samplePatient,
    this.loginError,
    this.logoutError,
  });

  AppUser user;
  Object? loginError;
  Object? logoutError;
  int loginCalls = 0;
  int logoutCalls = 0;
  String? receivedEmail;
  String? receivedPassword;

  @override
  Future<AppUser> getCurrentUser() async => user;

  @override
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    loginCalls++;
    receivedEmail = email;
    receivedPassword = password;
    if (loginError case final failure?) {
      throw failure;
    }
    return LoginResult(
      accessToken: 'test-access-token',
      tokenType: 'Bearer',
      expiresInSeconds: 900,
      user: user,
    );
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    if (logoutError case final failure?) {
      throw failure;
    }
  }
}

class FakePatientProfileRepository implements PatientProfileRepository {
  FakePatientProfileRepository({
    EmergencyProfile? profile,
    this.loadError,
    this.updateError,
  }) : current = profile ?? sampleProfile;

  EmergencyProfile current;
  Object? loadError;
  Object? updateError;
  String etag = '"profile-v1"';
  int loadCalls = 0;
  int updateCalls = 0;
  EmergencyProfile? receivedProfile;
  String? receivedEtag;

  @override
  Future<VersionedEmergencyProfile> getMyProfile() async {
    loadCalls++;
    if (loadError case final failure?) {
      throw failure;
    }
    return VersionedEmergencyProfile(profile: current, etag: etag);
  }

  @override
  Future<VersionedEmergencyProfile> updateMyProfile({
    required EmergencyProfile profile,
    required String etag,
  }) async {
    updateCalls++;
    receivedProfile = profile;
    receivedEtag = etag;
    if (updateError case final failure?) {
      throw failure;
    }
    current = profile.copyWith();
    this.etag = '"profile-v2"';
    return VersionedEmergencyProfile(profile: current, etag: this.etag);
  }
}

class FakeAccessRepository implements AccessRepository {
  FakeAccessRepository({this.qrAccess});

  final DoctorAccess? qrAccess;
  int grantCalls = 0;
  int revokeCalls = 0;
  int qrIssueCalls = 0;
  int qrRevokeCalls = 0;
  String? redeemedQrToken;
  final doctor = const DoctorOption(
    id: 'doctor-user-id',
    name: 'Dr. Ali Hassan',
    email: 'doctor@example.test',
  );

  @override
  Future<PatientAccessDashboard> patientDashboard() async =>
      PatientAccessDashboard(
        doctors: [doctor],
        grants: const [],
        audit: const [],
      );

  @override
  Future<void> grant({
    required String doctorEmail,
    required int minutes,
  }) async {
    grantCalls++;
  }

  @override
  Future<void> revoke(String grantId) async {
    revokeCalls++;
  }

  @override
  Future<MedicalQrAccess> issueMedicalQr() async {
    qrIssueCalls++;
    return MedicalQrAccess(
      token: 'test-medical-qr-token-value-1234567890',
      expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 5)),
    );
  }

  @override
  Future<void> revokeMedicalQr() async {
    qrRevokeCalls++;
  }

  @override
  Future<List<DoctorAccess>> doctorAccess() async => const [];

  @override
  Future<List<DoctorPatient>> doctorDirectory() async => const [];

  @override
  Future<DoctorAccess> breakGlass({
    required String patientProfileId,
    required String reason,
  }) => throw StateError('No fake break-glass access configured.');

  @override
  Future<DoctorAccess> redeemMedicalQr(String token) async {
    redeemedQrToken = token;
    return qrAccess ??
        (throw StateError('No fake Medical ID QR access configured.'));
  }

  @override
  Future<DoctorSnapshot> doctorSnapshot(String grantId) async {
    final access = qrAccess;
    if (access == null) throw StateError('No fake snapshot configured.');
    return DoctorSnapshot(
      expiresAt: access.expiresAt,
      profile: sampleProfile,
      accessType: access.accessType,
    );
  }
}

class FakeClinicalRepository implements ClinicalRepository {
  FakeClinicalRepository({List<ClinicalEncounter>? records})
    : records = records ?? <ClinicalEncounter>[];

  List<ClinicalEncounter> records;
  ClinicalEncounterDraft? receivedDraft;

  @override
  Future<List<ClinicalEncounter>> patientHistory() async => records;

  @override
  Future<List<ClinicalEncounter>> doctorHistory(String grantId) async =>
      records;

  @override
  Future<ClinicalEncounter> createEncounter(
    String grantId,
    ClinicalEncounterDraft draft,
  ) async {
    receivedDraft = draft;
    final record = ClinicalEncounter(
      id: 'encounter-id',
      patientName: sampleProfile.fullName,
      doctorName: sampleDoctor.displayName,
      chiefComplaint: draft.chiefComplaint,
      clinicalNotes: draft.clinicalNotes,
      disposition: draft.disposition,
      occurredAt: DateTime.utc(2026, 9, 5, 12),
      createdAt: DateTime.utc(2026, 9, 5, 12),
      observation: draft.observation,
      prescriptions: draft.prescriptions,
    );
    records = [record, ...records];
    return record;
  }
}

const invalidCredentials = ApiException(
  kind: ApiErrorKind.unauthorized,
  message: 'The email or password is incorrect.',
  statusCode: 401,
);
