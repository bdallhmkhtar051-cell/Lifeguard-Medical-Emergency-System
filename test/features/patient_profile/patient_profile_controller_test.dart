import 'package:emergency_system/src/core/network/api_exception.dart';
import 'package:emergency_system/src/features/patient_profile/patient_profile_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

void main() {
  test('loads and saves a versioned profile', () async {
    final repository = FakePatientProfileRepository();
    final controller = PatientProfileController(repository: repository);

    await controller.load();
    final edited = controller.profile!.copyWith(bloodGroup: 'A+');
    final saved = await controller.save(edited);

    expect(saved, isTrue);
    expect(controller.profile?.bloodGroup, 'A+');
    expect(repository.receivedEtag, '"profile-v1"');
    expect(controller.errorMessage, isNull);
  });

  test('turns a stale ETag into an actionable reload message', () async {
    final repository = FakePatientProfileRepository(
      updateError: const ApiException(
        kind: ApiErrorKind.conflict,
        message: 'Precondition failed.',
        statusCode: 412,
      ),
    );
    final controller = PatientProfileController(repository: repository);
    await controller.load();

    final saved = await controller.save(controller.profile!);

    expect(saved, isFalse);
    expect(controller.errorMessage, contains('Reload'));
    expect(controller.profile, isNotNull);
  });

  test('clearSensitiveState removes medical data from memory', () async {
    final controller = PatientProfileController(
      repository: FakePatientProfileRepository(),
    );
    await controller.load();

    controller.clearSensitiveState();

    expect(controller.profile, isNull);
  });
}
