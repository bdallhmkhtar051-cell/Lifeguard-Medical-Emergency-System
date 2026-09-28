import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../auth/auth_models.dart';
import '../patient_profile/emergency_profile.dart';
import '../clinical/clinical_encounter_dialog.dart';
import '../clinical/clinical_history_panel.dart';
import '../clinical/clinical_models.dart';
import '../clinical/clinical_repository.dart';
import '../documents/document_repository.dart';
import '../documents/medical_documents_panel.dart';
import '../home/workspace_navigation.dart';
import 'access_models.dart';
import 'access_repository.dart';
import 'ai_medical_summary_dialog.dart';
import 'doctor_profile_page.dart';
import 'medical_qr_scanner_dialog.dart';

class DoctorAccessPage extends StatefulWidget {
  const DoctorAccessPage({
    required this.repository,
    required this.clinicalRepository,
    required this.user,
    this.initialMedicalQrToken,
    this.scannerBuilder,
    this.scannerExpectedBaseUri,
    this.documentRepository,
    this.navigationController,
    this.accessRevalidationInterval = const Duration(seconds: 5),
    super.key,
  });

  final AccessRepository repository;
  final ClinicalRepository clinicalRepository;
  final AppUser user;
  final String? initialMedicalQrToken;
  final MedicalQrScannerViewBuilder? scannerBuilder;
  final Uri? scannerExpectedBaseUri;
  final DocumentRepository? documentRepository;
  final WorkspaceNavigationController? navigationController;
  final Duration accessRevalidationInterval;

  @override
  State<DoctorAccessPage> createState() => _DoctorAccessPageState();
}

class _DoctorAccessPageState extends State<DoctorAccessPage> {
  late final WorkspaceNavigationController _navigation =
      widget.navigationController ??
      WorkspaceNavigationController(WorkspaceDestination.doctorPatients);
  List<DoctorAccess>? _access;
  List<DoctorPatient>? _patients;
  DoctorSnapshot? _snapshot;
  List<ClinicalEncounter> _clinicalRecords = const [];
  DoctorAccess? _selectedAccess;
  String? _error;
  bool _busy = true;
  bool _revalidatingAccess = false;
  Timer? _accessRevalidationTimer;

  @override
  void initState() {
    super.initState();
    _navigation.addListener(_handleNavigation);
    unawaited(_initialize());
  }

  @override
  void dispose() {
    _accessRevalidationTimer?.cancel();
    _navigation.removeListener(_handleNavigation);
    if (widget.navigationController == null) _navigation.dispose();
    super.dispose();
  }

  void _handleNavigation() {
    switch (_navigation.destination) {
      case WorkspaceDestination.doctorPatients:
        setState(() {
          _clearOpenedRecord();
        });
        break;
      case WorkspaceDestination.doctorScanQr:
        unawaited(_scanFromDrawer());
        break;
      case WorkspaceDestination.doctorProfile:
        setState(() {});
        break;
      default:
        break;
    }
  }

