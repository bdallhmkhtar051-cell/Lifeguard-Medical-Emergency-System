# Development checkpoint 11: role-aware navigation

## Outcome

LifeGuard now has the responsive left-side hamburger navigation used by the
visual reference while preserving the working system's real role boundary.
The authenticated role determines the drawer contents; the menu never switches
a patient into a doctor workspace or bypasses authorization.

## Patient drawer

- Medical overview
- Clinical history
- My documents
- Access permissions and audit
- Sign out

Selecting a destination updates the same patient content tabs already backed
by the API. The active destination is highlighted in the drawer.

## Doctor drawer

- Authorized patients
- Scan Medical ID QR
- Sign out

The QR destination opens the existing camera scanner and therefore retains the
same token validation, expiry, one-use, authorization, and audit behavior.
Returning to Authorized patients clears any selected snapshot from the screen.

## Administrator drawer

- Administration overview
- Sign out

Administrator navigation does not expose patient editing or doctor emergency
actions.

## Implementation structure

- `HomeShell` owns the drawer and the authenticated role boundary.
- `WorkspaceNavigationController` holds the selected destination.
- `PatientProfilePage` maps drawer destinations to its existing four tabs.
- `DoctorAccessPage` handles the scanner and authorized-patient commands.

## Verification

Verification completed on 10 September 2026:

- `flutter analyze --no-pub`: no issues found.
- focused application suite: 10 tests passed.
- complete Flutter suite: 39 tests passed.
- patient drawer navigation, mobile width, and patient/doctor/administrator
  menu isolation are covered by widget tests.

