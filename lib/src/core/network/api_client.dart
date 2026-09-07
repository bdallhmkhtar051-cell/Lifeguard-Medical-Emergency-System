import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

class ApiResponse {
  const ApiResponse({
    required this.statusCode,
    required this.headers,
    this.data,
  });

  final int statusCode;
  final Map<String, String> headers;
  final Object? data;

  Map<String, dynamic> requireObject() {
    final value = data;
    if (value is Map<String, dynamic>) {
      return value;
    }
    throw const ApiException.protocol();
  }
}

/// Small HTTP boundary shared by feature repositories.
///
/// Authentication is intentionally kept in memory. The browser never writes
/// the access token to localStorage or another persistent JavaScript store.
class ApiClient {
  ApiClient({
    required Uri baseUri,
    required http.Client client,
    this.timeout = const Duration(seconds: 15),
  }) : _baseUri = baseUri,
       _client = client;

  final Uri _baseUri;
  final http.Client _client;
  final Duration timeout;

  String? _accessToken;
  String _tokenType = 'Bearer';

  void Function()? onUnauthorized;

  void setAuthorization({
    required String accessToken,
    String tokenType = 'Bearer',
  }) {
    _accessToken = accessToken;
    _tokenType = tokenType.trim().isEmpty ? 'Bearer' : tokenType.trim();
  }

  void clearAuthorization() {
    _accessToken = null;
    _tokenType = 'Bearer';
  }

  Future<void> checkHealth() async {
    await _send(method: 'GET', path: '/health', includeAuthorization: false);
  }

  Future<ApiResponse> getJson(String path) {
    return _send(method: 'GET', path: path);
  }

  Future<ApiResponse> postJson(
    String path, {
    Map<String, dynamic>? body,
    bool includeAuthorization = true,
  }) {
    return _send(
      method: 'POST',
      path: path,
      body: body,
      includeAuthorization: includeAuthorization,
    );
  }

  Future<ApiResponse> putJson(
    String path, {
    required Map<String, dynamic> body,
    Map<String, String> headers = const <String, String>{},
  }) {
    return _send(method: 'PUT', path: path, body: body, headers: headers);
  }

  Future<ApiResponse> _send({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    Map<String, String> headers = const <String, String>{},
    bool includeAuthorization = true,
  }) async {
    final request = http.Request(method, _resolve(path));
    request.headers.addAll(<String, String>{
      'Accept': 'application/json',
      ...headers,
    });
    if (body != null) {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.body = jsonEncode(body);
    }
    final token = _accessToken;
    if (includeAuthorization && token != null) {
      request.headers['Authorization'] = '$_tokenType $token';
    }

    try {
      final streamed = await _client.send(request).timeout(timeout);
      final response = await http.Response.fromStream(
        streamed,
      ).timeout(timeout);
      final parsed = _decodeBody(response);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(
          statusCode: response.statusCode,
          headers: response.headers,
          data: parsed,
        );
      }

      final exception = _problemException(response, parsed);
      if (response.statusCode == 401 && includeAuthorization) {
        final callback = onUnauthorized;
        if (callback != null) {
          // Let the repository/controller finish handling this response before
          // the session switch removes and disposes the authenticated widget
          // tree.
          Timer.run(callback);
        }
      }
      throw exception;
    } on TimeoutException {
      throw const ApiException.timeout();
    } on http.ClientException {
      throw const ApiException.network();
    } on ApiException {
      rethrow;
    } on FormatException {
      throw const ApiException.protocol();
    }
  }

  Uri _resolve(String path) {
    final base = _baseUri.toString().replaceFirst(RegExp(r'/*$'), '');
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$normalizedPath');
  }

  Object? _decodeBody(http.Response response) {
    if (response.bodyBytes.isEmpty) {
      return null;
    }
    final text = utf8.decode(response.bodyBytes).trim();
    if (text.isEmpty) {
      return null;
    }
    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.toLowerCase().contains('json')) {
      return text;
    }
    return jsonDecode(text);
  }

  ApiException _problemException(http.Response response, Object? parsed) {
    final status = response.statusCode;
    final problem = parsed is Map<String, dynamic>
        ? parsed
        : const <String, dynamic>{};
    final detail = _nonBlank(problem['detail']);
    final title = _nonBlank(problem['title']);
    final code = _nonBlank(problem['code']) ?? _nonBlank(problem['type']);
    final traceId =
        _nonBlank(problem['traceId']) ?? _nonBlank(problem['traceIdentifier']);
    final errors = _fieldErrors(problem['errors']);

    final kind = switch (status) {
      400 || 422 => ApiErrorKind.validation,
      401 => ApiErrorKind.unauthorized,
      403 => ApiErrorKind.forbidden,
      404 => ApiErrorKind.notFound,
      409 || 412 => ApiErrorKind.conflict,
      >= 500 => ApiErrorKind.server,
      _ => ApiErrorKind.unknown,
    };

    // Raw server details are useful for expected 4xx cases. Do not display
    // internal exception text returned by a 5xx response.
    final message = switch (kind) {
      ApiErrorKind.unauthorized => 'Your session is invalid or has expired.',
      ApiErrorKind.forbidden => 'You are not allowed to perform this action.',
      ApiErrorKind.conflict =>
        detail ??
            title ??
            'This record changed elsewhere. Reload it and try again.',
      ApiErrorKind.server => 'The server encountered a problem. Try again.',
      _ => detail ?? title ?? 'The request could not be completed.',
    };

    return ApiException(
      kind: kind,
      message: message,
      statusCode: status,
      code: code,
      traceId: traceId,
      fieldErrors: errors,
    );
  }

  static String? _nonBlank(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    return value.trim();
  }

  static Map<String, List<String>> _fieldErrors(Object? value) {
    if (value is! Map) {
      return const <String, List<String>>{};
    }
    final result = <String, List<String>>{};
    for (final entry in value.entries) {
      final key = entry.key.toString();
      final rawMessages = entry.value;
      if (rawMessages is List) {
        result[key] = rawMessages.map((item) => item.toString()).toList();
      } else if (rawMessages != null) {
        result[key] = <String>[rawMessages.toString()];
      }
    }
    return result;
  }
}
