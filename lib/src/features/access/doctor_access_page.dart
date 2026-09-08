import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../auth/auth_models.dart';
import '../patient_profile/emergency_profile.dart';
import '../clinical/clinical_encounter_dialog.dart';
import '../clinical/clinical_history_panel.dart';
import '../clinical/clinical_models.dart';
import '../clinical/clinical_repository.dart';
import 'access_models.dart';
import 'access_repository.dart';
import 'ai_medical_summary_dialog.dart';
import 'medical_qr_scanner_dialog.dart';

class DoctorAccessPage extends StatefulWidget {
  const DoctorAccessPage({
    required this.repository,
    required this.clinicalRepository,
    required this.user,
    this.initialMedicalQrToken,
    this.scannerBuilder,
    this.scannerExpectedBaseUri,
    super.key,
  });

  final AccessRepository repository;
  final ClinicalRepository clinicalRepository;
  final AppUser user;
  final String? initialMedicalQrToken;
  final MedicalQrScannerViewBuilder? scannerBuilder;
  final Uri? scannerExpectedBaseUri;

  @override
  State<DoctorAccessPage> createState() => _DoctorAccessPageState();
}

class _DoctorAccessPageState extends State<DoctorAccessPage> {
  List<DoctorAccess>? _access;
  List<DoctorPatient>? _patients;
  DoctorSnapshot? _snapshot;
  List<ClinicalEncounter> _clinicalRecords = const [];
  DoctorAccess? _selectedAccess;
  String? _error;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    await _load();
    final token = widget.initialMedicalQrToken?.trim();
    if (mounted && token != null && token.isNotEmpty) {
      await _redeemMedicalQr(token);
    }
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final results = await Future.wait<Object>([
        widget.repository.doctorAccess(),
        widget.repository.doctorDirectory(),
      ]);
      if (mounted) {
        setState(() {
          _access = results[0] as List<DoctorAccess>;
          _patients = results[1] as List<DoctorPatient>;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(DoctorAccess access) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final results = await Future.wait<Object>([
        widget.repository.doctorSnapshot(access.id),
        widget.clinicalRepository.doctorHistory(access.id),
      ]);
      if (mounted) {
        setState(() {
          _snapshot = results[0] as DoctorSnapshot;
          _clinicalRecords = results[1] as List<ClinicalEncounter>;
          _selectedAccess = access;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createEncounter() async {
    final access = _selectedAccess;
    final snapshot = _snapshot;
    if (access == null || snapshot == null) return;
    final draft = await showDialog<ClinicalEncounterDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          ClinicalEncounterDialog(patientName: snapshot.profile.fullName),
    );
    if (draft == null || !mounted) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final record = await widget.clinicalRepository.createEncounter(
        access.id,
        draft,
      );
      if (mounted) {
        setState(() => _clinicalRecords = [record, ..._clinicalRecords]);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clinical encounter saved and audited.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _generateAiSummary() async {
    final access = _selectedAccess;
    if (access == null) return;
    AiMedicalSummary? summary;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      summary = await widget.repository.generateAiSummary(access.id);
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (summary != null && mounted) {
      await showDialog<void>(
        context: context,
        builder: (_) => AiMedicalSummaryDialog(summary: summary!),
      );
    }
  }

  Future<void> _breakGlass(DoctorPatient patient) async {
    final reason = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _BreakGlassDialog(patient: patient),
    );
    if (reason == null || !mounted) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final access = await widget.repository.breakGlass(
        patientProfileId: patient.id,
        reason: reason,
      );
      if (mounted) await _open(access);
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _redeemMedicalQr(String token) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final access = await widget.repository.redeemMedicalQr(token);
      if (!mounted) return;
      await _open(access);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Medical ID QR accepted. Access is active for 15 minutes.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error is ApiException && error.statusCode == 404
              ? 'This Medical ID QR has expired, was revoked, or was already used.'
              : _message(error);
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _scanMedicalQr() async {
    final token = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => MedicalQrScannerDialog(
        scannerBuilder: widget.scannerBuilder,
        expectedBaseUri: widget.scannerExpectedBaseUri,
      ),
    );
    if (token != null && mounted) await _redeemMedicalQr(token);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 48),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ClinicianCredential(
                  user: widget.user,
                  patientCount: _access?.length ?? 0,
                  busy: _busy,
                  onRefresh: _load,
                  onScanMedicalQr: _scanMedicalQr,
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: _ErrorBanner(message: _error!),
                  ),
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (_snapshot case final snapshot?) ...[
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() {
                        _snapshot = null;
                        _selectedAccess = null;
                        _clinicalRecords = const [];
                      }),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Authorized patients'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ClinicalSnapshot(
                    snapshot: snapshot,
                    clinicalRecords: _clinicalRecords,
                    busy: _busy,
                    onCreateEncounter: _createEncounter,
                    onGenerateAiSummary: _generateAiSummary,
                  ),
                ] else if ((_access, _patients) case (
                  final access?,
                  final patients?,
                )) ...[
                  const SizedBox(height: 18),
                  _PatientDirectory(
                    patients: patients,
                    access: access,
                    busy: _busy,
                    onOpen: _open,
                    onBreakGlass: _breakGlass,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Teal counterpart of the patient's blue digital Medical ID card.
class _ClinicianCredential extends StatelessWidget {
  const _ClinicianCredential({
    required this.user,
    required this.patientCount,
    required this.busy,
    required this.onRefresh,
    required this.onScanMedicalQr,
  });

  final AppUser user;
  final int patientCount;
  final bool busy;
  final VoidCallback onRefresh;
  final VoidCallback onScanMedicalQr;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF042F2E), Color(0xFF0F172A), Color(0xFF020617)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x664E9F97)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330F172A),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned(
            right: 12,
            top: 22,
            child: Icon(
              Icons.medical_services_outlined,
              size: 148,
              color: Color(0x102CCFC0),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.circle,
                      color: Color(0xFF2DD4BF),
                      size: 10,
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.medical_services_outlined,
                      color: Color(0xFF99F6E4),
                      size: 17,
                    ),
                    const SizedBox(width: 7),
                    const Expanded(
                      child: Text(
                        'LIFEGUARD ID • CLINICAL PHYSICIAN CREDENTIAL',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .7,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh access',
                      onPressed: busy ? null : onRefresh,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white10,
                      ),
                      icon: const Icon(Icons.refresh, color: Color(0xFFCCFBF1)),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFF334155), height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF14B8A6), Color(0xFF0F766E)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0x6645E6D1)),
                          ),
                          child: Text(
                            _initials(user.displayName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Doctor workspace',
                              style: TextStyle(
                                color: Color(0xFF5EEAD4),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .8,
                              ),
                            ),
                            Text(
                              user.displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              user.email,
                              style: const TextStyle(
                                color: Color(0xFFCBD5E1),
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF042F2E),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF115E59)),
                      ),
                      child: const Text(
                        'SECURE EHR NODE',
                        style: TextStyle(
                          color: Color(0xFF5EEAD4),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        label: 'Authorized patients',
                        value: '$patientCount',
                        color: const Color(0xFF5EEAD4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: _Metric(
                        label: 'Clinical mode',
                        value: 'READ + DOCUMENT',
                        color: Color(0xFF60A5FA),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: _Metric(
                        label: 'Audit status',
                        value: 'ACTIVE',
                        color: Color(0xFF34D399),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    key: const ValueKey('scan-medical-qr-button'),
                    onPressed: busy ? null : onScanMedicalQr,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                    ),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan Medical ID QR'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0x99020617),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 10),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientDirectory extends StatelessWidget {
  const _PatientDirectory({
    required this.patients,
    required this.access,
    required this.busy,
    required this.onOpen,
    required this.onBreakGlass,
  });

  final List<DoctorPatient> patients;
  final List<DoctorAccess> access;
  final bool busy;
  final ValueChanged<DoctorAccess> onOpen;
  final ValueChanged<DoctorPatient> onBreakGlass;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'PATIENT DIRECTORY & EMERGENCY ACCESS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Use consented access when available. Break-glass is limited to a genuine emergency and fully audited.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
            const SizedBox(height: 14),
            if (patients.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text(
                  'No patient records are available.',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              )
            else
              for (final patient in patients)
                _PatientDirectoryRow(
                  patient: patient,
                  access: access
                      .where((item) => item.patientProfileId == patient.id)
                      .firstOrNull,
                  busy: busy,
                  onOpen: onOpen,
                  onBreakGlass: onBreakGlass,
                ),
          ],
        ),
      ),
    );
  }
}

