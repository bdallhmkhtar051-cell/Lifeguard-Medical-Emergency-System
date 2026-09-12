# Development checkpoint 12: patient emergency information

**Completed:** 12 September 2026

## Outcome

LifeGuard now stores and displays additional patient-reported information that
can help coordinate emergency care:

- primary physician name and international phone number;
- insurance provider and policy/member number;
- organ-donor status with explicit `Unknown`, `Donor`, and `NotDonor` values;
- first-responder notes.

The fields are available in the patient editor, patient overview, authorized
doctor snapshot, guarded AI-summary input, ASP.NET contracts, and SQL Server.

## Safety boundary

These details are informational and patient reported. The interface tells the
user to confirm them with official sources. Donor status does not replace an
official registry. Legally binding DNR/DNI or advance-directive functionality
was deliberately not added because it requires separate legal, clinical, and
institutional requirements.

## End-to-end implementation

- `PatientProfile` owns the six new SQL fields.
- `OrganDonorStatus` provides a safe three-state enum.
- `EmergencyProfileValidator` validates text lengths, enum values, and optional
  physician phone numbers in international E.164 form.
- Application request/response contracts and `EmergencyProfileMapper` expose
  the fields consistently.
- `EmergencyProfileService` normalizes blank optional values to `null`.
- Flutter's `EmergencyProfile` parses, copies, and serializes the new values.
- `PatientProfileForm` includes a responsive Emergency Coordination section.
- The patient overview and authorized doctor snapshot display the information.
- The guarded AI record includes the same authorized fields.

## Database migration

Migration:

`20260912142846_AddPatientEmergencyInformation`

The migration adds nullable physician, insurance, and responder-note columns
to `PatientProfiles`. `OrganDonorStatus` is required and safely initializes
existing profiles to `Unknown`.

The migration was successfully applied to the local SQL Server
`EmergencySystem` database on 12 September 2026.

## Verification

- ASP.NET solution build: passed with zero warnings and zero errors.
- Application tests: **6 passed**.
- API integration tests: **23 passed**.
- Flutter analyzer: no issues found.
- Flutter tests: **39 passed**.
- Flutter Web release build: passed.
- EF Core migration: applied successfully to local SQL Server.

Tests cover optional-field validation, persistence through the profile API,
exposure in authorized doctor snapshots, Dart parsing/serialization, and the
patient edit/save workflow while preserving all previous workflows.

## Presentation workflow

1. Sign in as the patient and edit the emergency profile.
2. Open **Emergency coordination** and enter only synthetic physician,
   insurance, donor, and responder information.
3. Save and show the two new overview cards.
4. Grant a doctor temporary access.
5. Sign in as that doctor and show the same information in the read-only EHR.
6. Explain that the API rechecks the active grant and that all values are
   patient reported, not legally verified directives.
