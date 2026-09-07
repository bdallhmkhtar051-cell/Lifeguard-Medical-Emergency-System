# Development checkpoint 01: secure patient profile

Checkpoint date: 2026-07-28

## Outcome

The repository has moved beyond the generated Flutter baseline. The first
working vertical slice connects:

```text
Flutter Web :5000
        |
        | HTTP/JSON + short-lived bearer token + ETag
        v
ASP.NET Core API :5080
        |
        | EF Core 10
        v
SQL Server / EmergencySystem
```

A synthetic patient can sign in, load an emergency profile, edit its normalized
medical and contact data, and persist the update. Doctor and administrator demo
accounts receive separate roles. The API, rather than Flutter visibility,
enforces patient-only profile modification.

This is a thesis development prototype. It is not a certified clinical,
emergency-dispatch, or production medical system.

## Implemented scope

### Backend

- .NET 10 layered modular-monolith solution: Domain, Application,
  Infrastructure, API, and two test projects.
- ASP.NET Core Identity users and Patient, Doctor, and Administrator roles.
- Password sign-in and a 15-minute JWT access token.
- Active-user and security-stamp validation on authenticated requests.
- Five-attempt Identity lockout and five-login-attempts-per-minute IP rate
  limit.
- Exact development CORS origin: `http://localhost:5000`.
- RFC-style problem responses, bounded request bodies, and no-store API
  caching.
- Patient emergency-profile GET and PUT endpoints with ownership policy,
  validation, and optimistic concurrency.

### Data

- SQL Server database: `EmergencySystem` on local default instance
  `localhost`.
- EF Core migration: `20260728104911_InitialCreate`.
- Identity tables plus `PatientProfiles`, `Allergies`,
  `MedicalConditions`, `Medications`, and `EmergencyContacts`.
- Strong profile ETag backed by a concurrency token.
- Synthetic development seed enabled only by local user secrets in Development
  or Testing.

### Flutter Web

- API startup/health state with retry and an honest offline message.
- Responsive sign-in screen with accessible validation and error states.
- In-memory access token; no JWT is written to browser local storage.
- Fail-closed role routing.
- Patient emergency-profile view and edit flow.
- Constrained blood-group and allergy-severity choices.
- ETag precondition support, including concurrent-update feedback.
- Doctor and administrator landing states that do not expose the patient
  editor.

## Local setup

The current development laptop is already configured. For a fresh checkout:

1. Install Flutter compatible with Dart 3.9 and a .NET 10 SDK.
2. Start a local SQL Server instance reachable as `localhost`, or override the
   backend connection string outside Git.
3. Generate local development secrets:

   ```powershell
   .\scripts\configure-development-secrets.cmd
   ```

4. Create/update the database:

   ```powershell
   .\scripts\update-database.cmd
   ```

The secret script generates new demo passwords and prints them once. It stores
them, along with a random JWT signing key, in .NET user secrets outside Git.
Never place those values in Dart, `appsettings.json`, screenshots, or commits.

## Run the system

From the repository root, use two PowerShell terminals.

Terminal 1:

```powershell
.\scripts\run-api.cmd
```

Wait for `Now listening on: http://localhost:5080`.

Terminal 2:

```powershell
.\scripts\run-web.cmd
```

The browser opens `http://localhost:5000`. The fixed port matches the backend's
development CORS allowlist. Starting Flutter on a random port will correctly be
rejected by the browser.

The seeded account emails are:

| Role | Email |
| --- | --- |
| Patient | `patient.demo@emergency.test` |
| Doctor | `doctor.demo@emergency.test` |
| Administrator | `admin.demo@emergency.test` |

Passwords are local user secrets and are intentionally absent from source
control.

## API checkpoint

| Method | Route | Access | Purpose |
| --- | --- | --- | --- |
| GET | `/health` | Public | Local readiness check |
| POST | `/api/v1/auth/login` | Public, rate limited | Password sign-in |
| GET | `/api/v1/auth/me` | Authenticated | Current identity and roles |
| GET | `/api/v1/patients/me/emergency-profile` | Patient | Read own profile and ETag |
| PUT | `/api/v1/patients/me/emergency-profile` | Patient | Create/update own profile with a precondition |

The PUT operation uses `If-Match` for an existing profile and `If-None-Match:
*` for creation. A stale ETag receives 412; a missing required precondition
receives 428.

## Verification evidence

The checkpoint was verified on 2026-07-28:

- backend: 11 tests passed (3 application + 8 API integration);
- Flutter: 25 tests passed;
- `flutter analyze`: no issues;
- Flutter Web release build: succeeded;
- Flutter WebAssembly compatibility dry run: succeeded;
- NuGet vulnerability audit: no known vulnerable packages;
- .NET build/format verification: clean;
- SQL migration history: EF Core 10.0.10 migration present;
- SQL seed counts: 3 users, 3 roles, 1 profile, 1 allergy, 1 condition,
  1 medication, and 1 emergency contact.

Live API checks also proved:

- health returned 200;
- invalid credentials returned 401;
- patient login and `/auth/me` returned 200;
- patient profile GET and PUT returned 200;
- the profile ETag changed after update;
- a doctor token calling the patient self-profile route returned 403.

Repeat the automated checks with:

```powershell
.\scripts\verify-all.cmd
```

## Important code map

| Area | Location |
| --- | --- |
| API composition and security policies | `backend/src/EmergencySystem.Api/Program.cs` |
| Login and current-user endpoints | `backend/src/EmergencySystem.Api/Controllers/AuthController.cs` |
| Patient profile endpoints | `backend/src/EmergencySystem.Api/Controllers/EmergencyProfileController.cs` |
| Profile business validation | `backend/src/EmergencySystem.Application/Profiles/EmergencyProfileValidator.cs` |
| EF Core model | `backend/src/EmergencySystem.Infrastructure/Persistence/ApplicationDbContext.cs` |
| Demo seeding | `backend/src/EmergencySystem.Infrastructure/Seeding/DemoDataSeeder.cs` |
| Flutter app/session orchestration | `lib/src/app/app_controller.dart` |
| HTTP behavior | `lib/src/core/network/api_client.dart` |
| Patient profile feature | `lib/src/features/patient_profile/` |

Comments in code explain non-obvious security and concurrency decisions. The
tests are also useful executable explanations of expected behavior.

## Known boundaries

- The supplied Word brief describes a shop ERP, not this medical system. The
  correct medical requirements document is still required before freezing
  thesis wording and optional scope.
- Consent, access requests, emergency snapshot, break-glass, append-only audit,
  doctor encounters, and account administration are not implemented yet.
- Passkeys are scheduled only after the password/authorization foundation.
- AI and Firebase are not part of the MVP.
- The committed localhost configuration is for development. A deployment must
  use HTTPS, a deployment-specific API URL, strict deployed CORS origins,
  production secrets, and a production database configuration.
- Generated Flutter platform folders do not affect web runtime performance.
  Android/iOS releases remain later work; iOS requires a Mac.
- Default Flutter app icons and native `com.example` identifiers must be
  replaced before a branded PWA or mobile release.

## Next development slice

Build the consent and access-audit foundation vertically:

1. patient creates a time-limited consent grant for a doctor;
2. doctor is denied before consent and permitted while it is valid;
3. patient revokes consent and the doctor is denied again;
4. every request, grant, denial, view, and revocation creates an append-only
   server audit event;
5. patient can view the access history in Flutter.

That slice proves the thesis's central privacy/emergency-access contribution
before adding clinical records or passkeys.
