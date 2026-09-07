import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import 'emergency_profile.dart';
import 'patient_profile_repository.dart';

class PatientProfileController extends ChangeNotifier {
  PatientProfileController({required PatientProfileRepository repository})
    : _repository = repository;

  final PatientProfileRepository _repository;

  EmergencyProfile? _profile;
  String? _etag;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  Map<String, List<String>> _fieldErrors = const <String, List<String>>{};

  EmergencyProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  Map<String, List<String>> get fieldErrors => _fieldErrors;

  Future<void> load() async {
    if (_isLoading) {
      return;
    }
    _isLoading = true;
    _errorMessage = null;
    _fieldErrors = const <String, List<String>>{};
    notifyListeners();
    try {
      final result = await _repository.getMyProfile();
      _profile = result.profile;
      _etag = result.etag;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'The emergency profile could not be loaded.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> save(EmergencyProfile editedProfile) async {
    final etag = _etag;
    if (_profile == null || etag == null || _isSaving) {
      return false;
    }
    _isSaving = true;
    _errorMessage = null;
    _fieldErrors = const <String, List<String>>{};
    notifyListeners();
    try {
      final result = await _repository.updateMyProfile(
        profile: editedProfile,
        etag: etag,
      );
      _profile = result.profile;
      _etag = result.etag;
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.isConcurrencyConflict
          ? 'This profile changed in another session. Reload it before saving.'
          : error.message;
      _fieldErrors = error.fieldErrors;
      return false;
    } catch (_) {
      _errorMessage = 'The emergency profile could not be saved.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void dismissError() {
    if (_errorMessage == null) {
      return;
    }
    _errorMessage = null;
    _fieldErrors = const <String, List<String>>{};
    notifyListeners();
  }

  void clearSensitiveState({bool notify = true}) {
    _profile = null;
    _etag = null;
    _errorMessage = null;
    _fieldErrors = const <String, List<String>>{};
    if (notify) {
      notifyListeners();
    }
  }
}