class _PatientDirectoryRow extends StatelessWidget {
  const _PatientDirectoryRow({
    required this.patient,
    required this.access,
    required this.busy,
    required this.onOpen,
    required this.onBreakGlass,
  });

  final DoctorPatient patient;
  final DoctorAccess? access;
  final bool busy;
  final ValueChanged<DoctorAccess> onOpen;
  final ValueChanged<DoctorPatient> onBreakGlass;

  @override
  Widget build(BuildContext context) {
    final currentAccess = access;
    final emergency =
        currentAccess?.accessType == EmergencyAccessKind.breakGlass;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: emergency
                ? const Color(0xFFFEE2E2)
                : const Color(0xFFD1FAE5),
            foregroundColor: emergency
                ? const Color(0xFFB91C1C)
                : const Color(0xFF047857),
            child: const Icon(Icons.person_outline),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  currentAccess == null
                      ? 'RECORD LOCKED • EMERGENCY OVERRIDE AVAILABLE'
                      : '${_accessLabel(currentAccess.accessType)} ACCESS EXPIRES ${_time(currentAccess.expiresAt)}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 9,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          if (currentAccess != null)
            FilledButton.icon(
              onPressed: busy ? null : () => onOpen(currentAccess),
              style: FilledButton.styleFrom(
                backgroundColor: emergency
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF059669),
              ),
              icon: const Icon(Icons.lock_open_outlined, size: 16),
              label: const Text('Open EHR'),
            )
          else
            FilledButton.icon(
              key: ValueKey('break-glass-${patient.id}'),
              onPressed: busy ? null : () => onBreakGlass(patient),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
              ),
              icon: const Icon(Icons.emergency_outlined, size: 16),
              label: const Text('Break glass'),
            ),
        ],
      ),
    );
  }
}

