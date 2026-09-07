/// Compile-time configuration that is safe to include in the Flutter client.
///
/// API secrets must never be added here. Override the development URL with:
/// `--dart-define=API_BASE_URL=https://your-api.example`.
class AppConfig {
  const AppConfig.fromEnvironment({
    this.apiBaseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:5080',
    ),
  });

  final String apiBaseUrl;

  Uri get apiBaseUri {
    final uri = Uri.parse(apiBaseUrl);
    if (!uri.hasScheme ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw FormatException(
        'API_BASE_URL must be an absolute HTTP or HTTPS URL.',
        apiBaseUrl,
      );
    }
    return uri;
  }
}
