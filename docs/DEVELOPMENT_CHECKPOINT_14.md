# Development checkpoint 14: presentation utilities

**Completed:** 12 September 2026

## Outcome

LifeGuard now contains two utilities designed for a clear thesis demonstration:
an authenticated About LifeGuard page and a printable patient emergency
summary. Both describe or display implemented behavior without inventing
future functionality.

## About LifeGuard

Every authenticated role can open **About LifeGuard** from the hamburger menu.
The page explains:

- the Flutter Web, ASP.NET Core, Entity Framework Core, and SQL Server stack;
- the patient, doctor, and administrator roles and access patterns;
- consent, QR, break-glass, document, audit, and AI safety boundaries;
- that biometric sign-in is a simulation and creates no authenticated session.

## Stored emergency summary

The patient Medical ID card contains **Print / Save PDF**. It opens a clean
summary built from the profile already loaded from the API, including identity,
blood group, allergies, medication, conditions, emergency contacts, physician,
insurance, donor status, responder notes, and last update time.

The summary is deliberately labelled as patient-reported information. It does
not clinically verify data or replace identity, medication, allergy, or legal
directive checks. On Flutter Web, the button opens the browser's standard print
dialog, where the user may choose **Save as PDF**.

## Main files

- `lib/src/features/home/about_lifeguard_page.dart`
- `lib/src/features/home/home_shell.dart`
- `lib/src/features/home/workspace_navigation.dart`
- `lib/src/features/patient_profile/medical_summary_dialog.dart`
- `lib/src/features/patient_profile/patient_medical_id_header.dart`
- `lib/src/core/platform/browser_print*.dart`
- `test/app/emergency_system_app_test.dart`

## Verification

- Flutter analyzer: no issues.
- Flutter tests: **43 passed**.
- Application tests: **6 passed**.
- API integration tests: **23 passed**.
- About navigation, stored patient summary, and responsive Medical ID
  layouts are covered by widget tests.
