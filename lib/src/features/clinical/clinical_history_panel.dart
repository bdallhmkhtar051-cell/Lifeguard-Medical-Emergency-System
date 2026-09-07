import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import 'clinical_models.dart';
import 'clinical_repository.dart';

/// Patient-owned, read-only clinical timeline loaded from the API.
class PatientClinicalHistory extends StatefulWidget {
  const PatientClinicalHistory({required this.repository, super.key});

  final ClinicalRepository repository;

  @override
  State<PatientClinicalHistory> createState() => _PatientClinicalHistoryState();
}

class _PatientClinicalHistoryState extends State<PatientClinicalHistory> {
  List<ClinicalEncounter>? _records;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final records = await widget.repository.patientHistory();
      if (mounted) setState(() => _records = records);
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_records == null && _error == null) {
      return const Padding(
        padding: EdgeInsets.all(28),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return ClinicalHistoryPanel(
      records: _records ?? const [],
      error: _error,
      onRefresh: _load,
    );
  }
}

/// Shared timeline used by both portals so doctors and patients see the same data.
class ClinicalHistoryPanel extends StatelessWidget {
  const ClinicalHistoryPanel({
    required this.records,
    this.error,
    this.onRefresh,
    this.onCreate,
    this.busy = false,
    super.key,
  });

  final List<ClinicalEncounter> records;
  final String? error;
  final VoidCallback? onRefresh;
  final VoidCallback? onCreate;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CLINICAL ENCOUNTER TIMELINE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .8,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Vital observations, physician notes and prescriptions',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onRefresh != null)
                      IconButton(
                        tooltip: 'Refresh timeline',
                        onPressed: busy ? null : onRefresh,
                        icon: const Icon(Icons.refresh),
                      ),
                    if (onCreate != null) ...[
                      const SizedBox(width: 6),
                      FilledButton.icon(
                        key: const ValueKey('new-clinical-encounter'),
                        onPressed: busy ? null : onCreate,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('New encounter'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Text(
                  error!,
                  style: const TextStyle(color: Color(0xFF991B1B)),
                ),
              ),
            ],
            const SizedBox(height: 14),
            if (records.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text(
                  'No clinical encounters have been recorded.',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              )
            else
              for (final record in records) _EncounterCard(record: record),
          ],
        ),
      ),
    );
  }
}

class _EncounterCard extends StatelessWidget {
  const _EncounterCard({required this.record});

  final ClinicalEncounter record;

  @override
  Widget build(BuildContext context) {
    final observation = record.observation;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                record.chiefComplaint,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                _dateTime(record.occurredAt),
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${record.doctorName} • ${record.patientName}',
            style: const TextStyle(color: Color(0xFF0F766E), fontSize: 11),
          ),
          const SizedBox(height: 10),
          Text(record.clinicalNotes, style: const TextStyle(fontSize: 12)),
          if (record.disposition != null) ...[
            const SizedBox(height: 7),
            Text(
              'Disposition: ${record.disposition}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ],
          if (observation != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                if (observation.temperatureCelsius != null)
                  _Vital('TEMP', '${observation.temperatureCelsius} °C'),
                if (observation.heartRateBpm != null)
                  _Vital('HR', '${observation.heartRateBpm} bpm'),
                if (observation.systolicBloodPressure != null ||
                    observation.diastolicBloodPressure != null)
                  _Vital(
                    'BP',
                    '${observation.systolicBloodPressure ?? '-'}'
                        '/${observation.diastolicBloodPressure ?? '-'}',
                  ),
                if (observation.oxygenSaturationPercent != null)
                  _Vital('SPO₂', '${observation.oxygenSaturationPercent}%'),
                if (observation.respiratoryRatePerMinute != null)
                  _Vital('RR', '${observation.respiratoryRatePerMinute}/min'),
              ],
            ),
          ],
          if (record.prescriptions.isNotEmpty) ...[
            const Divider(height: 24),
            const Text(
              'PRESCRIPTIONS',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
            ),
            for (final item in record.prescriptions)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${item.medicationName} • ${item.dosage} • '
                  '${item.frequency} • ${item.duration}'
                  '${item.instructions == null ? '' : ' — ${item.instructions}'}',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Vital extends StatelessWidget {
  const _Vital(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFECFDF5),
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: const Color(0xFFA7F3D0)),
    ),
    child: Text(
      '$label  $value',
      style: const TextStyle(
        color: Color(0xFF065F46),
        fontSize: 10,
        fontWeight: FontWeight.w900,
        fontFamily: 'monospace',
      ),
    ),
  );
}

String clinicalErrorMessage(Object error) => _message(error);

String _message(Object error) => error is ApiException
    ? error.message
    : 'The clinical history is unavailable.';

String _dateTime(DateTime value) {
  final date = value.toLocal();
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.year}-$month-$day ${date.hour}:$minute';
}