  Future<void> _scanFromDrawer() async {
    await _scanMedicalQr();
    if (mounted &&
        _navigation.destination == WorkspaceDestination.doctorScanQr) {
      _navigation.select(WorkspaceDestination.doctorPatients);
    }
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

  Future<void> _refresh() async {
    final selectedAccess = _selectedAccess;
    if (selectedAccess == null) {
      await _load();
    } else {
      await _open(selectedAccess);
    }
  }

  Future<void> _open(DoctorAccess access) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final snapshot = await widget.repository.doctorSnapshot(access.id);
      // Break-glass is intentionally a minimum-necessary emergency view. Full
      // history is requested only for patient-consented access.
      final clinicalRecords = snapshot.accessType == EmergencyAccessKind.breakGlass
          ? const <ClinicalEncounter>[]
          : await widget.clinicalRepository.doctorHistory(access.id);
      if (mounted) {
        setState(() {
          _snapshot = snapshot;
          _clinicalRecords = clinicalRecords;
          _selectedAccess = access;
        });
        _scheduleAccessRevalidation();
      }
    } catch (error) {
      if (mounted) {
        if (_accessEnded(error)) {
          setState(() {
            _clearOpenedRecord();
            _error = null;
          });
          _showAccessEndedMessage();
          await _load();
        } else {
          setState(() => _error = _message(error));
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _scheduleAccessRevalidation() {
    _accessRevalidationTimer?.cancel();
    _accessRevalidationTimer = Timer.periodic(
      widget.accessRevalidationInterval,
      (_) => unawaited(_revalidateOpenedAccess()),
    );
  }

  Future<void> _revalidateOpenedAccess() async {
    final selected = _selectedAccess;
    if (selected == null || _revalidatingAccess || _busy) return;
    if (!selected.expiresAt.toUtc().isAfter(DateTime.now().toUtc())) {
      setState(() {
        _clearOpenedRecord();
        _error = null;
      });
      _showAccessEndedMessage();
      return;
    }
    _revalidatingAccess = true;
    try {
      final activeAccess = await widget.repository.doctorAccess();
      if (!mounted || _selectedAccess?.id != selected.id) return;
      final stillActive = activeAccess
          .where((item) => item.id == selected.id)
          .firstOrNull;
      if (stillActive == null) {
        setState(() {
          _access = activeAccess;
          _clearOpenedRecord();
          _error = null;
        });
        _showAccessEndedMessage();
      } else {
        setState(() {
          _access = activeAccess;
          _selectedAccess = stillActive;
        });
      }
    } catch (_) {
      // A temporary network failure must not be mistaken for revocation.
      // Protected API actions continue to enforce access server-side.
    } finally {
      _revalidatingAccess = false;
    }
  }

  void _clearOpenedRecord() {
    _accessRevalidationTimer?.cancel();
    _accessRevalidationTimer = null;
    _snapshot = null;
    _selectedAccess = null;
    _clinicalRecords = const [];
  }

  void _showAccessEndedMessage() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Access was revoked or expired. The patient record has been closed.',
          ),
        ),
      );
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
      if (mounted) {
        final message = _message(error);
        setState(() => _error = message);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
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

  Future<void> _identifyEmergencyPatient(String qrPayload) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    EmergencyPatientIdentification? identification;
    try {
      identification = await widget.repository.identifyEmergencyPatient(
        qrPayload,
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error is ApiException && error.statusCode == 404
              ? 'This permanent emergency QR is invalid or no longer active.'
              : _message(error);
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }

    if (identification == null || !mounted) return;
    final useBreakGlass = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EmergencyIdentityDialog(identification: identification!),
    );
    if (useBreakGlass == true && mounted) {
      await _breakGlass(
        DoctorPatient(
          id: identification.patientProfileId,
          name: identification.patientName,
        ),
      );
    }
  }

