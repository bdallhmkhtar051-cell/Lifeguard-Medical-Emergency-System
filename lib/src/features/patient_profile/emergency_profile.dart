class Allergy {
  const Allergy({
    this.id,
    required this.name,
    this.severity = 'Unknown',
    this.reaction = '',
  });

  factory Allergy.fromJson(Map<String, dynamic> json) => Allergy(
    id: _optionalId(json['id']),
    name: _requiredText(json, 'name'),
    severity: _optionalText(json['severity']).isEmpty
        ? 'Unknown'
        : _optionalText(json['severity']),
    reaction: _optionalText(json['reaction']),
  );

  final String? id;
  final String name;
  final String severity;
  final String reaction;

  Map<String, dynamic> toUpdateJson() => <String, dynamic>{
    'name': name.trim(),
    'severity': severity.trim(),
    'reaction': reaction.trim(),
  };
}

class MedicalCondition {
  const MedicalCondition({this.id, required this.name, this.notes = ''});

  factory MedicalCondition.fromJson(Map<String, dynamic> json) =>
      MedicalCondition(
        id: _optionalId(json['id']),
        name: _requiredText(json, 'name'),
        notes: _optionalText(json['notes']),
      );

  final String? id;
  final String name;
  final String notes;

  Map<String, dynamic> toUpdateJson() => <String, dynamic>{
    'name': name.trim(),
    'notes': notes.trim(),
  };
}

class Medication {
  const Medication({
    this.id,
    required this.name,
    this.dosage = '',
    this.frequency = '',
  });

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
    id: _optionalId(json['id']),
    name: _requiredText(json, 'name'),
    dosage: _optionalText(json['dosage']),
    frequency: _optionalText(json['frequency']),
  );

  final String? id;
  final String name;
  final String dosage;
  final String frequency;

  Map<String, dynamic> toUpdateJson() => <String, dynamic>{
    'name': name.trim(),
    'dosage': dosage.trim(),
    'frequency': frequency.trim(),
  };
}

class EmergencyContact {
  const EmergencyContact({
    this.id,
    required this.name,
    this.relationship = '',
    required this.phoneNumber,
    this.isPrimary = false,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) =>
      EmergencyContact(
        id: _optionalId(json['id']),
        name: _requiredText(json, 'name'),
        relationship: _optionalText(json['relationship']),
        phoneNumber: _requiredText(json, 'phoneNumber'),
        isPrimary: json['isPrimary'] == true,
      );

  final String? id;
  final String name;
  final String relationship;
  final String phoneNumber;
  final bool isPrimary;

  Map<String, dynamic> toUpdateJson() => <String, dynamic>{
    'name': name.trim(),
    'relationship': relationship.trim(),
    'phoneNumber': phoneNumber.trim(),
    'isPrimary': isPrimary,
  };
}

class EmergencyProfile {
  const EmergencyProfile({
    required this.id,
    required this.fullName,
    this.dateOfBirth,
    this.bloodGroup = '',
    this.primaryPhysicianName = '',
    this.primaryPhysicianPhone = '',
    this.insuranceProvider = '',
    this.insurancePolicyNumber = '',
    this.organDonorStatus = 'Unknown',
    this.firstResponderNotes = '',
    this.allergies = const <Allergy>[],
    this.medicalConditions = const <MedicalCondition>[],
    this.medications = const <Medication>[],
    this.emergencyContacts = const <EmergencyContact>[],
    this.updatedAtUtc,
  });

  factory EmergencyProfile.fromJson(Map<String, dynamic> json) {
    return EmergencyProfile(
      id: _requiredText(json, 'id'),
      fullName: _requiredText(json, 'fullName'),
      dateOfBirth: _optionalDate(json['dateOfBirth']),
      bloodGroup: _optionalText(json['bloodGroup']),
      primaryPhysicianName: _optionalText(json['primaryPhysicianName']),
      primaryPhysicianPhone: _optionalText(json['primaryPhysicianPhone']),
      insuranceProvider: _optionalText(json['insuranceProvider']),
      insurancePolicyNumber: _optionalText(json['insurancePolicyNumber']),
      organDonorStatus: _optionalText(json['organDonorStatus']).isEmpty
          ? 'Unknown'
          : _optionalText(json['organDonorStatus']),
      firstResponderNotes: _optionalText(json['firstResponderNotes']),
      allergies: _objects(json['allergies'], Allergy.fromJson),
      medicalConditions: _objects(
        json['medicalConditions'],
        MedicalCondition.fromJson,
      ),
      medications: _objects(json['medications'], Medication.fromJson),
      emergencyContacts: _objects(
        json['emergencyContacts'],
        EmergencyContact.fromJson,
      ),
      updatedAtUtc: _optionalDate(json['updatedAtUtc']),
    );
  }

