import 'package:emergency_system/src/features/patient_profile/emergency_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a complete emergency profile', () {
    final profile = EmergencyProfile.fromJson({
      'id': 'profile-id',
      'fullName': 'Amina Yusuf',
      'dateOfBirth': '1997-04-12',
      'bloodGroup': 'OPositive',
      'primaryPhysicianName': 'Dr. Fadumo Abdi',
      'primaryPhysicianPhone': '+252612345670',
      'insuranceProvider': 'LifeGuard Demo Health',
      'insurancePolicyNumber': 'DEMO-2026-001',
      'organDonorStatus': 'Donor',
      'firstResponderNotes': 'Carries a prescribed rescue inhaler.',
      'allergies': [
        {
          'id': 'allergy-id',
          'name': 'Penicillin',
          'severity': 'Severe',
          'reaction': 'Anaphylaxis',
        },
      ],
      'medicalConditions': [
        {'id': 'condition-id', 'name': 'Asthma', 'notes': 'Controlled'},
      ],
      'medications': [
        {
          'id': 'medication-id',
          'name': 'Salbutamol',
          'dosage': '100 mcg',
          'frequency': 'As needed',
        },
      ],
      'emergencyContacts': [
        {
          'id': 'contact-id',
          'name': 'Hodan Yusuf',
          'relationship': 'Sister',
          'phoneNumber': '+252 61 0000000',
          'isPrimary': true,
        },
      ],
      'updatedAtUtc': '2026-07-28T12:00:00Z',
    });

    expect(profile.id, 'profile-id');
    expect(profile.allergies.single.reaction, 'Anaphylaxis');
    expect(profile.emergencyContacts.single.isPrimary, isTrue);
    expect(profile.primaryPhysicianName, 'Dr. Fadumo Abdi');
    expect(profile.organDonorStatus, 'Donor');
    expect(profile.firstResponderNotes, contains('rescue inhaler'));
    expect(profile.updatedAtUtc?.isUtc, isTrue);
  });

  test('update JSON omits IDs but includes unchanged replacement identity', () {
    final profile = EmergencyProfile.fromJson({
      'id': 'profile-id',
      'fullName': 'Amina Yusuf',
      'dateOfBirth': '1997-04-12',
      'bloodGroup': 'OPositive',
      'allergies': [
        {'id': 'allergy-id', 'name': 'Penicillin'},
      ],
      'medicalConditions': [],
      'medications': [],
      'emergencyContacts': [],
    });

    final update = profile.toUpdateJson();

    expect(update, isNot(contains('id')));
    expect(update['fullName'], 'Amina Yusuf');
    expect(update['dateOfBirth'], '1997-04-12');
    expect(update['organDonorStatus'], 'Unknown');
    expect(update['primaryPhysicianName'], isNull);
    expect(update['allergies'], [
      {'name': 'Penicillin', 'severity': 'Unknown', 'reaction': ''},
    ]);
  });

  test('missing optional arrays become empty collections', () {
    final profile = EmergencyProfile.fromJson({
      'id': 'profile-id',
      'fullName': 'Amina Yusuf',
    });

    expect(profile.allergies, isEmpty);
    expect(profile.medicalConditions, isEmpty);
    expect(profile.medications, isEmpty);
    expect(profile.emergencyContacts, isEmpty);
    expect(profile.organDonorStatus, 'Unknown');
    expect(profile.firstResponderNotes, isEmpty);
  });
}
