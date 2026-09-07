import 'package:emergency_system/src/core/network/api_client.dart';
import 'package:emergency_system/src/features/auth/auth_models.dart';
import 'package:emergency_system/src/features/auth/session_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/fakes.dart';

void main() {
  group('auth models', () {
    test('parses supported roles and does not grant unknown roles', () {
      final user = AppUser.fromJson({
        'id': '1',
        'email': 'doctor@example.test',
        'displayName': 'Doctor',
        'roles': ['Doctor', 'UntrustedSuperUser'],
      });

      expect(user.roles, {UserRole.doctor});
      expect(user.hasRole(UserRole.administrator), isFalse);
    });

    test('rejects a user with no supported role', () {
      expect(
        () => AppUser.fromJson({
          'id': '1',
          'email': 'unknown@example.test',
          'displayName': 'Unknown',
          'roles': ['UntrustedSuperUser'],
        }),
        throwsFormatException,
      );
    });
  });

  group('SessionController', () {
    test('signs in and applies token to subsequent API requests', () async {
      late http.Request protectedRequest;
      final apiClient = ApiClient(
        baseUri: Uri.parse('http://localhost:5080'),
        client: MockClient((request) async {
          protectedRequest = request;
          return http.Response(
            '{"ok":true}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      final repository = FakeAuthRepository();
      final controller = SessionController(
        repository: repository,
        apiClient: apiClient,
      );

      final success = await controller.login(
        email: ' patient@example.test ',
        password: 'correct password',
      );
      await apiClient.getJson('/protected');

      expect(success, isTrue);
      expect(controller.status, SessionStatus.signedIn);
      expect(controller.user, samplePatient);
      expect(
        _header(protectedRequest, 'authorization'),
        'Bearer test-access-token',
      );
    });

    test('reports invalid credentials without authenticating', () async {
      final controller = SessionController(
        repository: FakeAuthRepository(loginError: invalidCredentials),
        apiClient: _unusedApiClient(),
      );

      final success = await controller.login(
        email: 'patient@example.test',
        password: 'wrong',
      );

      expect(success, isFalse);
      expect(controller.status, SessionStatus.signedOut);
      expect(controller.user, isNull);
      expect(controller.errorMessage, contains('incorrect'));
    });

    test(
      'logout clears local state even when the server is unavailable',
      () async {
        final repository = FakeAuthRepository(
          logoutError: StateError('network down'),
        );
        final controller = SessionController(
          repository: repository,
          apiClient: _unusedApiClient(),
        );
        await controller.login(
          email: 'patient@example.test',
          password: 'correct',
        );

        await controller.logout();

        expect(controller.status, SessionStatus.signedOut);
        expect(controller.user, isNull);
        expect(repository.logoutCalls, 1);
      },
    );
  });
}

ApiClient _unusedApiClient() => ApiClient(
  baseUri: Uri.parse('http://localhost:5080'),
  client: MockClient((_) async => http.Response('', 204)),
);

String? _header(http.Request request, String name) {
  final normalized = name.toLowerCase();
  for (final entry in request.headers.entries) {
    if (entry.key.toLowerCase() == normalized) {
      return entry.value;
    }
  }
  return null;
}
