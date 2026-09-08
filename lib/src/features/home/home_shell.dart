import 'package:flutter/material.dart';

import '../auth/auth_models.dart';
import '../auth/session_controller.dart';
import '../administration/administration_page.dart';
import '../administration/administration_repository.dart';
import '../access/access_repository.dart';
import '../access/doctor_access_page.dart';
import '../clinical/clinical_repository.dart';
import '../patient_profile/patient_profile_page.dart';
import '../patient_profile/patient_profile_repository.dart';
import '../documents/document_repository.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({
    required this.sessionController,
    required this.patientProfileRepository,
    required this.accessRepository,
    required this.clinicalRepository,
    required this.administrationRepository,
    required this.documentRepository,
    this.initialMedicalQrToken,
    super.key,
  });

  final SessionController sessionController;
  final PatientProfileRepository patientProfileRepository;
  final AccessRepository accessRepository;
  final ClinicalRepository clinicalRepository;
  final AdministrationRepository administrationRepository;
  final DocumentRepository documentRepository;
  final String? initialMedicalQrToken;

  @override
  Widget build(BuildContext context) {
    final user = sessionController.user!;
    final role = user.singleRole;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 74,
        titleSpacing: 0,
        title: _PortalNavigation(
          user: user,
          role: role,
          busy: sessionController.isBusy,
          onLogout: sessionController.logout,
        ),
      ),
      body: role == UserRole.patient
          ? PatientProfilePage(
              repository: patientProfileRepository,
              accessRepository: accessRepository,
              clinicalRepository: clinicalRepository,
              documentRepository: documentRepository,
            )
          : role == UserRole.doctor
          ? DoctorAccessPage(
              repository: accessRepository,
              clinicalRepository: clinicalRepository,
              user: user,
              initialMedicalQrToken: initialMedicalQrToken,
              documentRepository: documentRepository,
            )
          : role == UserRole.administrator
          ? AdministrationPage(
              repository: administrationRepository,
              currentUser: user,
            )
          : _RoleLanding(user: user),
    );
  }

  static IconData _roleIcon(UserRole role) => switch (role) {
    UserRole.patient => Icons.person_outline,
    UserRole.doctor => Icons.medical_services_outlined,
    UserRole.administrator => Icons.admin_panel_settings_outlined,
  };
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.role});

  final UserRole? role;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: role == UserRole.doctor
            ? const Color(0xFF0F766E)
            : const Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(11),
        boxShadow: const [BoxShadow(color: Color(0x552563EB), blurRadius: 14)],
      ),
      child: Icon(
        role == UserRole.doctor
            ? Icons.medical_services
            : Icons.health_and_safety,
        color: Colors.white,
        size: 23,
      ),
    );
  }
}

/// The prototype allowed a visual portal switch. The working system displays
/// the authenticated role here instead, so the same look keeps real security.
class _PortalNavigation extends StatelessWidget {
  const _PortalNavigation({
    required this.user,
    required this.role,
    required this.busy,
    required this.onLogout,
  });

  final AppUser user;
  final UserRole? role;
  final bool busy;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final doctor = role == UserRole.doctor;
    final accent = doctor ? const Color(0xFF2DD4BF) : const Color(0xFF60A5FA);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _BrandMark(role: role),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: 'LIFEGUARD ',
                        children: [
                          TextSpan(
                            text: 'ID',
                            style: TextStyle(color: accent),
                          ),
                        ],
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.2,
                      ),
                    ),
                    Text(
                      doctor
                          ? 'HOSPITAL NODE • EMERGENCY EHR TERMINAL'
                          : 'CENTRALIZED MEDICAL RECORD & EMERGENCY ACCESS',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: .7,
                      ),
                    ),
                  ],
                ),
              ),
              _RolePill(role: role, accent: accent),
              const SizedBox(width: 10),
              if (MediaQuery.sizeOf(context).width >= 760) ...[
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      user.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      user.email,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
              ],
              IconButton(
                key: const ValueKey('logout-button'),
                tooltip: 'Sign out',
                onPressed: busy ? null : onLogout,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  side: const BorderSide(color: Color(0xFF334155)),
                ),
                icon: const Icon(Icons.logout, size: 19),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.role, required this.accent});

  final UserRole? role;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final label = switch (role) {
      UserRole.patient => 'PATIENT PORTAL',
      UserRole.doctor => 'CLINICIAN',
      UserRole.administrator => 'ADMIN',
      null => 'ACCOUNT',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF020617),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            HomeShell._roleIcon(role ?? UserRole.administrator),
            size: 14,
            color: accent,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: accent,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: .5,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleLanding extends StatelessWidget {
  const _RoleLanding({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final roleLabel = user.singleRole?.label ?? 'Multiple roles';
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      user.singleRole == UserRole.doctor
                          ? Icons.medical_services_outlined
                          : Icons.admin_panel_settings_outlined,
                      size: 56,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Welcome, ${user.displayName}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$roleLabel workspace',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Authentication and role authorization are connected. '
                      'Clinical workflows for this role will be added in a '
                      'later milestone; no patient editor is exposed here.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
