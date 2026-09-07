import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import 'emergency_profile.dart';

class VersionedEmergencyProfile {
  const VersionedEmergencyProfile({required this.profile, required this.etag});

  final EmergencyProfile profile;
  final String etag;
}

abstract interface class PatientProfileRepository {
  Future<VersionedEmergencyProfile> getMyProfile();

  Future<VersionedEmergencyProfile> updateMyProfile({
    required EmergencyProfile profile,
    required String etag,
  });
}

class ApiPatientProfileRepository implements PatientProfileRepository {
  ApiPatientProfileRepository(this._apiClient);

  static const _path = '/api/v1/patients/me/emergency-profile';
  final ApiClient _apiClient;

  @override
  Future<VersionedEmergencyProfile> getMyProfile() async {
    final response = await _apiClient.getJson(_path);
    return _parse(response);
  }

  @override
  Future<VersionedEmergencyProfile> updateMyProfile({
    required EmergencyProfile profile,
    required String etag,
  }) async {
    if (etag.trim().isEmpty) {
      throw const ApiException.protocol();
    }
    final response = await _apiClient.putJson(
      _path,
      body: profile.toUpdateJson(),
      headers: <String, String>{'If-Match': etag},
    );
    return _parse(response);
  }

  VersionedEmergencyProfile _parse(ApiResponse response) {
    final etag = response.headers['etag']?.trim();
    if (etag == null || etag.isEmpty) {
      throw const ApiException(
        kind: ApiErrorKind.protocol,
        message: 'The server response did not include a record version.',
      );
    }
    try {
      return VersionedEmergencyProfile(
        profile: EmergencyProfile.fromJson(response.requireObject()),
        etag: etag,
      );
    } on FormatException {
      throw const ApiException.protocol();
    }
  }
}
