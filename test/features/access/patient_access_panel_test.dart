import 'package:emergency_system/src/features/access/access_models.dart';
import 'package:emergency_system/src/features/access/patient_access_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

void main() {
  testWidgets('access grants are collapsed so history stays close', (
    tester,
  ) async {
    final dashboard = PatientAccessDashboard(
      doctors: const [
        DoctorOption(
          id: 'doctor-id',
          name: 'Dr. Ali Hassan',
          email: 'doctor@example.test',
        ),
      ],
      grants: [
        AccessGrant(
          id: 'active-grant',
          doctorName: 'Dr. Active Grant',
          doctorEmail: 'active@example.test',
          expiresAt: DateTime(2026, 9, 21, 12),
          active: true,
          accessType: EmergencyAccessKind.consented,
        ),
        AccessGrant(
          id: 'old-grant',
          doctorName: 'Dr. Previous Grant',
          doctorEmail: 'previous@example.test',
          expiresAt: DateTime(2026, 9, 20, 12),
          active: false,
          accessType: EmergencyAccessKind.breakGlass,
          emergencyReason: 'Synthetic emergency demonstration reason.',
        ),
      ],
      audit: [
        AccessAudit(
          actor: 'Dr. Audit Example',
          action: 'Viewed',
          time: DateTime(2026, 9, 21, 10),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PatientAccessPanel(
              repository: FakeAccessRepository(
                patientAccessDashboard: dashboard,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 recorded events'), findsOneWidget);
    expect(find.text('1 active • 2 total'), findsOneWidget);
    expect(find.text('Dr. Active Grant'), findsNothing);
    expect(find.text('Viewed by Dr. Audit Example'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('patient-access-history-section')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Viewed by Dr. Audit Example'), findsOneWidget);
    expect(find.text('Dr. Active Grant'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('patient-access-grants-section')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Dr. Active Grant'), findsOneWidget);
    expect(find.text('Dr. Previous Grant'), findsOneWidget);
  });
}
