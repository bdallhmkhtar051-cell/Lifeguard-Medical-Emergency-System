import 'package:emergency_system/src/features/clinical/clinical_history_panel.dart';
import 'package:emergency_system/src/features/clinical/clinical_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('clinical timeline shows vitals, notes, and prescriptions', (
    tester,
  ) async {
    final record = ClinicalEncounter(
      id: 'encounter-id',
      patientName: 'Amina Yusuf',
      doctorName: 'Dr. Ali Hassan',
      chiefComplaint: 'Shortness of breath',
      clinicalNotes: 'Patient stabilized after emergency treatment.',
      disposition: 'Discharged with follow-up',
      occurredAt: DateTime.utc(2026, 9, 5, 12),
      createdAt: DateTime.utc(2026, 9, 5, 12),
      observation: const ClinicalObservation(
        temperatureCelsius: 37.2,
        heartRateBpm: 92,
        oxygenSaturationPercent: 97,
      ),
      prescriptions: const [
        ClinicalPrescription(
          medicationName: 'Salbutamol',
          dosage: '100 mcg',
          frequency: 'As needed',
          duration: '7 days',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ClinicalHistoryPanel(records: [record]),
          ),
        ),
      ),
    );

    expect(find.text('Shortness of breath'), findsOneWidget);
    expect(find.textContaining('97%'), findsOneWidget);
    expect(find.textContaining('Salbutamol'), findsOneWidget);
    expect(find.textContaining('Dr. Ali Hassan'), findsOneWidget);
  });
}
