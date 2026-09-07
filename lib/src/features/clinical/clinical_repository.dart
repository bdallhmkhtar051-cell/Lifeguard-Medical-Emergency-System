import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import 'clinical_models.dart';

abstract interface class ClinicalRepository {
  Future<List<ClinicalEncounter>> patientHistory();
  Future<List<ClinicalEncounter>> doctorHistory(String grantId);
  Future<ClinicalEncounter> createEncounter(
    String grantId,
    ClinicalEncounterDraft draft,
  );
}

class ApiClinicalRepository implements ClinicalRepository {
  ApiClinicalRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<ClinicalEncounter>> patientHistory() =>
      _history('/api/v1/patients/me/clinical-records');

  @override
  Future<List<ClinicalEncounter>> doctorHistory(String grantId) =>
      _history('/api/v1/doctors/emergency-access/$grantId/clinical-records');

  @override
  Future<ClinicalEncounter> createEncounter(
    String grantId,
    ClinicalEncounterDraft draft,
  ) async {
    try {
      return ClinicalEncounter.fromJson(
        (await _api.postJson(
          '/api/v1/doctors/emergency-access/$grantId/clinical-records',
          body: draft.toJson(),
        )).requireObject(),
      );
    } on FormatException {
      throw const ApiException.protocol();
    }
  }

  Future<List<ClinicalEncounter>> _history(String path) async {
    final data = (await _api.getJson(path)).data;
    if (data is! List) throw const ApiException.protocol();
    try {
      return data
          .cast<Map<String, dynamic>>()
          .map(ClinicalEncounter.fromJson)
          .toList();
    } on FormatException {
      throw const ApiException.protocol();
    }
  }
}