  Future<void> _scanMedicalQr() async {
    final result = await showDialog<MedicalQrScanResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => MedicalQrScannerDialog(
        scannerBuilder: widget.scannerBuilder,
        expectedBaseUri: widget.scannerExpectedBaseUri,
      ),
    );
    if (result == null || !mounted) return;
    switch (result.kind) {
      case MedicalQrScanKind.temporaryConsent:
        await _redeemMedicalQr(result.value);
      case MedicalQrScanKind.permanentEmergency:
        await _identifyEmergencyPatient(result.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_navigation.destination == WorkspaceDestination.doctorProfile) {
      return DoctorProfilePage(repository: widget.repository);
    }
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
                  onRefresh: _refresh,
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
                        _clearOpenedRecord();
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
                  if (snapshot.accessType != EmergencyAccessKind.breakGlass &&
                      widget.documentRepository != null) ...[
                    const SizedBox(height: 18),
                    MedicalDocumentsPanel(
                      repository: widget.documentRepository!,
                      doctorGrantId: _selectedAccess!.id,
                    ),
                  ],
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF103F50), Color(0xFF086F79), Color(0xFF095896)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x664E9F97)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x200F766E),
            blurRadius: 16,
            offset: Offset(0, 8),
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
                    TextButton.icon(
                      key: const ValueKey('refresh-doctor-data'),
                      onPressed: busy ? null : onRefresh,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFCCFBF1),
                        backgroundColor: Colors.white10,
                      ),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Refresh data'),
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
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Row(
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
                              border: Border.all(
                                color: const Color(0x6645E6D1),
                              ),
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
                          Expanded(
                            child: Column(
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
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  user.email,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFCBD5E1),
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 620;
                    final metricWidth = compact
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 20) / 3;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        SizedBox(
                          width: metricWidth,
                          child: _Metric(
                            label: 'Authorized patients',
                            value: '$patientCount',
                            color: const Color(0xFF5EEAD4),
                          ),
                        ),
                        SizedBox(
                          width: metricWidth,
                          child: const _Metric(
                            label: 'Clinical mode',
                            value: 'READ + DOCUMENT',
                            color: Color(0xFF60A5FA),
                          ),
                        ),
                        SizedBox(
                          width: metricWidth,
                          child: const _Metric(
                            label: 'Audit status',
                            value: 'ACTIVE',
                            color: Color(0xFF34D399),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Scan a temporary consent QR or permanent emergency ID. Camera images stay on this device.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                    ),
                    FilledButton.icon(
                      key: const ValueKey('scan-medical-qr-button'),
                      onPressed: busy ? null : onScanMedicalQr,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                      ),
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Scan Medical ID QR'),
                    ),
                  ],
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

/// Confirmation boundary between patient identification and authorization.
/// No clinical data is loaded until the doctor completes break-glass.
class _EmergencyIdentityDialog extends StatelessWidget {
  const _EmergencyIdentityDialog({required this.identification});

  final EmergencyPatientIdentification identification;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.lock_outline, color: Color(0xFFB45309)),
          SizedBox(width: 10),
          Expanded(child: Text('Emergency patient identified')),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Color(0xFFFFEDD5),
                    child: Icon(
                      Icons.person_search_outlined,
                      color: Color(0xFFC2410C),
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    identification.patientName,
                    key: const ValueKey('identified-emergency-patient-name'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'IDENTITY MATCHED • RECORD LOCKED',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFB45309),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .7,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'The permanent QR identified this patient only. No medical information has been opened and no access grant has been created.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'For a genuine emergency, continue to break-glass and provide a specific reason. Access will be time-limited and audited.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF9A3412),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          key: const ValueKey('continue-emergency-break-glass'),
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFB91C1C),
          ),
          icon: const Icon(Icons.emergency_outlined),
          label: const Text('Continue to break-glass'),
        ),
      ],
    );
  }
}

enum _DirectoryFilter { all, authorized, locked, emergency }

class _PatientDirectory extends StatefulWidget {
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
  State<_PatientDirectory> createState() => _PatientDirectoryState();
}

class _PatientDirectoryState extends State<_PatientDirectory> {
  final _search = TextEditingController();
  _DirectoryFilter _filter = _DirectoryFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  DoctorAccess? _accessFor(DoctorPatient patient) => widget.access
      .where((item) => item.patientProfileId == patient.id)
      .firstOrNull;

  bool _matches(DoctorPatient patient) {
    final query = _search.text.trim().toLowerCase();
    if (query.isNotEmpty && !patient.name.toLowerCase().contains(query)) {
      return false;
    }
    final access = _accessFor(patient);
    return switch (_filter) {
      _DirectoryFilter.all => true,
      _DirectoryFilter.authorized => access != null,
      _DirectoryFilter.locked => access == null,
      _DirectoryFilter.emergency =>
        access?.accessType == EmergencyAccessKind.breakGlass,
    };
  }

