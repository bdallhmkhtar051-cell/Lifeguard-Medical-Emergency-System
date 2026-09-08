import 'package:emergency_system/src/features/access/access_models.dart';
import 'package:emergency_system/src/features/access/doctor_access_page.dart';
import 'package:emergency_system/src/features/access/medical_qr_dialog.dart';
import 'package:emergency_system/src/features/access/medical_qr_scanner_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

void main() {
  test('scanner accepts only a Medical ID link from the current app', () {
    final expected = Uri.parse('https://lifeguard.example');

    expect(
      extractMedicalQrToken(
        'https://lifeguard.example/#medicalQr=secure-token',
        expectedBaseUri: expected,
      ),
      'secure-token',
    );
    expect(
      extractMedicalQrToken(
        'https://untrusted.example/#medicalQr=stolen-token',
        expectedBaseUri: expected,
      ),
      isNull,
    );
    expect(
      extractMedicalQrToken(
        'https://lifeguard.example/unrelated',
        expectedBaseUri: expected,
      ),
      isNull,
    );
  });

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

  testWidgets('doctor scans a patient QR with the camera workflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final access = DoctorAccess(
      id: 'camera-grant-id',
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
          scannerExpectedBaseUri: Uri.parse('http://localhost'),
          scannerBuilder: (_, onDetected) => ColoredBox(
            color: Colors.black,
            child: Center(
              child: FilledButton(
                key: const ValueKey('simulate-camera-scan'),
                onPressed: () => onDetected(
                  'http://localhost/#medicalQr=camera-scanned-token',
                ),
                child: const Text('Simulate scan'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('scan-medical-qr-button')));
    await tester.pumpAndSettle();
    expect(find.byType(MedicalQrScannerDialog), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('simulate-camera-scan')));
    await tester.pumpAndSettle();

    expect(repository.redeemedQrToken, 'camera-scanned-token');
    expect(find.textContaining('QR CONSENT'), findsOneWidget);
    expect(find.text(sampleProfile.fullName), findsWidgets);
  });
}
