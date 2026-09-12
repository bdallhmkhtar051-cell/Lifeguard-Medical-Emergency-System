import 'package:flutter/material.dart';

import '../../core/platform/browser_print.dart';
import 'emergency_profile.dart';

/// A presentation and printing view of the profile already loaded from the
/// API. It does not change, clinically verify, or send the record elsewhere.
class MedicalSummaryDialog extends StatelessWidget {
  const MedicalSummaryDialog({required this.profile, super.key});

  final EmergencyProfile profile;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 760),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 10, 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.description_outlined,
                    color: Color(0xFF0F766E),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'LifeGuard emergency summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _SummarySheet(profile: profile),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Wrap(
                spacing: 10,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  FilledButton.icon(
                    key: const ValueKey('print-medical-summary'),
                    onPressed: () {
                      if (!printCurrentPage()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Printing is available in the web application.',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('Print / Save PDF'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummarySheet extends StatelessWidget {
  const _SummarySheet({required this.profile});

  final EmergencyProfile profile;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('medical-summary-sheet'),
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFCBD5E1)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'LIFEGUARD MEDICAL ID',
          style: TextStyle(
            color: Color(0xFF0F766E),
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          profile.fullName,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        Text(
          'Patient ID: ${profile.id}',
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 14),
        _Warning(
          text:
              'Patient-reported information from the current stored record. Confirm identity, accuracy, allergies, medications and directives before clinical use.',
        ),
        const SizedBox(height: 18),
        _Fields(
          values: {
            'Date of birth': profile.dateOfBirth == null
                ? 'Not recorded'
                : _date(profile.dateOfBirth!),
            'Blood group': bloodGroupLabel(profile.bloodGroup),
            'Organ donor':
                organDonorStatusLabels[profile.organDonorStatus] ??
                profile.organDonorStatus,
            'Last updated': profile.updatedAtUtc == null
                ? 'Not recorded'
                : _dateTime(profile.updatedAtUtc!),
            'Primary physician': _orMissing(profile.primaryPhysicianName),
            'Physician phone': _orMissing(profile.primaryPhysicianPhone),
            'Insurance provider': _orMissing(profile.insuranceProvider),
            'Policy / member number': _orMissing(profile.insurancePolicyNumber),
          },
        ),
        const SizedBox(height: 18),
        _ListSection(
          title: 'ALLERGIES',
          emptyText: 'No allergies recorded',
          values: profile.allergies
              .map(
                (item) =>
                    '${item.name} — ${item.severity}${item.reaction.isEmpty ? '' : ' (${item.reaction})'}',
              )
              .toList(),
        ),
        _ListSection(
          title: 'CURRENT MEDICATIONS',
          emptyText: 'No medications recorded',
          values: profile.medications
              .map(
                (item) =>
                    '${item.name}${item.dosage.isEmpty ? '' : ' — ${item.dosage}'}${item.frequency.isEmpty ? '' : ', ${item.frequency}'}',
              )
              .toList(),
        ),
        _ListSection(
          title: 'MEDICAL CONDITIONS',
          emptyText: 'No conditions recorded',
          values: profile.medicalConditions
              .map(
                (item) =>
                    '${item.name}${item.notes.isEmpty ? '' : ' — ${item.notes}'}',
              )
              .toList(),
        ),
        _ListSection(
          title: 'EMERGENCY CONTACTS',
          emptyText: 'No contacts recorded',
          values: profile.emergencyContacts
              .map(
                (item) =>
                    '${item.name} (${_orMissing(item.relationship)}) — ${item.phoneNumber}${item.isPrimary ? ' • PRIMARY' : ''}',
              )
              .toList(),
        ),
        const SizedBox(height: 4),
        const Text(
          'FIRST-RESPONDER NOTES',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: .8,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          _orMissing(profile.firstResponderNotes),
          style: const TextStyle(height: 1.4),
        ),
      ],
    ),
  );
}

class _Warning extends StatelessWidget {
  const _Warning({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    color: const Color(0xFFFFFBEB),
    child: Text(
      text,
      style: const TextStyle(
        color: Color(0xFF78350F),
        fontSize: 11,
        height: 1.4,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _Fields extends StatelessWidget {
  const _Fields({required this.values});
  final Map<String, String> values;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth >= 600
          ? (constraints.maxWidth - 16) / 2
          : constraints.maxWidth;
      return Wrap(
        spacing: 16,
        runSpacing: 12,
        children: values.entries
            .map(
              (entry) => SizedBox(
                width: width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.value,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      );
    },
  );
}

class _ListSection extends StatelessWidget {
  const _ListSection({
    required this.title,
    required this.emptyText,
    required this.values,
  });
  final String title;
  final String emptyText;
  final List<String> values;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: .8,
          ),
        ),
        const SizedBox(height: 5),
        if (values.isEmpty)
          Text(emptyText, style: const TextStyle(color: Color(0xFF64748B)))
        else
          for (final value in values)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $value'),
            ),
      ],
    ),
  );
}

String _orMissing(String value) =>
    value.trim().isEmpty ? 'Not recorded' : value;
String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
String _dateTime(DateTime value) =>
    '${_date(value.toLocal())} ${value.toLocal().hour.toString().padLeft(2, '0')}:${value.toLocal().minute.toString().padLeft(2, '0')}';