  final String id;
  final String fullName;
  final DateTime? dateOfBirth;
  final String bloodGroup;
  final String primaryPhysicianName;
  final String primaryPhysicianPhone;
  final String insuranceProvider;
  final String insurancePolicyNumber;
  final String organDonorStatus;
  final String firstResponderNotes;
  final List<Allergy> allergies;
  final List<MedicalCondition> medicalConditions;
  final List<Medication> medications;
  final List<EmergencyContact> emergencyContacts;
  final DateTime? updatedAtUtc;

  EmergencyProfile copyWith({
    String? bloodGroup,
    String? primaryPhysicianName,
    String? primaryPhysicianPhone,
    String? insuranceProvider,
    String? insurancePolicyNumber,
    String? organDonorStatus,
    String? firstResponderNotes,
    List<Allergy>? allergies,
    List<MedicalCondition>? medicalConditions,
    List<Medication>? medications,
    List<EmergencyContact>? emergencyContacts,
  }) {
    return EmergencyProfile(
      id: id,
      fullName: fullName,
      dateOfBirth: dateOfBirth,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      primaryPhysicianName:
          primaryPhysicianName ?? this.primaryPhysicianName,
      primaryPhysicianPhone:
          primaryPhysicianPhone ?? this.primaryPhysicianPhone,
      insuranceProvider: insuranceProvider ?? this.insuranceProvider,
      insurancePolicyNumber:
          insurancePolicyNumber ?? this.insurancePolicyNumber,
      organDonorStatus: organDonorStatus ?? this.organDonorStatus,
      firstResponderNotes: firstResponderNotes ?? this.firstResponderNotes,
      allergies: allergies ?? this.allergies,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      medications: medications ?? this.medications,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      updatedAtUtc: updatedAtUtc,
    );
  }

  /// Child IDs and server-owned timestamps are deliberately omitted. The API
  /// uses a complete replacement document, so read-only identity values are
  /// sent back unchanged.
  Map<String, dynamic> toUpdateJson() => <String, dynamic>{
    'fullName': fullName.trim(),
    'dateOfBirth': dateOfBirth == null ? null : _dateOnly(dateOfBirth!),
    'bloodGroup': bloodGroup.trim(),
    'primaryPhysicianName': _nullableText(primaryPhysicianName),
    'primaryPhysicianPhone': _nullableText(primaryPhysicianPhone),
    'insuranceProvider': _nullableText(insuranceProvider),
    'insurancePolicyNumber': _nullableText(insurancePolicyNumber),
    'organDonorStatus': organDonorStatus,
    'firstResponderNotes': _nullableText(firstResponderNotes),
    'allergies': allergies.map((item) => item.toUpdateJson()).toList(),
    'medicalConditions': medicalConditions
        .map((item) => item.toUpdateJson())
        .toList(),
    'medications': medications.map((item) => item.toUpdateJson()).toList(),
    'emergencyContacts': emergencyContacts
        .map((item) => item.toUpdateJson())
        .toList(),
  };
}

const bloodGroupLabels = <String, String>{
  'Unknown': 'Unknown',
  'APositive': 'A+',
  'ANegative': 'A-',
  'BPositive': 'B+',
  'BNegative': 'B-',
  'ABPositive': 'AB+',
  'ABNegative': 'AB-',
  'OPositive': 'O+',
  'ONegative': 'O-',
};

const organDonorStatusLabels = <String, String>{
  'Unknown': 'Not specified',
  'Donor': 'Registered donor (patient reported)',
  'NotDonor': 'Not a donor (patient reported)',
};

String bloodGroupLabel(String apiValue) =>
    bloodGroupLabels[apiValue] ?? apiValue;

String _dateOnly(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

String? _optionalId(Object? value) => value?.toString().trim();

String _requiredText(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key is missing.');
  }
  return value.trim();
}

String _optionalText(Object? value) =>
    value is String ? value.trim() : value?.toString().trim() ?? '';

String? _nullableText(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

DateTime? _optionalDate(Object? value) {
  if (value == null || value == '') {
    return null;
  }
  if (value is! String) {
    throw const FormatException('Date must be a string.');
  }
  return DateTime.parse(value);
}

List<T> _objects<T>(Object? value, T Function(Map<String, dynamic>) parser) {
  if (value == null) {
    return <T>[];
  }
  if (value is! List) {
    throw const FormatException('Expected a list.');
  }
  return List<T>.unmodifiable(
    value.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Expected an object.');
      }
      return parser(item);
    }),
  );
}
