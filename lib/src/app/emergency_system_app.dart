import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/async_error_panel.dart';
import '../features/auth/login_page.dart';
import '../features/auth/session_controller.dart';
import '../features/access/access_repository.dart';
import '../features/clinical/clinical_repository.dart';
import '../features/home/home_shell.dart';
import '../features/patient_profile/patient_profile_repository.dart';
import 'app_controller.dart';

class EmergencySystemApp extends StatelessWidget {
  const EmergencySystemApp({
    required this.appController,
    required this.sessionController,
    required this.patientProfileRepository,
    required this.accessRepository,
    required this.clinicalRepository,
    super.key,
  });

  final AppController appController;
  final SessionController sessionController;
  final PatientProfileRepository patientProfileRepository;
  final AccessRepository accessRepository;
  final ClinicalRepository clinicalRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeGuard Medical ID',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: _AppRoot(
        appController: appController,
        sessionController: sessionController,
        patientProfileRepository: patientProfileRepository,
        accessRepository: accessRepository,
        clinicalRepository: clinicalRepository,
      ),
    );
  }
}

class _AppRoot extends StatelessWidget {
  const _AppRoot({
    required this.appController,
    required this.sessionController,
    required this.patientProfileRepository,
    required this.accessRepository,
    required this.clinicalRepository,
  });

  final AppController appController;
  final SessionController sessionController;
  final PatientProfileRepository patientProfileRepository;
  final AccessRepository accessRepository;
  final ClinicalRepository clinicalRepository;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appController,
      builder: (context, _) {
        switch (appController.availability) {
          case ApiAvailability.checking:
            return const _StartupPage();
          case ApiAvailability.offline:
            return _OfflinePage(
              message:
                  appController.healthError ??
                  'The API is unavailable. Check that it is running.',
              onRetry: appController.checkHealth,
            );
          case ApiAvailability.online:
            return ListenableBuilder(
              listenable: sessionController,
              builder: (context, _) {
                if (sessionController.status == SessionStatus.signedIn &&
                    sessionController.user != null) {
                  return HomeShell(
                    sessionController: sessionController,
                    patientProfileRepository: patientProfileRepository,
                    accessRepository: accessRepository,
                    clinicalRepository: clinicalRepository,
                  );
                }
                return LoginPage(sessionController: sessionController);
              },
            );
        }
      },
    );
  }
}

class _StartupPage extends StatelessWidget {
  const _StartupPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Semantics(
          label: 'Connecting to the emergency system',
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BrandMark(size: 64),
              SizedBox(height: 24),
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Connecting securely…'),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfflinePage extends StatelessWidget {
  const _OfflinePage({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  const BrandMark(size: 72),
                  const SizedBox(height: 24),
                  Text(
                    'LifeGuard Medical ID',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 24),
                  AsyncErrorPanel(
                    key: const ValueKey('offline-panel'),
                    title: 'Cannot reach the API',
                    message: message,
                    onRetry: onRetry,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No medical information is cached on this device.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 56, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(size * .28),
      ),
      child: Icon(
        Icons.health_and_safety_outlined,
        size: size * .56,
        color: scheme.primary,
      ),
    );
  }
}
