import 'package:emergency_system/src/features/access/access_models.dart';
import 'package:emergency_system/src/features/access/access_repository.dart';
import 'package:emergency_system/src/features/access/doctor_access_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

void main() {
  testWidgets('doctor must explain break-glass access before snapshot opens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = _BreakGlassRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: DoctorAccessPage(
          repository: repository,
          clinicalRepository: FakeClinicalRepository(),
          user: sampleDoctor,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final button = find.byKey(const ValueKey('break-glass-profile-id'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('break-glass-reason')),
      'Too short',
    );
    await tester.tap(find.byKey(const ValueKey('confirm-break-glass')));
    await tester.pump();
    expect(find.text('Enter at least 20 characters.'), findsOneWidget);
    expect(repository.breakGlassCalls, 0);

    const reason =
        'Patient is unconscious and immediate allergy verification is required.';
    await tester.enterText(
      find.byKey(const ValueKey('break-glass-reason')),
      reason,
    );
    await tester.tap(find.byKey(const ValueKey('confirm-break-glass')));
    await tester.pumpAndSettle();

    expect(repository.breakGlassCalls, 1);
    expect(repository.receivedReason, reason);
    expect(find.textContaining('BREAK-GLASS EMERGENCY'), findsOneWidget);
    expect(find.textContaining(reason), findsOneWidget);
  });
}

class _BreakGlassRepository implements AccessRepository {
  int breakGlassCalls = 0;
  String? receivedReason;

  @override
  Future<List<DoctorPatient>> doctorDirectory() async => const [
    DoctorPatient(id: 'profile-id', name: 'Amina Yusuf'),
  ];

  @override
  Future<List<DoctorAccess>> doctorAccess() async => const [];

  @override
  Future<DoctorAccess> breakGlass({
    required String patientProfileId,
    required String reason,
  }) async {
    breakGlassCalls++;
    receivedReason = reason;
    return DoctorAccess(
      id: 'grant-id',
      patientProfileId: patientProfileId,
      patientName: 'Amina Yusuf',
      expiresAt: DateTime(2026, 9, 2, 12, 15),
      accessType: EmergencyAccessKind.breakGlass,
      emergencyReason: reason,
    );
  }

  @override
  Future<DoctorSnapshot> doctorSnapshot(String grantId) async => DoctorSnapshot(
    expiresAt: DateTime(2026, 9, 2, 12, 15),
    profile: sampleProfile,
    accessType: EmergencyAccessKind.breakGlass,
    emergencyReason: receivedReason,
  );

  @override
  Future<PatientAccessDashboard> patientDashboard() =>
      throw UnimplementedError();

  @override
  Future<void> grant({required String doctorEmail, required int minutes}) =>
      throw UnimplementedError();

  @override
  Future<void> revoke(String grantId) => throw UnimplementedError();

  @override
  Future<MedicalQrAccess> issueMedicalQr() => throw UnimplementedError();

  @override
  Future<void> revokeMedicalQr() => throw UnimplementedError();

  @override
  Future<DoctorAccess> redeemMedicalQr(String token) =>
      throw UnimplementedError();

  @override
  Future<AiMedicalSummary> generateAiSummary(String grantId) =>
      throw UnimplementedError();
}
