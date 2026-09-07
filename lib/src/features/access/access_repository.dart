import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import 'access_models.dart';

abstract interface class AccessRepository {
  Future<PatientAccessDashboard> patientDashboard();
  Future<void> grant({required String doctorEmail, required int minutes});
  Future<void> revoke(String grantId);
  Future<List<DoctorAccess>> doctorAccess();
  Future<List<DoctorPatient>> doctorDirectory();
  Future<DoctorAccess> breakGlass({
    required String patientProfileId,
    required String reason,
  });
  Future<DoctorSnapshot> doctorSnapshot(String grantId);
}

class ApiAccessRepository implements AccessRepository {
  ApiAccessRepository(this._api);
  static const _patientPath = '/api/v1/patients/me/emergency-access';
  static const _doctorPath = '/api/v1/doctors/emergency-access';
  final ApiClient _api;

  @override
  Future<PatientAccessDashboard> patientDashboard() async {
    try {
      return PatientAccessDashboard.fromJson(
        (await _api.getJson(_patientPath)).requireObject(),
      );
    } on FormatException {
      throw const ApiException.protocol();
    }
  }

  @override
  Future<void> grant({
    required String doctorEmail,
    required int minutes,
  }) async {
    await _api.postJson(
      _patientPath,
      body: {'doctorEmail': doctorEmail, 'durationMinutes': minutes},
    );
  }

  @override
  Future<void> revoke(String grantId) async {
    await _api.postJson('$_patientPath/$grantId/revoke');
  }

  @override
  Future<List<DoctorAccess>> doctorAccess() async {
    final data = (await _api.getJson(_doctorPath)).data;
    if (data is! List) throw const ApiException.protocol();
    try {
      return data
          .cast<Map<String, dynamic>>()
          .map(DoctorAccess.fromJson)
          .toList();
    } on FormatException {
      throw const ApiException.protocol();
    }
  }

  @override
  Future<List<DoctorPatient>> doctorDirectory() async {
    final data = (await _api.getJson('$_doctorPath/directory')).data;
    if (data is! List) throw const ApiException.protocol();
    try {
      return data
          .cast<Map<String, dynamic>>()
          .map(DoctorPatient.fromJson)
          .toList();
    } on FormatException {
      throw const ApiException.protocol();
    }
  }

  @override
  Future<DoctorAccess> breakGlass({
    required String patientProfileId,
    required String reason,
  }) async {
    try {
      return DoctorAccess.fromJson(
        (await _api.postJson(
          '$_doctorPath/break-glass',
          body: {'patientProfileId': patientProfileId, 'reason': reason},
        )).requireObject(),
      );
    } on FormatException {
      throw const ApiException.protocol();
    }
  }

  @override
  Future<DoctorSnapshot> doctorSnapshot(String grantId) async {
    try {
      return DoctorSnapshot.fromJson(
        (await _api.getJson('$_doctorPath/$grantId/snapshot')).requireObject(),
      );
    } on FormatException {
      throw const ApiException.protocol();
    }
  }
}
