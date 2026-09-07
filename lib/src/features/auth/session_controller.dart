import 'package:flutter/foundation.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import 'auth_models.dart';
import 'auth_repository.dart';

enum SessionStatus { signedOut, signingIn, signedIn, signingOut }

class SessionController extends ChangeNotifier {
  SessionController({
    required AuthRepository repository,
    required ApiClient apiClient,
  }) : _repository = repository,
       _apiClient = apiClient;

  final AuthRepository _repository;
  final ApiClient _apiClient;

  SessionStatus _status = SessionStatus.signedOut;
  AppUser? _user;
  String? _errorMessage;
  DateTime? _expiresAtUtc;

  SessionStatus get status => _status;
  AppUser? get user => _user;
  String? get errorMessage => _errorMessage;
  DateTime? get expiresAtUtc => _expiresAtUtc;
  bool get isBusy =>
      _status == SessionStatus.signingIn || _status == SessionStatus.signingOut;

  Future<bool> login({required String email, required String password}) async {
    if (isBusy) {
      return false;
    }
    _status = SessionStatus.signingIn;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.login(email: email, password: password);
      _apiClient.setAuthorization(
        accessToken: result.accessToken,
        tokenType: result.tokenType,
      );
      _user = result.user;
      _expiresAtUtc = DateTime.now().toUtc().add(
        Duration(seconds: result.expiresInSeconds),
      );
      _status = SessionStatus.signedIn;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _clearSession();
      _errorMessage = error.message;
    } catch (_) {
      _clearSession();
      _errorMessage = 'Sign-in could not be completed. Please try again.';
    }
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    if (_status == SessionStatus.signingOut) {
      return;
    }
    _status = SessionStatus.signingOut;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.logout();
    } catch (_) {
      // Local sign-out must always complete, even when the network is down.
    } finally {
      _clearSession();
      notifyListeners();
    }
  }

  /// Called when a protected API request returns 401.
  void expireSession() {
    if (_status == SessionStatus.signedOut) {
      return;
    }
    _clearSession();
    _errorMessage = 'Your session expired. Please sign in again.';
    notifyListeners();
  }

  void dismissError() {
    if (_errorMessage == null) {
      return;
    }
    _errorMessage = null;
    notifyListeners();
  }

  void _clearSession() {
    _apiClient.clearAuthorization();
    _user = null;
    _expiresAtUtc = null;
    _status = SessionStatus.signedOut;
  }
}
