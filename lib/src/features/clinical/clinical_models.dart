class ClinicalEncounter {
  const ClinicalEncounter({
    required this.id,
    required this.patientName,
    required this.doctorName,
    required this.chiefComplaint,
    required this.clinicalNotes,
    required this.occurredAt,
    required this.createdAt,
    required this.prescriptions,
    this.disposition,
    this.observation,
  });

  factory ClinicalEncounter.fromJson(Map<String, dynamic> json) =>
      ClinicalEncounter(
        id: json['id'].toString(),
        patientName: json['patientName'].toString(),
        doctorName: json['doctorName'].toString(),
        chiefComplaint: json['chiefComplaint'].toString(),
        clinicalNotes: json['clinicalNotes'].toString(),
        disposition: _optional(json['disposition']),
        occurredAt: DateTime.parse(json['occurredAtUtc'].toString()),
        createdAt: DateTime.parse(json['createdAtUtc'].toString()),
        observation: json['observation'] is Map<String, dynamic>
            ? ClinicalObservation.fromJson(
                json['observation'] as Map<String, dynamic>,
              )
            : null,
        prescriptions: (json['prescriptions'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(ClinicalPrescription.fromJson)
            .toList(),
      );

  final String id;
  final String patientName;
  final String doctorName;
  final String chiefComplaint;
  final String clinicalNotes;
  final String? disposition;
  final DateTime occurredAt;
  final DateTime createdAt;
  final ClinicalObservation? observation;
  final List<ClinicalPrescription> prescriptions;
}

class ClinicalObservation {
  const ClinicalObservation({
    this.temperatureCelsius,
    this.heartRateBpm,
    this.systolicBloodPressure,
    this.diastolicBloodPressure,
    this.oxygenSaturationPercent,
    this.respiratoryRatePerMinute,
  });

  factory ClinicalObservation.fromJson(Map<String, dynamic> json) =>
      ClinicalObservation(
        temperatureCelsius: _decimal(json['temperatureCelsius']),
        heartRateBpm: _integer(json['heartRateBpm']),
        systolicBloodPressure: _integer(json['systolicBloodPressure']),
        diastolicBloodPressure: _integer(json['diastolicBloodPressure']),
        oxygenSaturationPercent: _integer(json['oxygenSaturationPercent']),
        respiratoryRatePerMinute: _integer(json['respiratoryRatePerMinute']),
      );

  final double? temperatureCelsius;
  final int? heartRateBpm;
  final int? systolicBloodPressure;
  final int? diastolicBloodPressure;
  final int? oxygenSaturationPercent;
  final int? respiratoryRatePerMinute;

  Map<String, dynamic> toJson() => {
    'temperatureCelsius': temperatureCelsius,
    'heartRateBpm': heartRateBpm,
    'systolicBloodPressure': systolicBloodPressure,
    'diastolicBloodPressure': diastolicBloodPressure,
    'oxygenSaturationPercent': oxygenSaturationPercent,
    'respiratoryRatePerMinute': respiratoryRatePerMinute,
  };
}

class ClinicalPrescription {
  const ClinicalPrescription({
    required this.medicationName,
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.instructions,
  });

  factory ClinicalPrescription.fromJson(Map<String, dynamic> json) =>
      ClinicalPrescription(
        medicationName: json['medicationName'].toString(),
        dosage: json['dosage'].toString(),
        frequency: json['frequency'].toString(),
        duration: json['duration'].toString(),
        instructions: _optional(json['instructions']),
      );

  final String medicationName;
  final String dosage;
  final String frequency;
  final String duration;
  final String? instructions;

  Map<String, dynamic> toJson() => {
    'medicationName': medicationName,
    'dosage': dosage,
    'frequency': frequency,
    'duration': duration,
    'instructions': instructions,
  };
}

class ClinicalEncounterDraft {
  const ClinicalEncounterDraft({
    required this.chiefComplaint,
    required this.clinicalNotes,
    required this.disposition,
    required this.observation,
    required this.prescriptions,
  });

  final String chiefComplaint;
  final String clinicalNotes;
  final String? disposition;
  final ClinicalObservation? observation;
  final List<ClinicalPrescription> prescriptions;

  Map<String, dynamic> toJson() => {
    'chiefComplaint': chiefComplaint,
    'clinicalNotes': clinicalNotes,
    'disposition': disposition,
    'occurredAtUtc': DateTime.now().toUtc().toIso8601String(),
    'observation': observation?.toJson(),
    'prescriptions': prescriptions.map((item) => item.toJson()).toList(),
  };
}

String? _optional(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

double? _decimal(Object? value) =>
    value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '');

int? _integer(Object? value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');