  @override
  Widget build(BuildContext context) {
    final visiblePatients = widget.patients.where(_matches).toList();
    return Card(
      key: const ValueKey('doctor-patient-directory'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 6,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'PATIENT DIRECTORY & EMERGENCY ACCESS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),
                Text(
                  '${visiblePatients.length} OF ${widget.patients.length} PATIENTS',
                  key: const ValueKey('doctor-directory-result-count'),
                  style: const TextStyle(
                    color: Color(0xFF0F766E),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            const Text(
              'Open an active authorization whenever possible. Break-glass is for a genuine emergency and is fully audited.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('doctor-patient-search'),
              controller: _search,
              enabled: !widget.busy,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: 'Search patients',
                hintText: 'Enter a patient name',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        key: const ValueKey('clear-doctor-patient-search'),
                        tooltip: 'Clear search',
                        onPressed: () {
                          _search.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _DirectoryFilter.values
                  .map(
                    (filter) => FilterChip(
                      key: ValueKey('doctor-filter-${filter.name}'),
                      label: Text(_filterLabel(filter)),
                      selected: _filter == filter,
                      onSelected: widget.busy
                          ? null
                          : (_) => setState(() => _filter = filter),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 14),
            if (widget.patients.isEmpty)
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
            else if (visiblePatients.isEmpty)
              Container(
                key: const ValueKey('doctor-directory-empty-filter'),
                padding: const EdgeInsets.all(28),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text(
                  'No patients match this search and filter.',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              )
            else
              for (final patient in visiblePatients)
                _PatientDirectoryRow(
                  patient: patient,
                  access: _accessFor(patient),
                  busy: widget.busy,
                  onOpen: widget.onOpen,
                  onBreakGlass: widget.onBreakGlass,
                ),
          ],
        ),
      ),
    );
  }
}

String _filterLabel(_DirectoryFilter filter) => switch (filter) {
  _DirectoryFilter.all => 'All',
  _DirectoryFilter.authorized => 'Authorized',
  _DirectoryFilter.locked => 'Locked',
  _DirectoryFilter.emergency => 'Break-glass',
};

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
    final identity = Row(
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
      ],
    );
    final action = currentAccess != null
        ? FilledButton.icon(
            onPressed: busy ? null : () => onOpen(currentAccess),
            style: FilledButton.styleFrom(
              backgroundColor: emergency
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF059669),
            ),
            icon: const Icon(Icons.lock_open_outlined, size: 16),
            label: const Text('Open EHR'),
          )
        : FilledButton.icon(
            key: ValueKey('break-glass-${patient.id}'),
            onPressed: busy ? null : () => onBreakGlass(patient),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            icon: const Icon(Icons.emergency_outlined, size: 16),
            label: const Text('Break glass'),
          );
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 620) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [identity, const SizedBox(height: 10), action],
            );
          }
          return Row(
            children: [
              Expanded(child: identity),
              const SizedBox(width: 12),
              action,
            ],
          );
        },
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
      key: const ValueKey('doctor-clinical-snapshot'),
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
                    Text(
                      breakGlass
                          ? 'ACTIVE EMERGENCY SUMMARY'
                          : 'ACTIVE SELECTED PATIENT EHR',
                      style: const TextStyle(
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
                    '${_accessLabel(snapshot.accessType)} • '
                    '${breakGlass ? 'MINIMUM NECESSARY VIEW' : 'PROFILE READ ONLY • DOCUMENTATION ENABLED'} • '
                    '${_time(snapshot.expiresAt)}',
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
        if (breakGlass)
          _BreakGlassEmergencySummary(profile: profile)
        else ...[
          _SnapshotGrid(profile: profile),
          const SizedBox(height: 18),
          Card(
            color: const Color(0xFFF8FAFC),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CLINICAL TOOLS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .8,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'AI summaries are temporary decision support and must be verified by the clinician.',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    key: const ValueKey('generate-ai-summary'),
                    onPressed: busy ? null : onGenerateAiSummary,
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('Generate AI summary'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ClinicalHistoryPanel(
            records: clinicalRecords,
            busy: busy,
            onCreate: onCreateEncounter,
          ),
        ],
      ],
    );
  }
}

