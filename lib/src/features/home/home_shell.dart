import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
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
import 'workspace_navigation.dart';
import 'about_lifeguard_page.dart';
import 'accessibility_settings_page.dart';

class HomeShell extends StatefulWidget {
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
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late final WorkspaceNavigationController _navigation;
  double _textScale = 1;
  bool _highContrast = false;
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    _navigation = WorkspaceNavigationController(
      switch (widget.sessionController.user!.singleRole) {
        UserRole.patient => WorkspaceDestination.patientOverview,
        UserRole.doctor => WorkspaceDestination.doctorPatients,
        UserRole.administrator || null => WorkspaceDestination.administration,
      },
    );
  }

  @override
  void dispose() {
    _navigation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.sessionController.user!;
    final role = user.singleRole;
    final media = MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(_textScale),
      disableAnimations: _reducedMotion,
    );
    return Theme(
      data: _highContrast ? AppTheme.highContrast() : AppTheme.light(),
      child: MediaQuery(
        data: media,
        child: Scaffold(
          drawer: _WorkspaceDrawer(
            user: user,
            navigation: _navigation,
            busy: widget.sessionController.isBusy,
            onLogout: widget.sessionController.logout,
          ),
          appBar: AppBar(
            toolbarHeight: 74,
            titleSpacing: 0,
            leading: Builder(
              builder: (context) => IconButton(
                key: const ValueKey('workspace-menu-button'),
                tooltip: 'Open navigation menu',
                onPressed: Scaffold.of(context).openDrawer,
                icon: const Icon(Icons.menu),
              ),
            ),
            title: _PortalNavigation(
              user: user,
              role: role,
              busy: widget.sessionController.isBusy,
              onLogout: widget.sessionController.logout,
            ),
          ),
          body: ListenableBuilder(
            listenable: _navigation,
            builder: (context, _) => switch (_navigation.destination) {
              WorkspaceDestination.about => AboutLifeGuardPage(user: user),
              WorkspaceDestination.settings => AccessibilitySettingsPage(
                user: user,
                expiresAtUtc: widget.sessionController.expiresAtUtc,
                textScale: _textScale,
                highContrast: _highContrast,
                reducedMotion: _reducedMotion,
                onTextScaleChanged: (value) =>
                    setState(() => _textScale = value),
                onHighContrastChanged: (value) =>
                    setState(() => _highContrast = value),
                onReducedMotionChanged: (value) =>
                    setState(() => _reducedMotion = value),
                onReset: () => setState(() {
                  _textScale = 1;
                  _highContrast = false;
                  _reducedMotion = false;
                }),
              ),
              _ =>
                role == UserRole.patient
                    ? PatientProfilePage(
                        repository: widget.patientProfileRepository,
                        accessRepository: widget.accessRepository,
                        clinicalRepository: widget.clinicalRepository,
                        documentRepository: widget.documentRepository,
                        navigationController: _navigation,
                      )
                    : role == UserRole.doctor
                    ? DoctorAccessPage(
                        repository: widget.accessRepository,
                        clinicalRepository: widget.clinicalRepository,
                        user: user,
                        initialMedicalQrToken: widget.initialMedicalQrToken,
                        documentRepository: widget.documentRepository,
                        navigationController: _navigation,
                      )
                    : role == UserRole.administrator
                    ? AdministrationPage(
                        repository: widget.administrationRepository,
                        currentUser: user,
                      )
                    : _RoleLanding(user: user),
            },
          ),
        ),
      ),
    );
  }

  static IconData _roleIcon(UserRole role) => switch (role) {
    UserRole.patient => Icons.person_outline,
    UserRole.doctor => Icons.medical_services_outlined,
    UserRole.administrator => Icons.admin_panel_settings_outlined,
  };
}

class _WorkspaceDrawer extends StatelessWidget {
  const _WorkspaceDrawer({
    required this.user,
    required this.navigation,
    required this.busy,
    required this.onLogout,
  });

