import 'dart:async';
import 'dart:convert';

import 'package:emergency_system/src/core/network/api_client.dart';
import 'package:emergency_system/src/core/network/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ApiClient', () {
    test('health uses the configured base URL without authorization', () async {
      late http.Request request;
      final client = ApiClient(
        baseUri: Uri.parse('http://localhost:5080'),
        client: MockClient((captured) async {
          request = captured;
          return http.Response('Healthy', 200);
        }),
      )..setAuthorization(accessToken: 'secret');

      await client.checkHealth();

      expect(request.url.toString(), 'http://localhost:5080/health');
      expect(request.method, 'GET');
      expect(request.headers, isNot(contains('Authorization')));
    });

    test('adds the in-memory bearer token to protected requests', () async {
      late http.Request request;
      final client = ApiClient(
        baseUri: Uri.parse('https://api.example.test'),
        client: MockClient((captured) async {
          request = captured;
          return http.Response(
            '{"id":"user-id"}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      )..setAuthorization(accessToken: 'abc123');

      await client.getJson('/api/v1/auth/me');

      expect(_header(request, 'authorization'), 'Bearer abc123');
    });

    test('maps validation ProblemDetails and field errors', () async {
      final client = ApiClient(
        baseUri: Uri.parse('http://localhost:5080'),
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'title': 'Validation failed',
              'status': 400,
              'errors': {
                'bloodGroup': ['Blood group is invalid.'],
              },
              'traceId': 'trace-1',
            }),
            400,
            headers: {'content-type': 'application/problem+json'},
          ),
        ),
      );

      await expectLater(
        client.putJson('/profile', body: const {'bloodGroup': 'X'}),
        throwsA(
          isA<ApiException>()
              .having((error) => error.kind, 'kind', ApiErrorKind.validation)
              .having(
                (error) => error.fieldErrors['bloodGroup'],
                'bloodGroup errors',
                ['Blood group is invalid.'],
              )
              .having((error) => error.traceId, 'traceId', 'trace-1'),
        ),
      );
    });

    test('maps 412 to a concurrency conflict', () async {
      final client = ApiClient(
        baseUri: Uri.parse('http://localhost:5080'),
        client: MockClient(
          (_) async => http.Response(
            '{"title":"Precondition failed"}',
            412,
            headers: {'content-type': 'application/problem+json'},
          ),
        ),
      );

      await expectLater(
        client.putJson('/profile', body: const {}),
        throwsA(
          isA<ApiException>().having(
            (error) => error.kind,
            'kind',
            ApiErrorKind.conflict,
          ),
        ),
      );
    });

    test(
      'notifies the session boundary when a protected call returns 401',
      () async {
        var expired = false;
        final client = ApiClient(
          baseUri: Uri.parse('http://localhost:5080'),
          client: MockClient((_) async => http.Response('', 401)),
        )..onUnauthorized = () => expired = true;

        await expectLater(
          client.getJson('/protected'),
          throwsA(isA<ApiException>()),
        );
        await Future<void>.delayed(Duration.zero);
        expect(expired, isTrue);
      },
    );

    test(
      'maps a request timeout without exposing an internal exception',
      () async {
        final pending = Completer<http.Response>();
        final client = ApiClient(
          baseUri: Uri.parse('http://localhost:5080'),
          client: MockClient((_) => pending.future),
          timeout: const Duration(milliseconds: 1),
        );

        await expectLater(
          client.checkHealth(),
          throwsA(
            isA<ApiException>().having(
              (error) => error.kind,
              'kind',
              ApiErrorKind.timeout,
            ),
          ),
        );
      },
    );
  });
}

String? _header(http.Request request, String name) {
  final normalized = name.toLowerCase();
  for (final entry in request.headers.entries) {
    if (entry.key.toLowerCase() == normalized) {
      return entry.value;
    }
  }
  return null;
}
