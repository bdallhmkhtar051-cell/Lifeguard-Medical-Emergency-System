import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'src/app/app_controller.dart';
import 'src/app/emergency_system_app.dart';
import 'src/core/config/app_config.dart';
import 'src/core/network/api_client.dart';
import 'src/features/auth/auth_repository.dart';
import 'src/features/auth/session_controller.dart';
import 'src/features/access/access_repository.dart';
import 'src/features/clinical/clinical_repository.dart';
import 'src/features/health/health_repository.dart';
import 'src/features/patient_profile/patient_profile_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  const config = AppConfig.fromEnvironment();
  final apiClient = ApiClient(
    baseUri: config.apiBaseUri,
    client: http.Client(),
  );
  final sessionController = SessionController(
    repository: ApiAuthRepository(apiClient),
    apiClient: apiClient,
  );
  apiClient.onUnauthorized = sessionController.expireSession;

  final appController = AppController(
    healthRepository: ApiHealthRepository(apiClient),
  );

  runApp(
    EmergencySystemApp(
      appController: appController,
      sessionController: sessionController,
      patientProfileRepository: ApiPatientProfileRepository(apiClient),
      accessRepository: ApiAccessRepository(apiClient),
      clinicalRepository: ApiClinicalRepository(apiClient),
    ),
  );

  // Bootstrap after the first frame so the user immediately sees a deliberate
  // loading state instead of a blank browser window.
  unawaited(appController.bootstrap());
}