class _BreakGlassDialog extends StatefulWidget {
  const _BreakGlassDialog({required this.patient});

  final DoctorPatient patient;

  @override
  State<_BreakGlassDialog> createState() => _BreakGlassDialogState();
}

class _BreakGlassDialogState extends State<_BreakGlassDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.emergency, color: Color(0xFFDC2626), size: 34),
      title: const Text('Emergency break-glass access'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Patient: ${widget.patient.name}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              const Text(
                'Use only when immediate access is necessary to protect the patient. Your identity, reason, and every record view will be audited.',
                style: TextStyle(color: Color(0xFF475569), fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('break-glass-reason'),
                controller: _reason,
                maxLength: 500,
                minLines: 3,
                maxLines: 5,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Specific emergency reason',
                  hintText: 'Describe why consent cannot be obtained…',
                ),
                validator: (value) => (value?.trim().length ?? 0) < 20
                    ? 'Enter at least 20 characters.'
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          key: const ValueKey('confirm-break-glass'),
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.pop(context, _reason.text.trim());
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
          ),
          icon: const Icon(Icons.warning_amber_rounded),
          label: const Text('Activate for 15 minutes'),
        ),
      ],
    );
  }
}

class _ClinicalSnapshot extends StatelessWidget {
  const _ClinicalSnapshot({
    required this.snapshot,
    required this.clinicalRecords,
    required this.busy,
    required this.onCreateEncounter,
    required this.onGenerateAiSummary,
  });

  final DoctorSnapshot snapshot;
  final List<ClinicalEncounter> clinicalRecords;
  final bool busy;
  final VoidCallback onCreateEncounter;
  final VoidCallback onGenerateAiSummary;

  @override
  Widget build(BuildContext context) {
    final profile = snapshot.profile;
    final breakGlass = snapshot.accessType == EmergencyAccessKind.breakGlass;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ACTIVE SELECTED PATIENT EHR',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .8,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          profile.fullName,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        _Badge(
                          text: profile.id,
                          color: const Color(0xFF0F172A),
                        ),
                        _Badge(
                          text:
                              'BLOOD TYPE: ${bloodGroupLabel(profile.bloodGroup)}',
                          color: const Color(0xFFDC2626),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: breakGlass
                        ? const Color(0xFFFEF2F2)
                        : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: breakGlass
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF10B981),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    '${_accessLabel(snapshot.accessType)} • PROFILE READ ONLY • DOCUMENTATION ENABLED • ${_time(snapshot.expiresAt)}',
                    style: TextStyle(
                      color: breakGlass
                          ? const Color(0xFF991B1B)
                          : const Color(0xFF065F46),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (breakGlass && snapshot.emergencyReason != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF97316)),
            ),
            child: Text(
              'AUDITED EMERGENCY REASON: ${snapshot.emergencyReason}',
              style: const TextStyle(
                color: Color(0xFF9A3412),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        _EmergencyBar(profile: profile),
        const SizedBox(height: 18),
        _SnapshotGrid(profile: profile),
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            key: const ValueKey('generate-ai-summary'),
            onPressed: busy ? null : onGenerateAiSummary,
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: const Text('Generate AI summary'),
          ),
        ),
        const SizedBox(height: 12),
        ClinicalHistoryPanel(
          records: clinicalRecords,
          busy: busy,
          onCreate: onCreateEncounter,
        ),
      ],
    );
  }
}

