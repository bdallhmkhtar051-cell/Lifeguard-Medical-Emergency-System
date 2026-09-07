# Checkpoint 03 — audited break-glass emergency access

## Outcome

A doctor can now obtain a 15-minute, read-only emergency snapshot when patient
consent cannot be obtained. This is a real server-enforced workflow, not a UI
simulation.

The doctor must select a patient and enter a specific reason of 20–500
characters. ASP.NET creates a `BreakGlass` grant, stores the reason in SQL
Server, and appends a `BreakGlassActivated` audit event. Opening the snapshot
adds the existing `Viewed` event. The patient can see the doctor, reason,
access type, time, expiry, and later views in the access dashboard.

## Security rules

- Only an authenticated account with the `Doctor` role can call the endpoint.
- A reason shorter than 20 characters or longer than 500 is rejected.
- An override cannot be created while that doctor already has active access.
- Break-glass access lasts exactly 15 minutes and remains read-only.
- Three override attempts are allowed per IP address in five minutes.
- Emergency responses use `Cache-Control: no-store`.
- Flutter never decides whether access is valid; it only displays the API
  result.
- The original medical record is never modified by this workflow.

## Data and API

Migration: `20260902101505_AddBreakGlassAccess`

New grant fields:

- `AccessType`: `Consented` or `BreakGlass`
- `EmergencyReason`: nullable for consent, required by the break-glass service

New doctor endpoints:

| Method | Route | Purpose |
| --- | --- | --- |
| GET | `/api/v1/doctors/emergency-access/directory` | Minimum patient directory for emergency selection |
| POST | `/api/v1/doctors/emergency-access/break-glass` | Validate and create a 15-minute override |

Existing snapshot and patient-audit endpoints return the access type and
emergency reason.

## Flutter workflow

1. Sign in as the doctor.
2. A patient without active consent is labelled `RECORD LOCKED`.
3. Select **Break glass**.
4. Read the warning and enter a specific emergency reason.
5. Select **Activate for 15 minutes**.
6. The read-only snapshot opens with a red emergency label and the audited
   reason.
7. Sign in as the patient and open **Access permissions** to see the override
   and audit history.

## Verification

- Backend build: clean with zero warnings and zero errors.
- Backend tests: 15 total after this checkpoint (3 application and 12 API).
- Flutter analyzer: no issues.
- Flutter tests: 27 passed, including dialog validation and snapshot display.
- Flutter Web release build: successful.
- SQL Server migration applied to the local `EmergencySystem` database.
- Live demo verification returned a `BreakGlass` snapshot and the patient
  dashboard contained both `BreakGlassActivated` and `Viewed` events.

The integration tests prove successful override, short-reason rejection,
wrong-role rejection, rate limiting, snapshot access, and patient-visible audit
records.

## Important implementation locations

- Domain type: `EmergencySystem.Domain/Access/EmergencyAccessType.cs`
- Service rules: `EmergencySystem.Infrastructure/Access/EmergencyAccessService.cs`
- API endpoints: `EmergencySystem.Api/Controllers/DoctorAccessController.cs`
- SQL migration: `EmergencySystem.Infrastructure/Persistence/Migrations/20260902101505_AddBreakGlassAccess.cs`
- Flutter workflow: `lib/src/features/access/doctor_access_page.dart`
- API tests: `backend/tests/EmergencySystem.Api.Tests/ApiIntegrationTests.cs`
- Flutter test: `test/features/access/doctor_break_glass_test.dart`

## Deliberate limitations

This is a thesis prototype, not unrestricted hospital access. The directory
contains only the minimum patient identifier and name. Production deployment
would additionally require institutional clinician verification, monitoring,
incident review, legal policy, and stronger operational controls.