  final AppUser user;
  final WorkspaceNavigationController navigation;
  final bool busy;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final role = user.singleRole;
    final doctor = role == UserRole.doctor;
    final accent = doctor ? const Color(0xFF2DD4BF) : const Color(0xFF60A5FA);
    return Drawer(
      key: const ValueKey('workspace-drawer'),
      backgroundColor: const Color(0xFF0F172A),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 18),
              child: Row(
                children: [
                  _BrandMark(role: role),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          role == UserRole.patient
                              ? 'PATIENT PORTAL'
                              : role == UserRole.doctor
                              ? 'DOCTOR CONSOLE'
                              : 'ADMINISTRATION',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .7,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          user.displayName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close menu',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF334155), height: 1),
            Expanded(
              child: ListenableBuilder(
                listenable: navigation,
                builder: (context, _) => ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    _DrawerSection(
                      label: role == UserRole.patient
                          ? 'MY MEDICAL RECORD'
                          : role == UserRole.doctor
                          ? 'EMERGENCY TOOLS'
                          : 'SYSTEM MANAGEMENT',
                    ),
                    ..._destinations(role).map(
                      (item) => _DrawerDestinationTile(
                        item: item,
                        selected: navigation.destination == item.destination,
                        accent: accent,
                        onTap: () {
                          navigation.select(item.destination);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(color: Color(0xFF334155), height: 1),
                    ),
                    _DrawerDestinationTile(
                      item: const _DrawerItem(
                        WorkspaceDestination.about,
                        'About LifeGuard',
                        Icons.info_outline,
                      ),
                      selected:
                          navigation.destination == WorkspaceDestination.about,
                      accent: accent,
                      onTap: () {
                        navigation.select(WorkspaceDestination.about);
                        Navigator.pop(context);
                      },
                    ),
                    _DrawerDestinationTile(
                      item: const _DrawerItem(
                        WorkspaceDestination.settings,
                        'Accessibility & settings',
                        Icons.settings_accessibility_outlined,
                      ),
                      selected:
                          navigation.destination ==
                          WorkspaceDestination.settings,
                      accent: accent,
                      onTap: () {
                        navigation.select(WorkspaceDestination.settings);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const Divider(color: Color(0xFF334155), height: 1),
            ListTile(
              key: const ValueKey('drawer-logout-button'),
              enabled: !busy,
              leading: const Icon(Icons.logout, color: Color(0xFFF87171)),
              title: const Text(
                'Sign out',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                user.email,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
              ),
              onTap: () {
                Navigator.pop(context);
                onLogout();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static List<_DrawerItem> _destinations(UserRole? role) => switch (role) {
    UserRole.patient => const [
      _DrawerItem(
        WorkspaceDestination.patientOverview,
        'Medical overview',
        Icons.dashboard_outlined,
      ),
      _DrawerItem(
        WorkspaceDestination.patientClinicalHistory,
        'Clinical history',
        Icons.history_edu_outlined,
      ),
      _DrawerItem(
        WorkspaceDestination.patientDocuments,
        'My documents',
        Icons.folder_copy_outlined,
      ),
      _DrawerItem(
        WorkspaceDestination.patientAccess,
        'Access permissions & audit',
        Icons.key_outlined,
      ),
    ],
    UserRole.doctor => const [
      _DrawerItem(
        WorkspaceDestination.doctorPatients,
        'Authorized patients',
        Icons.people_outline,
      ),
      _DrawerItem(
        WorkspaceDestination.doctorScanQr,
        'Scan Medical ID QR',
        Icons.qr_code_scanner,
      ),
      _DrawerItem(
        WorkspaceDestination.doctorProfile,
        'Professional profile',
        Icons.badge_outlined,
      ),
    ],
    UserRole.administrator || null => const [
      _DrawerItem(
        WorkspaceDestination.administration,
        'Administration overview',
        Icons.admin_panel_settings_outlined,
      ),
    ],
  };
}

class _DrawerSection extends StatelessWidget {
  const _DrawerSection({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
    child: Text(
      label,
      style: const TextStyle(
        color: Color(0xFF64748B),
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
      ),
    ),
  );
}

class _DrawerItem {
  const _DrawerItem(this.destination, this.label, this.icon);
  final WorkspaceDestination destination;
  final String label;
  final IconData icon;
}

class _DrawerDestinationTile extends StatelessWidget {
  const _DrawerDestinationTile({
    required this.item,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final _DrawerItem item;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: ListTile(
      key: ValueKey('drawer-${item.destination.name}'),
      selected: selected,
      selectedTileColor: accent.withValues(alpha: .17),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      leading: Icon(
        item.icon,
        color: selected ? accent : const Color(0xFF94A3B8),
      ),
      title: Text(
        item.label,
        style: TextStyle(
          color: selected ? Colors.white : const Color(0xFFCBD5E1),
          fontSize: 13,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        size: 18,
        color: selected ? accent : const Color(0xFF475569),
      ),
      onTap: onTap,
    ),
  );
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
              if (MediaQuery.sizeOf(context).width >= 520) ...[
                _RolePill(role: role, accent: accent),
                const SizedBox(width: 10),
              ],
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
            _HomeShellState._roleIcon(role ?? UserRole.administrator),
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
