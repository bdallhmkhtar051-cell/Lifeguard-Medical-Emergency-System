import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import 'auth_models.dart';

abstract interface class AuthRepository {
  Future<LoginResult> login({required String email, required String password});

  Future<AppUser> getCurrentUser();

  Future<void> logout();
}

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.postJson(
        '/api/v1/auth/login',
        body: <String, dynamic>{'email': email.trim(), 'password': password},
        includeAuthorization: false,
      );
      return LoginResult.fromJson(response.requireObject());
    } on ApiException catch (error) {
      if (error.kind == ApiErrorKind.unauthorized) {
        throw const ApiException(
          kind: ApiErrorKind.unauthorized,
          message: 'The email or password is incorrect.',
          statusCode: 401,
        );
      }
      rethrow;
    } on FormatException {
      throw const ApiException.protocol();
    }
  }

  @override
  Future<AppUser> getCurrentUser() async {
    final response = await _apiClient.getJson('/api/v1/auth/me');
    try {
      return AppUser.fromJson(response.requireObject());
    } on FormatException {
      throw const ApiException.protocol();
    }
  }

  @override
  Future<void> logout() async {
    // The current API issues short-lived stateless JWTs and intentionally has
    // no logout endpoint. SessionController clears the in-memory token.
  }
}
