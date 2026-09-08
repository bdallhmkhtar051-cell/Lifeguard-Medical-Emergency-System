import 'package:emergency_system/src/app/app_controller.dart';
import 'package:emergency_system/src/app/emergency_system_app.dart';
import 'package:emergency_system/src/core/network/api_client.dart';
import 'package:emergency_system/src/features/auth/session_controller.dart';
import 'package:emergency_system/src/features/patient_profile/patient_profile_page.dart';
import 'package:emergency_system/src/features/administration/administration_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../helpers/fakes.dart';

void main() {
  testWidgets('offline health failure has a working retry path', (
    tester,
  ) async {
    final health = FakeHealthRepository(error: http.ClientException('offline'));
    final harness = await _Harness.create(health: health);

    await tester.pumpWidget(harness.app);
    expect(find.byKey(const ValueKey('offline-panel')), findsOneWidget);

    health.error = null;
    await tester.tap(find.byKey(const ValueKey('retry-button')));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(health.checks, 2);
  });

  testWidgets('login validates input and reports rejected credentials', (
    tester,
  ) async {
    final auth = FakeAuthRepository(loginError: invalidCredentials);
    final harness = await _Harness.create(auth: auth);
    await tester.pumpWidget(harness.app);

    await tester.tap(find.byKey(const ValueKey('login-button')));
    await tester.pump();
    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('email-field')),
      'patient@example.test',
    );
    await tester.enterText(
      find.byKey(const ValueKey('password-field')),
      'incorrect',
    );
    await tester.tap(find.byKey(const ValueKey('login-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('login-error')), findsOneWidget);
    expect(find.text('The email or password is incorrect.'), findsOneWidget);
  });

  testWidgets('login remains usable at a narrow mobile browser width', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 760);
    addTearDown(tester.view.reset);
    final harness = await _Harness.create();

    await tester.pumpWidget(harness.app);

    expect(find.text('Welcome back'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('doctor role never receives the patient profile editor', (
    tester,
  ) async {
    final auth = FakeAuthRepository(user: sampleDoctor);
    final harness = await _Harness.create(auth: auth, authenticate: true);

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(find.text('Doctor workspace'), findsOneWidget);
    expect(find.byType(PatientProfilePage), findsNothing);
    expect(find.byKey(const ValueKey('edit-profile-button')), findsNothing);
  });

  testWidgets('patient can view, edit, save, and then sign out', (
    tester,
  ) async {
    final profiles = FakePatientProfileRepository();
    final harness = await _Harness.create(
      profile: profiles,
      authenticate: true,
    );

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();
    expect(find.text('Penicillin'), findsOneWidget);
    // The dashboard intentionally repeats the critical blood group in both the
    // Medical ID header and the detailed emergency-summary card.
    expect(find.text('O+'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('edit-profile-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('blood-group-field')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('save-profile-button')));
    await tester.pumpAndSettle();
    expect(profiles.updateCalls, 1);
    expect(find.text('Emergency profile saved.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('logout-button')));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('administrator can review users and deactivate an account', (
    tester,
  ) async {
    final auth = FakeAuthRepository(user: sampleAdministrator);
    final administration = FakeAdministrationRepository();
    final harness = await _Harness.create(
      auth: auth,
      administration: administration,
      authenticate: true,
    );

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(find.byType(AdministrationPage), findsOneWidget);
    expect(find.text('System administration'), findsOneWidget);
    expect(find.text(sampleDoctor.displayName), findsOneWidget);

    await tester.tap(find.byKey(ValueKey('toggle-user-${sampleDoctor.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-status-change')));
    await tester.pumpAndSettle();

    expect(administration.changedUserId, sampleDoctor.id);
    expect(
      find.text('${sampleDoctor.displayName} was deactivated'),
      findsOneWidget,
    );
  });
}

class _Harness {
  const _Harness({
    required this.appController,
    required this.sessionController,
    required this.profileRepository,
    required this.administrationRepository,
  });

  static Future<_Harness> create({
    FakeHealthRepository? health,
    FakeAuthRepository? auth,
    FakePatientProfileRepository? profile,
    FakeAdministrationRepository? administration,
    bool authenticate = false,
  }) async {
    final appController = AppController(
      healthRepository: health ?? FakeHealthRepository(),
    );
    await appController.bootstrap();
    final apiClient = ApiClient(
      baseUri: Uri.parse('http://localhost:5080'),
      client: MockClient((_) async => http.Response('', 204)),
    );
    final sessionController = SessionController(
      repository: auth ?? FakeAuthRepository(),
      apiClient: apiClient,
    );
    apiClient.onUnauthorized = sessionController.expireSession;
    if (authenticate) {
      await sessionController.login(
        email: 'user@example.test',
        password: 'correct',
      );
    }
    return _Harness(
      appController: appController,
      sessionController: sessionController,
      profileRepository: profile ?? FakePatientProfileRepository(),
      administrationRepository:
          administration ?? FakeAdministrationRepository(),
    );
  }

  final AppController appController;
  final SessionController sessionController;
  final FakePatientProfileRepository profileRepository;
  final FakeAdministrationRepository administrationRepository;

  Widget get app => EmergencySystemApp(
    appController: appController,
    sessionController: sessionController,
    patientProfileRepository: profileRepository,
    accessRepository: FakeAccessRepository(),
    clinicalRepository: FakeClinicalRepository(),
    administrationRepository: administrationRepository,
    documentRepository: FakeDocumentRepository(),
  );
}
