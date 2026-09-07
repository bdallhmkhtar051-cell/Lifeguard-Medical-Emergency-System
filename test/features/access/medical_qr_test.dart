import 'package:emergency_system/src/features/access/access_models.dart';
import 'package:emergency_system/src/features/access/doctor_access_page.dart';
import 'package:emergency_system/src/features/access/medical_qr_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

void main() {
  testWidgets('patient sees a real QR and closing revokes its token', (
    tester,
  ) async {
    final repository = FakeAccessRepository();
    await tester.pumpWidget(
      MaterialApp(home: MedicalQrDialog(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Secure Medical ID QR'), findsOneWidget);
    expect(find.textContaining('works once only'), findsOneWidget);
    expect(find.text('Copy link'), findsOneWidget);
    expect(repository.qrIssueCalls, 1);

    await tester.tap(find.text('Close and revoke'));
    await tester.pumpAndSettle();
    expect(repository.qrRevokeCalls, 1);
  });

  testWidgets('doctor automatically redeems a QR link after sign in', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final access = DoctorAccess(
      id: 'qr-grant-id',
      patientProfileId: sampleProfile.id,
      patientName: sampleProfile.fullName,
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      accessType: EmergencyAccessKind.qrConsented,
    );
    final repository = FakeAccessRepository(qrAccess: access);

    await tester.pumpWidget(
      MaterialApp(
        home: DoctorAccessPage(
          repository: repository,
          clinicalRepository: FakeClinicalRepository(),
          user: sampleDoctor,
          initialMedicalQrToken: 'one-use-token',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.redeemedQrToken, 'one-use-token');
    expect(find.textContaining('QR CONSENT'), findsOneWidget);
    expect(find.text('Amina Yusuf'), findsWidgets);
  });
}
