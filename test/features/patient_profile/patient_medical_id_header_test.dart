import 'package:emergency_system/src/features/patient_profile/patient_medical_id_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

void main() {
  testWidgets('medical ID card remains usable at a mobile browser width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var editCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PatientMedicalIdHeader(
              profile: sampleProfile,
              onEdit: () => editCalls++,
              onRefresh: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Amina Yusuf'), findsOneWidget);
    expect(find.text('O+'), findsOneWidget);
    expect(find.text('Restricted'), findsOneWidget);
    expect(find.text('Display QR'), findsOneWidget);
    expect(find.text('View ICE'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('edit-profile-button')));
    expect(editCalls, 1);
  });

  testWidgets('ICE action shows real profile contacts', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PatientMedicalIdHeader(
            profile: sampleProfile,
            onEdit: () {},
            onRefresh: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('View ICE'));
    await tester.pumpAndSettle();

    expect(find.text('Emergency contacts'), findsOneWidget);
    expect(find.text('Hodan Yusuf'), findsOneWidget);
    expect(find.text('Sister • +252610000000'), findsOneWidget);
  });
}
