import 'package:flutter/foundation.dart';

enum WorkspaceDestination {
  patientOverview,
  patientClinicalHistory,
  patientDocuments,
  patientAccess,
  doctorPatients,
  doctorScanQr,
  administration,
  about,
  settings,
}

/// Shares the selected drawer destination with the active role page.
class WorkspaceNavigationController extends ChangeNotifier {
  WorkspaceNavigationController(this._destination);

  WorkspaceDestination _destination;

  WorkspaceDestination get destination => _destination;

  void select(WorkspaceDestination destination) {
    if (_destination == destination &&
        destination != WorkspaceDestination.doctorScanQr) {
      return;
    }
    _destination = destination;
    notifyListeners();
  }
}