/// A deliberately short minimum-necessary view for emergency override access.
class _BreakGlassEmergencySummary extends StatelessWidget {
  const _BreakGlassEmergencySummary({required this.profile});

  final EmergencyProfile profile;

  @override
  Widget build(BuildContext context) {
    final responderFacts = <String>[
      'Donor status: ${organDonorStatusLabels[profile.organDonorStatus] ?? profile.organDonorStatus}',
      if (profile.firstResponderNotes.isNotEmpty)
        'Patient-reported notes: ${profile.firstResponderNotes}',
    ];
    final sections = <Widget>[
      _SnapshotSection(
        title: 'Active medications',
        icon: Icons.medication_outlined,
        color: const Color(0xFF1D4ED8),
        values: profile.medications.map(
          (item) => '${item.name} ${item.dosage} • ${item.frequency}',
        ),
      ),
      _SnapshotSection(
        title: 'Critical conditions',
        icon: Icons.monitor_heart_outlined,
        color: const Color(0xFF4338CA),
        values: profile.medicalConditions.map((item) => item.name),
      ),
      _SnapshotSection(
        title: 'First-responder notes',
        icon: Icons.emergency_outlined,
        color: const Color(0xFFB45309),
        values: responderFacts,
      ),
    ];

    return Column(
      key: const ValueKey('break-glass-emergency-summary'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFDBA74)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield_outlined, color: Color(0xFF9A3412)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Emergency-only view: only the minimum information needed for immediate care is shown. Clinical history, documents, insurance and AI tools remain locked.',
                  style: TextStyle(
                    color: Color(0xFF9A3412),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        LayoutBuilder(
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
      _SnapshotSection(
        title: 'Care and coverage',
        icon: Icons.health_and_safety_outlined,
        color: const Color(0xFF0F766E),
        values: <String>[
          if (profile.primaryPhysicianName.isNotEmpty ||
              profile.primaryPhysicianPhone.isNotEmpty)
            'Physician: ${profile.primaryPhysicianName.isEmpty ? 'Not recorded' : profile.primaryPhysicianName}'
                '${profile.primaryPhysicianPhone.isEmpty ? '' : ' • ${profile.primaryPhysicianPhone}'}',
          if (profile.insuranceProvider.isNotEmpty ||
              profile.insurancePolicyNumber.isNotEmpty)
            'Insurance: ${profile.insuranceProvider.isEmpty ? 'Not recorded' : profile.insuranceProvider}'
                '${profile.insurancePolicyNumber.isEmpty ? '' : ' • ${profile.insurancePolicyNumber}'}',
        ],
      ),
      _SnapshotSection(
        title: 'First-responder information',
        icon: Icons.emergency_outlined,
        color: const Color(0xFFB45309),
        values: <String>[
          'Donor status: ${organDonorStatusLabels[profile.organDonorStatus] ?? profile.organDonorStatus}',
          if (profile.firstResponderNotes.isNotEmpty)
            'Patient-reported notes: ${profile.firstResponderNotes}',
        ],
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

bool _accessEnded(Object error) =>
    error is ApiException &&
    (error.statusCode == 403 || error.statusCode == 404);

String _accessLabel(EmergencyAccessKind kind) => switch (kind) {
  EmergencyAccessKind.consented => 'CONSENTED',
  EmergencyAccessKind.qrConsented => 'QR CONSENT',
  EmergencyAccessKind.breakGlass => 'BREAK-GLASS EMERGENCY',
};

String _time(DateTime value) => value.toLocal().toString().substring(0, 16);
