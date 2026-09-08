import 'package:emergency_system/src/features/documents/document_models.dart';
import 'package:emergency_system/src/features/documents/medical_documents_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

void main() {
  testWidgets('patient can see metadata and remove a medical document', (
    tester,
  ) async {
    final repository = FakeDocumentRepository();
    repository.documents.add(
      MedicalDocument(
        id: 'report-id',
        fileName: 'laboratory-report.pdf',
        contentType: 'application/pdf',
        category: 'Lab result',
        description: 'Synthetic thesis report',
        sizeBytes: 2048,
        uploadedAt: DateTime.utc(2026, 9, 8),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MedicalDocumentsPanel(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('laboratory-report.pdf'), findsOneWidget);
    expect(find.textContaining('Lab result'), findsOneWidget);
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(repository.documents, isEmpty);
    expect(find.text('laboratory-report.pdf'), findsNothing);
  });
}
