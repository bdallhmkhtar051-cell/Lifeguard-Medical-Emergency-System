import 'package:flutter/material.dart';

import 'clinical_models.dart';

/// Collects one encounter. The server repeats all validation before saving.
class ClinicalEncounterDialog extends StatefulWidget {
  const ClinicalEncounterDialog({required this.patientName, super.key});

  final String patientName;

  @override
  State<ClinicalEncounterDialog> createState() =>
      _ClinicalEncounterDialogState();
}

class _ClinicalEncounterDialogState extends State<ClinicalEncounterDialog> {
  final _formKey = GlobalKey<FormState>();
  final _complaint = TextEditingController();
  final _notes = TextEditingController();
  final _disposition = TextEditingController();
  final _temperature = TextEditingController();
  final _heartRate = TextEditingController();
  final _systolic = TextEditingController();
  final _diastolic = TextEditingController();
  final _oxygen = TextEditingController();
  final _respiratoryRate = TextEditingController();
  final _medication = TextEditingController();
  final _dosage = TextEditingController();
  final _frequency = TextEditingController();
  final _duration = TextEditingController();
  final _instructions = TextEditingController();

  List<TextEditingController> get _controllers => [
    _complaint,
    _notes,
    _disposition,
    _temperature,
    _heartRate,
    _systolic,
    _diastolic,
    _oxygen,
    _respiratoryRate,
    _medication,
    _dosage,
    _frequency,
    _duration,
    _instructions,
  ];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('New clinical encounter'),
          const SizedBox(height: 3),
          Text(
            widget.patientName,
            style: const TextStyle(
              color: Color(0xFF0F766E),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 720,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SectionLabel('ENCOUNTER NOTES'),
                TextFormField(
                  key: const ValueKey('chief-complaint'),
                  controller: _complaint,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    labelText: 'Chief complaint *',
                    hintText: 'Example: Shortness of breath',
                  ),
                  validator: (value) => _required(value, 3),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  key: const ValueKey('clinical-notes'),
                  controller: _notes,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                    labelText: 'Clinical assessment and treatment *',
                  ),
                  validator: (value) => _required(value, 3),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _disposition,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    labelText: 'Disposition',
                    hintText: 'Example: Discharged with follow-up',
                  ),
                ),
                const SizedBox(height: 14),
                const _SectionLabel('VITAL OBSERVATIONS (OPTIONAL)'),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _vital(
                      controller: _temperature,
                      label: 'Temperature °C',
                      minimum: 25,
                      maximum: 45,
                      decimal: true,
                    ),
                    _vital(
                      controller: _heartRate,
                      label: 'Heart rate bpm',
                      minimum: 20,
                      maximum: 250,
                    ),
                    _vital(
                      controller: _systolic,
                      label: 'Systolic BP',
                      minimum: 40,
                      maximum: 300,
                    ),
                    _vital(
                      controller: _diastolic,
                      label: 'Diastolic BP',
                      minimum: 20,
                      maximum: 200,
                    ),
                    _vital(
                      controller: _oxygen,
                      label: 'Oxygen %',
                      minimum: 50,
                      maximum: 100,
                    ),
                    _vital(
                      controller: _respiratoryRate,
                      label: 'Respiratory rate',
                      minimum: 4,
                      maximum: 80,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const _SectionLabel('PRESCRIPTION (OPTIONAL)'),
                const Text(
                  'Leave medication blank when no prescription is required.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _prescriptionField(_medication, 'Medication'),
                    _prescriptionField(_dosage, 'Dosage'),
                    _prescriptionField(_frequency, 'Frequency'),
                    _prescriptionField(_duration, 'Duration'),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _instructions,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Prescription instructions',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          key: const ValueKey('save-clinical-encounter'),
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0F766E),
          ),
          icon: const Icon(Icons.save_outlined, size: 18),
          label: const Text('Save encounter'),
        ),
      ],
    );
  }

  Widget _vital({
    required TextEditingController controller,
    required String label,
    required num minimum,
    required num maximum,
    bool decimal = false,
  }) => SizedBox(
    width: 210,
    child: TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      decoration: InputDecoration(labelText: label),
      validator: (value) => _number(value, minimum, maximum),
    ),
  );

  Widget _prescriptionField(TextEditingController controller, String label) =>
      SizedBox(
        width: 210,
        child: TextFormField(
          controller: controller,
          maxLength: 100,
          decoration: InputDecoration(labelText: label),
          validator: (value) {
            if (!_hasPrescription) return null;
            return value == null || value.trim().isEmpty
                ? '$label is required for a prescription.'
                : null;
          },
        ),
      );

  bool get _hasPrescription => [
    _medication,
    _dosage,
    _frequency,
    _duration,
    _instructions,
  ].any((controller) => controller.text.trim().isNotEmpty);

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final systolic = _int(_systolic);
    final diastolic = _int(_diastolic);
    if (systolic != null && diastolic != null && systolic <= diastolic) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Systolic pressure must be higher than diastolic pressure.',
          ),
        ),
      );
      return;
    }

    final observation = ClinicalObservation(
      temperatureCelsius: _double(_temperature),
      heartRateBpm: _int(_heartRate),
      systolicBloodPressure: systolic,
      diastolicBloodPressure: diastolic,
      oxygenSaturationPercent: _int(_oxygen),
      respiratoryRatePerMinute: _int(_respiratoryRate),
    );
    final hasVitals = _controllers
        .sublist(3, 9)
        .any((controller) => controller.text.trim().isNotEmpty);
    final prescriptions = _hasPrescription
        ? [
            ClinicalPrescription(
              medicationName: _medication.text.trim(),
              dosage: _dosage.text.trim(),
              frequency: _frequency.text.trim(),
              duration: _duration.text.trim(),
              instructions: _clean(_instructions.text),
            ),
          ]
        : <ClinicalPrescription>[];

    Navigator.pop(
      context,
      ClinicalEncounterDraft(
        chiefComplaint: _complaint.text.trim(),
        clinicalNotes: _notes.text.trim(),
        disposition: _clean(_disposition.text),
        observation: hasVitals ? observation : null,
        prescriptions: prescriptions,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        color: Color(0xFF0F766E),
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: .7,
      ),
    ),
  );
}

String? _required(String? value, int minimum) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'This field is required.';
  return text.length < minimum ? 'Enter at least $minimum characters.' : null;
}

String? _number(String? value, num minimum, num maximum) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  final number = num.tryParse(text);
  if (number == null) return 'Enter a number.';
  return number < minimum || number > maximum ? 'Use $minimum–$maximum.' : null;
}

int? _int(TextEditingController controller) =>
    int.tryParse(controller.text.trim());

double? _double(TextEditingController controller) =>
    double.tryParse(controller.text.trim());

String? _clean(String value) => value.trim().isEmpty ? null : value.trim();
