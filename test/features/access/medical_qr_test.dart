import 'package:emergency_system/src/features/access/access_models.dart';
import 'package:emergency_system/src/features/access/doctor_access_page.dart';
import 'package:emergency_system/src/features/access/medical_qr_dialog.dart';
import 'package:emergency_system/src/features/access/medical_qr_scanner_dialog.dart';
import 'package:emergency_system/src/features/access/permanent_emergency_qr_dialog.dart';
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

  test('scanner distinguishes temporary and permanent LifeGuard codes', () {
    final origin = Uri.parse('https://lifeguard.example');
    final temporary = parseMedicalQr(
      'https://lifeguard.example/#medicalQr=secure-token',
      expectedBaseUri: origin,
    );
    final permanent = parseMedicalQr(
      'LIFEGUARD:EMERGENCY:1:0123456789abcdef0123456789abcdef',
      expectedBaseUri: origin,
    );

    expect(temporary?.kind, MedicalQrScanKind.temporaryConsent);
    expect(temporary?.value, 'secure-token');
    expect(permanent?.kind, MedicalQrScanKind.permanentEmergency);
    expect(
      parseMedicalQr(
        'LIFEGUARD:EMERGENCY:1:not-a-valid-id',
        expectedBaseUri: origin,
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

  testWidgets('permanent QR is clearly identification-only', (tester) async {
    final repository = FakeAccessRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PermanentEmergencyQrDialog(
            repository: repository,
            patientName: sampleProfile.fullName,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Permanent Emergency Medical ID'), findsOneWidget);
    expect(find.textContaining('IDENTIFICATION ONLY'), findsOneWidget);
    expect(find.textContaining('does not unlock'), findsOneWidget);
    expect(find.textContaining('break-glass action'), findsOneWidget);
    expect(repository.emergencyMedicalIdCalls, 1);
    expect(repository.qrIssueCalls, 0);
  });

  testWidgets('patient can replace a permanent QR after a clear warning', (
    tester,
  ) async {
    final repository = FakeAccessRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PermanentEmergencyQrDialog(
            repository: repository,
            patientName: sampleProfile.fullName,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('printable-emergency-id-card')),
      findsOneWidget,
    );
    expect(find.text(sampleProfile.fullName), findsOneWidget);
    expect(find.byKey(const ValueKey('print-emergency-card')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('rotate-emergency-qr')));
    await tester.pumpAndSettle();
    expect(find.textContaining('stop working immediately'), findsOneWidget);
    expect(repository.emergencyMedicalIdRotateCalls, 0);

    await tester.tap(find.byKey(const ValueKey('confirm-rotate-emergency-qr')));
    await tester.pumpAndSettle();

    expect(repository.emergencyMedicalIdRotateCalls, 1);
    expect(find.text('Permanent Emergency Medical ID'), findsOneWidget);
    expect(
      tester
          .widget<SelectableText>(
            find.byKey(
              const ValueKey('permanent-emergency-id-value'),
              skipOffstage: false,
            ),
          )
          .data,
      'FEDCBA98-7654-3210-FEDC-BA9876543210',
    );
    expect(find.textContaining('Old copies no longer work'), findsOneWidget);
  });

  testWidgets('scanner dialog fits a short browser window', (tester) async {
    tester.view.physicalSize = const Size(800, 430);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var cameraCleanupCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => MedicalQrScannerDialog(
                  expectedBaseUri: Uri.parse('http://localhost'),
                  cameraCleanup: () async => cameraCleanupCalls++,
                  scannerBuilder: (_, __) =>
                      const ColoredBox(color: Colors.black),
                ),
              ),
              child: const Text('Open scanner'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open scanner'));
    await tester.pumpAndSettle();

    expect(find.byType(MedicalQrScannerDialog), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(MedicalQrScannerDialog), findsNothing);
    expect(cameraCleanupCalls, 1);
  });

  testWidgets('successful scan releases camera before returning its result', (
    tester,
  ) async {
    var cameraCleanupCalls = 0;
    MedicalQrScanResult? scanResult;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                scanResult = await showDialog<MedicalQrScanResult>(
                  context: context,
                  builder: (_) => MedicalQrScannerDialog(
                    expectedBaseUri: Uri.parse('http://localhost'),
                    cameraCleanup: () async => cameraCleanupCalls++,
                    scannerBuilder: (_, onDetected) => FilledButton(
                      onPressed: () =>
                          onDetected('http://localhost/#medicalQr=test-token'),
                      child: const Text('Complete scan'),
                    ),
                  ),
                );
              },
              child: const Text('Open scanner'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open scanner'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Complete scan'));
    await tester.pumpAndSettle();

    expect(cameraCleanupCalls, 1);
    expect(scanResult?.kind, MedicalQrScanKind.temporaryConsent);
    expect(scanResult?.value, 'test-token');
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
        home: Scaffold(
          body: DoctorAccessPage(
            repository: repository,
            clinicalRepository: FakeClinicalRepository(),
            user: sampleDoctor,
            initialMedicalQrToken: 'one-use-token',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.redeemedQrToken, 'one-use-token');
    expect(find.textContaining('QR CONSENT'), findsOneWidget);
    expect(find.text('Amina Yusuf'), findsWidgets);
  });

  testWidgets('manual refresh closes a record after access is revoked', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final access = DoctorAccess(
      id: 'revoked-grant-id',
      patientProfileId: sampleProfile.id,
      patientName: sampleProfile.fullName,
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      accessType: EmergencyAccessKind.qrConsented,
    );
    final repository = FakeAccessRepository(
      qrAccess: access,
      activeAccess: [access],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DoctorAccessPage(
            repository: repository,
            clinicalRepository: FakeClinicalRepository(),
            user: sampleDoctor,
            initialMedicalQrToken: 'one-use-token',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('doctor-clinical-snapshot')),
      findsOneWidget,
    );

    repository.rejectDoctorSnapshot = true;
    repository.activeDoctorAccess = [];
    await tester.tap(find.byKey(const ValueKey('refresh-doctor-data')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('doctor-clinical-snapshot')),
      findsNothing,
    );
    expect(find.textContaining('record has been closed'), findsOneWidget);
  });

  testWidgets('open record closes automatically when its grant disappears', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final access = DoctorAccess(
      id: 'auto-revoked-grant-id',
      patientProfileId: sampleProfile.id,
      patientName: sampleProfile.fullName,
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      accessType: EmergencyAccessKind.qrConsented,
    );
    final repository = FakeAccessRepository(
      qrAccess: access,
      activeAccess: [access],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DoctorAccessPage(
            repository: repository,
            clinicalRepository: FakeClinicalRepository(),
            user: sampleDoctor,
            initialMedicalQrToken: 'one-use-token',
            accessRevalidationInterval: const Duration(seconds: 1),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('doctor-clinical-snapshot')),
      findsOneWidget,
    );

    repository.activeDoctorAccess = [];
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('doctor-clinical-snapshot')),
      findsNothing,
    );
    expect(find.textContaining('record has been closed'), findsOneWidget);
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

    final aiButton = find.byKey(const ValueKey('generate-ai-summary'));
    await tester.ensureVisible(aiButton);
    await tester.tap(aiButton);
    await tester.pumpAndSettle();

    expect(repository.aiSummaryCalls, 1);
    expect(find.text('AI Medical Summary'), findsOneWidget);
    expect(find.textContaining('Not a diagnosis'), findsOneWidget);
  });

  testWidgets(
    'permanent QR identifies only before documented break-glass access',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const payload = 'LIFEGUARD:EMERGENCY:1:0123456789abcdef0123456789abcdef';
      final repository = FakeAccessRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: DoctorAccessPage(
            repository: repository,
            clinicalRepository: FakeClinicalRepository(),
            user: sampleDoctor,
            scannerExpectedBaseUri: Uri.parse('http://localhost'),
            scannerBuilder: (_, onDetected) => Center(
              child: FilledButton(
                key: const ValueKey('simulate-permanent-scan'),
                onPressed: () => onDetected(payload),
                child: const Text('Scan permanent ID'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('scan-medical-qr-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('simulate-permanent-scan')));
      await tester.pumpAndSettle();

      expect(repository.identifiedEmergencyQrPayload, payload);
      expect(find.text('Emergency patient identified'), findsOneWidget);
      expect(find.textContaining('No medical information'), findsOneWidget);
      expect(find.text('Severe allergies'), findsNothing);
      expect(repository.breakGlassReason, isNull);

      await tester.tap(
        find.byKey(const ValueKey('continue-emergency-break-glass')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('break-glass-reason')),
        'Patient is unconscious after a road traffic emergency.',
      );
      await tester.tap(find.byKey(const ValueKey('confirm-break-glass')));
      await tester.pumpAndSettle();

      expect(repository.breakGlassReason, contains('Patient is unconscious'));
      expect(find.textContaining('BREAK-GLASS'), findsWidgets);
      expect(find.text(sampleProfile.fullName), findsWidgets);
    },
  );
}
