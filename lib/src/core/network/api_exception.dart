enum ApiErrorKind {
  validation,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  network,
  timeout,
  server,
  protocol,
  unknown,
}

/// A safe client-side representation of RFC 9457/ProblemDetails failures.
class ApiException implements Exception {
  const ApiException({
    required this.kind,
    required this.message,
    this.statusCode,
    this.code,
    this.traceId,
    this.fieldErrors = const <String, List<String>>{},
  });

  const ApiException.network([
    this.message = 'The server could not be reached. Check your connection.',
  ]) : kind = ApiErrorKind.network,
       statusCode = null,
       code = null,
       traceId = null,
       fieldErrors = const <String, List<String>>{};

  const ApiException.timeout()
    : kind = ApiErrorKind.timeout,
      message = 'The request took too long. Please try again.',
      statusCode = null,
      code = null,
      traceId = null,
      fieldErrors = const <String, List<String>>{};

  const ApiException.protocol()
    : kind = ApiErrorKind.protocol,
      message = 'The server returned an unexpected response.',
      statusCode = null,
      code = null,
      traceId = null,
      fieldErrors = const <String, List<String>>{};

  final ApiErrorKind kind;
  final String message;
  final int? statusCode;
  final String? code;
  final String? traceId;
  final Map<String, List<String>> fieldErrors;

  bool get isConcurrencyConflict => kind == ApiErrorKind.conflict;

  @override
  String toString() => 'ApiException($kind, $statusCode, $message)';
}
