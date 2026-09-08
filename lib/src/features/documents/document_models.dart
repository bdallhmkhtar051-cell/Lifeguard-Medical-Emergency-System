class MedicalDocument {
  const MedicalDocument({
    required this.id,
    required this.fileName,
    required this.contentType,
    required this.category,
    required this.sizeBytes,
    required this.uploadedAt,
    this.description,
  });

  factory MedicalDocument.fromJson(Map<String, dynamic> json) =>
      MedicalDocument(
        id: json['id'].toString(),
        fileName: json['fileName'].toString(),
        contentType: json['contentType'].toString(),
        category: json['category'].toString(),
        description: _optional(json['description']),
        sizeBytes: (json['sizeBytes'] as num).toInt(),
        uploadedAt: DateTime.parse(json['uploadedAtUtc'].toString()),
      );

  final String id;
  final String fileName;
  final String contentType;
  final String category;
  final String? description;
  final int sizeBytes;
  final DateTime uploadedAt;
}

String? _optional(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}
