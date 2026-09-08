import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import 'document_models.dart';

abstract interface class DocumentRepository {
  Future<List<MedicalDocument>> patientDocuments();
  Future<List<MedicalDocument>> doctorDocuments(String grantId);
  Future<MedicalDocument> upload({
    required List<int> bytes,
    required String fileName,
    required String contentType,
    required String category,
    String? description,
  });
  Future<void> delete(String documentId);
  Future<List<int>> downloadForPatient(String documentId);
  Future<List<int>> downloadForDoctor(String grantId, String documentId);
}

class ApiDocumentRepository implements DocumentRepository {
  ApiDocumentRepository(this._api);
  static const _patientPath = '/api/v1/patients/me/documents';
  final ApiClient _api;

  @override
  Future<List<MedicalDocument>> patientDocuments() => _list(_patientPath);

  @override
  Future<List<MedicalDocument>> doctorDocuments(String grantId) =>
      _list('/api/v1/doctors/emergency-access/$grantId/documents');

  @override
  Future<MedicalDocument> upload({
    required List<int> bytes,
    required String fileName,
    required String contentType,
    required String category,
    String? description,
  }) async {
    try {
      return MedicalDocument.fromJson(
        (await _api.postMultipart(
          _patientPath,
          bytes: bytes,
          fileName: fileName,
          contentType: contentType,
          fields: {
            'category': category,
            if (description?.trim().isNotEmpty ?? false)
              'description': description!.trim(),
          },
        )).requireObject(),
      );
    } on FormatException {
      throw const ApiException.protocol();
    }
  }

  @override
  Future<void> delete(String documentId) async {
    await _api.deleteJson('$_patientPath/$documentId');
  }

  @override
  Future<List<int>> downloadForPatient(String documentId) async =>
      (await _api.getBytes('$_patientPath/$documentId/content')).bytes;

  @override
  Future<List<int>> downloadForDoctor(
    String grantId,
    String documentId,
  ) async => (await _api.getBytes(
    '/api/v1/doctors/emergency-access/$grantId/documents/$documentId/content',
  )).bytes;

  Future<List<MedicalDocument>> _list(String path) async {
    final data = (await _api.getJson(path)).data;
    if (data is! List) throw const ApiException.protocol();
    try {
      return data
          .cast<Map<String, dynamic>>()
          .map(MedicalDocument.fromJson)
          .toList();
    } on FormatException {
      throw const ApiException.protocol();
    }
  }
}
