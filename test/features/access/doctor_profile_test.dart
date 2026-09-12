import 'package:emergency_system/src/features/access/doctor_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

void main() {
  testWidgets('doctor edits and saves professional profile', (tester) async {
    final repository = FakeAccessRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DoctorProfilePage(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Professional profile'), findsOneWidget);
    expect(find.textContaining('not independently verified'), findsOneWidget);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(1), 'Emergency Teaching Hospital');
    await tester.enterText(fields.at(2), 'Trauma and Emergency Medicine');
    final saveButton = find.byKey(const ValueKey('save-doctor-profile'));
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pump(const Duration(milliseconds: 100));

    expect(repository.professionalProfile.hospitalName, 'Emergency Teaching Hospital');
    expect(repository.professionalProfile.department, 'Trauma and Emergency Medicine');
    expect(find.text('Professional profile saved.'), findsOneWidget);
  });
}
