import 'dart:convert';

import 'package:emergency_system/src/core/network/api_client.dart';
import 'package:emergency_system/src/features/patient_profile/patient_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/fakes.dart';

void main() {
  test('GET keeps the profile ETag outside the medical model', () async {
    final repository = ApiPatientProfileRepository(
      ApiClient(
        baseUri: Uri.parse('http://localhost:5080'),
        client: MockClient(
          (_) async => http.Response(
            jsonEncode(_profileJson),
            200,
            headers: {
              'content-type': 'application/json',
              'etag': '"version-1"',
            },
          ),
        ),
      ),
    );

    final result = await repository.getMyProfile();

    expect(result.profile.fullName, 'Amina Yusuf');
    expect(result.etag, '"version-1"');
  });

  test('PUT sends If-Match and excludes child IDs', () async {
    late http.Request request;
    final repository = ApiPatientProfileRepository(
      ApiClient(
        baseUri: Uri.parse('http://localhost:5080'),
        client: MockClient((captured) async {
          request = captured;
          return http.Response(
            jsonEncode(_profileJson),
            200,
            headers: {
              'content-type': 'application/json',
              'etag': '"version-2"',
            },
          );
        }),
      ),
    );

    await repository.updateMyProfile(
      profile: sampleProfile,
      etag: '"version-1"',
    );
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    final allergies = body['allergies'] as List<dynamic>;

    expect(request.url.path, '/api/v1/patients/me/emergency-profile');
    expect(request.method, 'PUT');
    expect(_header(request, 'if-match'), '"version-1"');
    expect(body, isNot(contains('id')));
    expect(allergies.single, isNot(contains('id')));
  });
}

final _profileJson = {
  'id': 'profile-id',
  'fullName': 'Amina Yusuf',
  'dateOfBirth': '1997-04-12',
  'bloodGroup': 'OPositive',
  'allergies': [
    {
      'id': 'allergy-id',
      'name': 'Penicillin',
      'severity': 'Severe',
      'reaction': 'Anaphylaxis',
    },
  ],
  'medicalConditions': <Object>[],
  'medications': <Object>[],
  'emergencyContacts': <Object>[],
  'updatedAtUtc': '2026-07-28T12:00:00Z',
};

String? _header(http.Request request, String name) {
  final normalized = name.toLowerCase();
  for (final entry in request.headers.entries) {
    if (entry.key.toLowerCase() == normalized) {
      return entry.value;
    }
  }
  return null;
}
