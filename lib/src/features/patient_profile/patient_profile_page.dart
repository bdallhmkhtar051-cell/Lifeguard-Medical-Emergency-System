import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/widgets/async_error_panel.dart';
import '../access/access_repository.dart';
import '../access/medical_qr_dialog.dart';
import '../access/patient_access_panel.dart';
import '../clinical/clinical_history_panel.dart';
import '../clinical/clinical_repository.dart';
import '../documents/document_repository.dart';
import '../documents/medical_documents_panel.dart';
import '../home/workspace_navigation.dart';
import 'emergency_profile.dart';
import 'patient_medical_id_header.dart';
import 'patient_profile_controller.dart';
import 'patient_profile_form.dart';
import 'patient_profile_repository.dart';

class PatientProfilePage extends StatefulWidget {
  const PatientProfilePage({
    required this.repository,
    required this.accessRepository,
    required this.clinicalRepository,
    required this.documentRepository,
    required this.navigationController,
    super.key,
  });

  final PatientProfileRepository repository;
  final AccessRepository accessRepository;
  final ClinicalRepository clinicalRepository;
  final DocumentRepository documentRepository;
  final WorkspaceNavigationController navigationController;

  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  late final PatientProfileController _controller;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _controller = PatientProfileController(repository: widget.repository);
    unawaited(_controller.load());
  }

  @override
  void dispose() {
    _controller.clearSensitiveState(notify: false);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final profile = _controller.profile;
          if (_controller.isLoading && profile == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (profile == null) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: AsyncErrorPanel(
                  message:
                      _controller.errorMessage ??
                      'The emergency profile is unavailable.',
                  onRetry: _controller.load,
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 48),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: _editing
                    ? PatientProfileForm(
                        key: ValueKey('profile-form-${profile.updatedAtUtc}'),
                        profile: profile,
                        saving: _controller.isSaving,
                        serverError: _controller.errorMessage,
                        fieldErrors: _controller.fieldErrors,
                        onSave: (edited) async {
                          final saved = await _controller.save(edited);
                          if (saved && context.mounted) {
                            setState(() => _editing = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Emergency profile saved.'),
                              ),
                            );
                          }
                          return saved;
                        },
                        onCancel: () => setState(() => _editing = false),
                        onReload: () {
                          setState(() => _editing = false);
                          unawaited(_controller.load());
                        },
                      )
                    : _PatientPortal(
                        profile: profile,
                        accessRepository: widget.accessRepository,
                        clinicalRepository: widget.clinicalRepository,
                        documentRepository: widget.documentRepository,
                        navigationController: widget.navigationController,
                        warning: _controller.errorMessage,
                        onEdit: () {
                          _controller.dismissError();
                          setState(() => _editing = true);
                        },
                        onRefresh: _controller.load,
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

enum _PatientTab { overview, clinicalHistory, documents, access }

/// Uses the reference portal hierarchy while values still come from the API.
class _PatientPortal extends StatefulWidget {
  const _PatientPortal({
    required this.profile,
    required this.accessRepository,
    required this.clinicalRepository,
    required this.documentRepository,
    required this.navigationController,
    required this.warning,
    required this.onEdit,
    required this.onRefresh,
  });

  final EmergencyProfile profile;
  final AccessRepository accessRepository;
  final ClinicalRepository clinicalRepository;
  final DocumentRepository documentRepository;
  final WorkspaceNavigationController navigationController;
  final String? warning;
  final VoidCallback onEdit;
  final VoidCallback onRefresh;

  @override
  State<_PatientPortal> createState() => _PatientPortalState();
}

class _PatientPortalState extends State<_PatientPortal> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.navigationController,
      builder: (context, _) {
        final tab = switch (widget.navigationController.destination) {
          WorkspaceDestination.patientClinicalHistory =>
            _PatientTab.clinicalHistory,
          WorkspaceDestination.patientDocuments => _PatientTab.documents,
          WorkspaceDestination.patientAccess => _PatientTab.access,
          _ => _PatientTab.overview,
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PatientMedicalIdHeader(
              profile: widget.profile,
              onEdit: widget.onEdit,
              onRefresh: widget.onRefresh,
              onDisplayQr: () => showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (_) =>
                    MedicalQrDialog(repository: widget.accessRepository),
              ),
            ),
            if (widget.warning != null) ...[
              const SizedBox(height: 16),
              AsyncErrorPanel(
                message: widget.warning!,
                compact: true,
                onRetry: widget.onRefresh,
              ),
            ],
            const SizedBox(height: 18),
            _PortalTabs(
              active: tab,
              onChanged: (value) => widget.navigationController.select(
                switch (value) {
                  _PatientTab.overview => WorkspaceDestination.patientOverview,
                  _PatientTab.clinicalHistory =>
                    WorkspaceDestination.patientClinicalHistory,
                  _PatientTab.documents =>
                    WorkspaceDestination.patientDocuments,
                  _PatientTab.access => WorkspaceDestination.patientAccess,
                },
              ),
            ),
            const SizedBox(height: 18),
            switch (tab) {
              _PatientTab.overview => _OverviewGrid(profile: widget.profile),
              _PatientTab.clinicalHistory => PatientClinicalHistory(
                repository: widget.clinicalRepository,
              ),
              _PatientTab.documents => MedicalDocumentsPanel(
                repository: widget.documentRepository,
              ),
              _PatientTab.access => PatientAccessPanel(
                repository: widget.accessRepository,
              ),
            },
            if (widget.profile.updatedAtUtc case final updated?) ...[
              const SizedBox(height: 16),
              Text(
                'LAST UPDATED ${_dateTime(updated).toUpperCase()}',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _PortalTabs extends StatelessWidget {
  const _PortalTabs({required this.active, required this.onChanged});

  final _PatientTab active;
  final ValueChanged<_PatientTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          _item(
            tab: _PatientTab.overview,
            label: 'Medical overview',
            icon: Icons.dashboard_outlined,
          ),
          _item(
            tab: _PatientTab.clinicalHistory,
            label: 'Clinical history',
            icon: Icons.history_edu_outlined,
          ),
          _item(
            tab: _PatientTab.documents,
            label: 'Documents',
            icon: Icons.folder_copy_outlined,
          ),
          _item(
            tab: _PatientTab.access,
            label: 'Access permissions',
            icon: Icons.key_outlined,
          ),
        ],
      ),
    );
  }

  Widget _item({
    required _PatientTab tab,
    required String label,
    required IconData icon,
  }) {
    final selected = active == tab;
    return Expanded(
      child: Material(
        color: selected ? const Color(0xFF2563EB) : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: () => onChanged(tab),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: selected ? Colors.white : const Color(0xFF64748B),
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF475569),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid({required this.profile});

  final EmergencyProfile profile;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      _RecordCard(
        title: 'Verified allergies (${profile.allergies.length})',
        icon: Icons.warning_amber_rounded,
        accent: const Color(0xFFB91C1C),
        emptyText: 'No allergies recorded.',
        children: profile.allergies
            .map(
              (item) => _RecordRow(
                title: item.name,
                subtitle: item.reaction.isEmpty
                    ? ''
                    : 'Reaction: ${item.reaction}',
                badge: item.severity,
                badgeColor: const Color(0xFFB91C1C),
              ),
            )
            .toList(),
      ),
      _RecordCard(
        title: 'Active prescriptions (${profile.medications.length})',
        icon: Icons.medication_outlined,
        accent: const Color(0xFF1D4ED8),
        emptyText: 'No medications recorded.',
        children: profile.medications
            .map(
              (item) => _RecordRow(
                title: item.name,
                subtitle: item.frequency,
                badge: item.dosage,
              ),
            )
            .toList(),
      ),
      _RecordCard(
        title: 'Chronic conditions (${profile.medicalConditions.length})',
        icon: Icons.monitor_heart_outlined,
        accent: const Color(0xFF4338CA),
        emptyText: 'No medical conditions recorded.',
        children: profile.medicalConditions
            .map((item) => _RecordRow(title: item.name, subtitle: item.notes))
            .toList(),
      ),
      _RecordCard(
        title: 'ICE emergency contacts',
        icon: Icons.phone_outlined,
        accent: const Color(0xFF047857),
        emptyText: 'No emergency contacts recorded.',
        children: profile.emergencyContacts
            .map(
              (item) => _RecordRow(
                title: item.name,
                subtitle: '${item.relationship} • ${item.phoneNumber}',
                badge: item.isPrimary ? 'PRIMARY ICE' : null,
                badgeColor: const Color(0xFF047857),
              ),
            )
            .toList(),
      ),
      _RecordCard(
        title: 'Care and coverage',
        icon: Icons.health_and_safety_outlined,
        accent: const Color(0xFF0F766E),
        emptyText: 'No physician or insurance details recorded.',
        children: [
          if (profile.primaryPhysicianName.isNotEmpty ||
              profile.primaryPhysicianPhone.isNotEmpty)
            _RecordRow(
              title: profile.primaryPhysicianName.isEmpty
                  ? 'Primary physician'
                  : profile.primaryPhysicianName,
              subtitle: profile.primaryPhysicianPhone,
              badge: 'PHYSICIAN',
              badgeColor: const Color(0xFF0F766E),
            ),
          if (profile.insuranceProvider.isNotEmpty ||
              profile.insurancePolicyNumber.isNotEmpty)
            _RecordRow(
              title: profile.insuranceProvider.isEmpty
                  ? 'Insurance'
                  : profile.insuranceProvider,
              subtitle: profile.insurancePolicyNumber.isEmpty
                  ? ''
                  : 'Member: ${profile.insurancePolicyNumber}',
              badge: 'COVERAGE',
              badgeColor: const Color(0xFF0F766E),
            ),
        ],
      ),
      _RecordCard(
        title: 'First-responder information',
        icon: Icons.emergency_outlined,
        accent: const Color(0xFFB45309),
        emptyText: 'No first-responder notes recorded.',
        children: [
          _RecordRow(
            title: 'Organ donor status',
            subtitle:
                organDonorStatusLabels[profile.organDonorStatus] ??
                profile.organDonorStatus,
            badge: 'PATIENT REPORTED',
            badgeColor: const Color(0xFFB45309),
          ),
          if (profile.firstResponderNotes.isNotEmpty)
            _RecordRow(
              title: 'Responder notes',
              subtitle: profile.firstResponderNotes,
              badge: 'VERIFY',
              badgeColor: const Color(0xFFB45309),
            ),
        ],
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth >= 760
            ? (constraints.maxWidth - 24) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 24,
          runSpacing: 24,
          children: cards
              .map((card) => SizedBox(width: cardWidth, child: card))
              .toList(),
        );
      },
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.emptyText,
    required this.children,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final String emptyText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: accent, size: 18),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      color: accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .7,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            if (children.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  emptyText,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              )
            else
              ...children,
          ],
        ),
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({
    required this.title,
    required this.subtitle,
    this.badge,
    this.badgeColor = const Color(0xFF475569),
  });

  final String title;
  final String subtitle;
  final String? badge;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (badge != null && badge!.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: badgeColor.withValues(alpha: .25)),
              ),
              child: Text(
                badge!,
                style: TextStyle(
                  color: badgeColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _dateTime(DateTime date) {
  final local = date.toLocal();
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')} at ${local.hour}:$minute';
}
