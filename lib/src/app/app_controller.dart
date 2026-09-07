import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../features/health/health_repository.dart';

enum ApiAvailability { checking, online, offline }

class AppController extends ChangeNotifier {
  AppController({required HealthRepository healthRepository})
    : _healthRepository = healthRepository;

  final HealthRepository _healthRepository;

  ApiAvailability _availability = ApiAvailability.checking;
  String? _healthError;
  bool _checkInProgress = false;

  ApiAvailability get availability => _availability;
  String? get healthError => _healthError;

  Future<void> bootstrap() => checkHealth();

  Future<void> checkHealth() async {
    if (_checkInProgress) {
      return;
    }
    _checkInProgress = true;
    _availability = ApiAvailability.checking;
    _healthError = null;
    notifyListeners();
    try {
      await _healthRepository.check();
      _availability = ApiAvailability.online;
    } on ApiException catch (error) {
      _availability = ApiAvailability.offline;
      _healthError = error.message;
    } catch (_) {
      _availability = ApiAvailability.offline;
      _healthError = 'The API is unavailable. Check that it is running.';
    } finally {
      _checkInProgress = false;
      notifyListeners();
    }
  }
}