class _EmergencyBar extends StatelessWidget {
  const _EmergencyBar({required this.profile});

  final EmergencyProfile profile;

  @override
  Widget build(BuildContext context) {
    final severe = profile.allergies.map((item) => item.name).join(', ');
    final contact = profile.emergencyContacts.firstOrNull;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth >= 720
              ? (constraints.maxWidth - 20) / 3
              : constraints.maxWidth;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _EmergencyFact(
                width: width,
                label: 'BLOOD TYPE & CODE',
                value: bloodGroupLabel(profile.bloodGroup),
                color: const Color(0xFFF87171),
              ),
              _EmergencyFact(
                width: width,
                label: 'SEVERE ALLERGIES (${profile.allergies.length})',
                value: severe.isEmpty ? 'NONE RECORDED' : severe,
                color: const Color(0xFFFCA5A5),
              ),
              _EmergencyFact(
                width: width,
                label: 'PRIMARY ICE CONTACT',
                value: contact == null
                    ? 'NONE RECORDED'
                    : '${contact.name} • ${contact.phoneNumber}',
                color: const Color(0xFF6EE7B7),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EmergencyFact extends StatelessWidget {
  const _EmergencyFact({
    required this.width,
    required this.label,
    required this.value,
    required this.color,
  });

  final double width;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xB3020617),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SnapshotGrid extends StatelessWidget {
  const _SnapshotGrid({required this.profile});

  final EmergencyProfile profile;

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[
      _SnapshotSection(
        title: 'Verified allergies',
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFB91C1C),
        values: profile.allergies.map(
          (item) => '${item.name} — ${item.severity}: ${item.reaction}',
        ),
      ),
      _SnapshotSection(
        title: 'Active prescriptions',
        icon: Icons.medication_outlined,
        color: const Color(0xFF1D4ED8),
        values: profile.medications.map(
          (item) => '${item.name} ${item.dosage} • ${item.frequency}',
        ),
      ),
      _SnapshotSection(
        title: 'Chronic conditions',
        icon: Icons.monitor_heart_outlined,
        color: const Color(0xFF4338CA),
        values: profile.medicalConditions.map(
          (item) =>
              '${item.name}${item.notes.isEmpty ? '' : ' • ${item.notes}'}',
        ),
      ),
      _SnapshotSection(
        title: 'Emergency contacts',
        icon: Icons.phone_outlined,
        color: const Color(0xFF047857),
        values: profile.emergencyContacts.map(
          (item) => '${item.name} • ${item.relationship} • ${item.phoneNumber}',
        ),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 760
            ? (constraints.maxWidth - 20) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: sections
              .map((section) => SizedBox(width: width, child: section))
              .toList(),
        );
      },
    );
  }
}

class _SnapshotSection extends StatelessWidget {
  const _SnapshotSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.values,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Iterable<String> values;

  @override
  Widget build(BuildContext context) {
    final rows = values.toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 7),
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .6,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            if (rows.isEmpty)
              const Text('None recorded')
            else
              for (final row in rows)
                Container(
                  margin: const EdgeInsets.only(top: 7),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    row,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Text(message, style: const TextStyle(color: Color(0xFFB91C1C))),
    );
  }
}

String _initials(String name) => name
    .trim()
    .split(RegExp(r'\s+'))
    .where((part) => part.isNotEmpty)
    .take(2)
    .map((part) => part[0])
    .join();

String _message(Object error) => error is ApiException
    ? error.message
    : 'Emergency access could not be loaded.';

String _accessLabel(EmergencyAccessKind kind) => switch (kind) {
  EmergencyAccessKind.consented => 'CONSENTED',
  EmergencyAccessKind.qrConsented => 'QR CONSENT',
  EmergencyAccessKind.breakGlass => 'BREAK-GLASS EMERGENCY',
};

String _time(DateTime value) => value.toLocal().toString().substring(0, 16);
