import 'package:flutter/material.dart';

import '../auth/auth_models.dart';

/// A presentation-ready description of the system that only names features
/// currently implemented in the repository.
class AboutLifeGuardPage extends StatelessWidget {
  const AboutLifeGuardPage({required this.user, super.key});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('about-lifeguard-page'),
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Hero(role: user.singleRole),
              const SizedBox(height: 18),
              const _Section(
                icon: Icons.hub_outlined,
                title: 'Current system architecture',
                description:
                    'One responsive Flutter Web client communicates with an ASP.NET Core Web API. The API applies authentication, role permissions, validation, consent and auditing before Entity Framework Core reads or writes SQL Server.',
                items: [
                  'Frontend: Flutter Web and Dart',
                  'Backend: ASP.NET Core 10 Web API',
                  'Database: SQL Server through Entity Framework Core',
                  'Authentication: ASP.NET Core Identity and short-lived JWTs',
                ],
              ),
              const SizedBox(height: 14),
              const _FeatureGrid(),
              const SizedBox(height: 14),
              const _Section(
                icon: Icons.verified_user_outlined,
                title: 'Safety and privacy boundaries',
                description:
                    'The API—not the interface—is the security authority. A doctor sees a patient record only through an active consent grant, a one-use QR grant, or an audited emergency break-glass grant.',
                items: [
                  'Patient access can expire or be revoked.',
                  'Emergency access requires a reason and creates audit history.',
                  'Medical documents are validated and access controlled.',
                  'AI output is temporary decision support and must be checked.',
                ],
              ),
              const SizedBox(height: 14),
              const _SimulationNotice(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.role});

  final UserRole? role;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF020617), Color(0xFF0F172A), Color(0xFF134E4A)],
      ),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Wrap(
      spacing: 18,
      runSpacing: 14,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Icon(Icons.health_and_safety, color: Color(0xFF5EEAD4), size: 56),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ABOUT LIFEGUARD',
                style: TextStyle(
                  color: Color(0xFF5EEAD4),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Medical ID & Emergency Access System',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'A thesis demonstration of controlled emergency medical information sharing for ${_roleLabel(role).toLowerCase()} users.',
                style: const TextStyle(color: Color(0xFFCBD5E1), height: 1.45),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth >= 700
          ? (constraints.maxWidth - 14) / 2
          : constraints.maxWidth;
      return Wrap(
        spacing: 14,
        runSpacing: 14,
        children: [
          for (final feature in _features)
            SizedBox(
              width: width,
              child: _Section(
                icon: feature.icon,
                title: feature.title,
                description: feature.description,
                items: feature.items,
              ),
            ),
        ],
      );
    },
  );
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.description,
    required this.items,
  });

  final IconData icon;
  final String title;
  final String description;
  final List<String> items;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF0F766E), size: 28),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 7),
          Text(
            description,
            style: const TextStyle(color: Color(0xFF475569), height: 1.45),
          ),
          const SizedBox(height: 12),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Color(0xFF059669),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(item, style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

class _SimulationNotice extends StatelessWidget {
  const _SimulationNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFBEB),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFF59E0B)),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.science_outlined, color: Color(0xFFB45309)),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'THESIS DEMONSTRATION BOUNDARY\nBiometric sign-in is an explicitly labelled simulation. It does not use a face, fingerprint, passkey, camera, or biometric data. Password authentication remains the real sign-in method.',
            style: TextStyle(
              color: Color(0xFF78350F),
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Feature {
  const _Feature(this.icon, this.title, this.description, this.items);
  final IconData icon;
  final String title;
  final String description;
  final List<String> items;
}

const _features = [
  _Feature(
    Icons.person_outline,
    'Patient capabilities',
    'Patients maintain and share their own emergency information.',
    [
      'Emergency profile and Medical ID',
      'Clinical history and documents',
      'Time-limited doctor consent',
      'One-use Medical ID QR',
    ],
  ),
  _Feature(
    Icons.medical_services_outlined,
    'Doctor capabilities',
    'Doctors work only with currently authorized records.',
    [
      'Patient directory and QR scanner',
      'Read-only emergency snapshot',
      'Encounters, vital signs and prescriptions',
      'Guarded AI summary',
    ],
  ),
  _Feature(
    Icons.admin_panel_settings_outlined,
    'Administrator capabilities',
    'Administrators manage accounts without becoming clinicians.',
    [
      'Account activation and deactivation',
      'Role-separated administration',
      'Account audit history',
      'System access audit review',
    ],
  ),
  _Feature(
    Icons.emergency_outlined,
    'Emergency workflow',
    'Urgent access remains limited, explained and traceable.',
    [
      'Required emergency reason',
      '15-minute break-glass grant',
      'Rate-limited activation',
      'Patient-visible audit event',
    ],
  ),
];

String _roleLabel(UserRole? role) => switch (role) {
  UserRole.patient => 'Patient',
  UserRole.doctor => 'Doctor',
  UserRole.administrator => 'Administrator',
  null => 'Authenticated',
};
