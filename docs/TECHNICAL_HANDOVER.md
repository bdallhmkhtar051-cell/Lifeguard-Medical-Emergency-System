# LifeGuard Medical Emergency System

## Technical development handover

**Snapshot date:** 12 September 2026

**Repository:** `Lifeguard-Medical-Emergency-System`

**Branch:** `main`

**Base commit:** `80011f1` (`feat: add role-aware workspace navigation`)

**Working milestone:** checkpoint 14 presentation utilities
**Primary local root:** `C:\Users\hp\Documents\flutter projects\my flutter projects\Emergency system\emergency_system`

This document is the source-of-truth handover for continuing development in a
new AI/Codex session. It describes behavior that exists in the repository at
the snapshot commit. Planned ideas are explicitly marked as pending or future
work and must not be presented as implemented.

The current repository has priority over old chat statements, prototype ZIPs,
early checkpoint notes, and thesis plans. The React prototype is a visual
reference only; it is not the implementation or a security specification.

## 1. Product identity, purpose, and scope

### Application name

The product is called **LifeGuard Medical Emergency System**. UI titles also
use **LifeGuard Medical ID**. The Dart package is still technically named
`emergency_system`, and the ASP.NET solution is `EmergencySystem.sln`.

### Main purpose

LifeGuard is a thesis prototype for controlled access to emergency medical
information. It allows:

- a patient to maintain an emergency profile, share time-limited access,
  display a secure QR, inspect access history, review clinical encounters, and
  manage supporting documents;
- a doctor to open records only through consent, a one-use QR, or an audited
  emergency break-glass grant, then review the emergency snapshot, add a
  clinical encounter, review documents, and request a guarded AI summary;
- an administrator to activate/deactivate accounts and review account and
  emergency-access metadata without receiving clinical-record access.

It is a working educational prototype, not a certified clinical, hospital,
dispatch, or public emergency-response product. Use synthetic data only.

### Current project scope

Implemented end-to-end scope:

- API health/startup gate;
- password login with JWT authentication;
- server-enforced Patient, Doctor, and Administrator roles;
- patient emergency profile with optimistic concurrency;
- patient-issued time-limited doctor grants and revocation;
- patient-visible access auditing;
- doctor patient directory and authorized emergency snapshots;
- 15-minute, reason-required break-glass access;
- one-use, five-minute Medical ID QR issuance and redemption;
- browser-camera QR scanning;
- append-only clinical encounters with optional vital signs and prescription;
- patient clinical timeline;
- patient document upload/list/download/soft deletion;
- grant-controlled doctor document list/download;
- temporary, guarded Gemini medical summary;
- administrator account status and audit dashboard;
- explicitly labelled biometric sign-in simulation;
- responsive, role-aware hamburger navigation.
- patient-reported physician, insurance, donor-status, and first-responder
  information shown to patients and authorized doctors.

Not implemented:

- real WebAuthn/passkeys, fingerprint capture, or face recognition;
- self-registration, password reset, refresh tokens, or persistent login;
- doctor access-request/patient approval workflow;
- patient DNR/advance-directive fields or official donor-registry verification;
- AI diagnosis, triage, or treatment advice;
- OCR or AI interpretation of uploaded documents;
- notifications, GPS, ambulance dispatch, EHR interoperability, or Firebase;
- production hosting, production HTTPS configuration, malware scanning,
  backup/restore evidence, or clinical certification.

### Current roles and permissions

| Capability | Patient | Doctor | Administrator |
| --- | --- | --- | --- |
| Sign in with password | Own account | Own account | Own account |
| View/edit emergency profile | Own profile | Read-only through a live grant | No clinical access |
| Issue/revoke consent grants | Yes | No | No |
| Display one-use Medical ID QR | Yes | No | No |
| Scan/redeem Medical ID QR | No | Yes | No |
| Use break-glass | No | Yes, with reason/rate limit/audit | No |
| View clinical encounters | Own history | Through a live grant | No |
| Create clinical encounter/vitals/prescription | No | Through a live grant | No |
| Upload/delete documents | Own documents | No | No |
| Download documents | Own documents | Read-only through a live grant | No |
| Generate AI summary | No | Through a live grant | No |
| View personal access history | Yes | No separate personal-audit screen | Metadata overview only |
| Activate/deactivate accounts | No | No | Other accounts only |
| View account-management audit | No | No | Yes |
| View emergency-access metadata | Own history | Through working access views | Yes, without clinical content |

Flutter hides out-of-role controls, but the authoritative permission checks are
the ASP.NET policies and service-level ownership/grant checks.

## 2. Technology and development environment

### Flutter and Dart

- Flutter stable **3.35.3**
- Dart **3.9.2**
- DevTools **2.48.0**
- `pubspec.yaml` SDK constraint: `^3.9.2`
- Material 3 UI

Important Flutter packages:

| Package | Version constraint | Purpose |
| --- | --- | --- |
| `http` | `^1.6.0` | JSON, multipart, and binary HTTP calls |
| `http_parser` | `^4.1.2` | Multipart MIME type parsing |
| `file_picker` | `^11.0.3` | Browser file selection and save/download flow |
| `mobile_scanner` | `^7.4.0` | Browser camera and QR decoding |
| `qr_flutter` | `^4.1.0` | Rendering the patient Medical ID QR |
| `flutter_lints` | `^5.0.0` | Static-analysis rules |
| `flutter_test` | Flutter SDK | Unit and widget tests |

There is no Provider, Riverpod, Bloc, GetX, GoRouter, Firebase, or local
database package. State is deliberately managed with small `ChangeNotifier`
controllers and feature-local `StatefulWidget` state.

### Target platforms

The thesis target is **Flutter Web first**, normally Chrome at
`http://localhost:5000`. Flutter-generated scaffolding also exists for:

- Android;
- iOS;
- Windows;
- Linux;
- macOS.

Those native folders do not slow the web application at runtime because
Flutter builds only the selected target. They are scaffolding, not verified
native releases. The browser UI is the implemented and tested client.

### Backend and database

- ASP.NET Core Web API targeting **.NET 10.0**
- SDK pinned by `global.json` and `backend/global.json` to **10.0.302**
- Entity Framework Core **10.0.10**
- ASP.NET Core Identity **10.0.10**
- JWT Bearer authentication **10.0.10**
- SQL Server via `Microsoft.EntityFrameworkCore.SqlServer`
- xUnit **2.9.3** for backend tests
- SQLite is used by API integration tests, not by the running application

Development connection string in `backend/src/EmergencySystem.Api/appsettings.json`:

```text
Server=localhost;Database=EmergencySystem;Trusted_Connection=True;
Encrypt=True;TrustServerCertificate=True;MultipleActiveResultSets=True
```

The database name is `EmergencySystem`. Windows trusted authentication is used
locally. SQL Server Management Studio is only a management/viewing tool; the
application talks to SQL Server through EF Core in the ASP.NET backend.

### Local ports and commands

Two terminals are required because the API and Flutter development server are
two long-running processes:

```powershell
# Terminal 1: ASP.NET API
.\scripts\run-api.cmd

# Terminal 2: Flutter Web in Chrome
.\scripts\run-web.cmd
```

- API: `http://localhost:5080`
- Flutter Web: `http://localhost:5000`
- API health: `GET http://localhost:5080/health`
- OpenAPI is mapped only in Development.
- Flutter can override the API through
  `--dart-define=API_BASE_URL=https://...`.
- CORS currently allows exactly `http://localhost:5000`.

Secrets are intentionally absent from Git. The JWT signing key, demo account
passwords, and Gemini key must be supplied through ASP.NET user secrets or
environment configuration. Never place them in Dart or committed JSON.

## 3. Repository structure

```text
/
|-- lib/                              Flutter application
|   |-- main.dart                     Composition root and QR URL parsing
|   `-- src/
|       |-- app/                      Root app and startup controller
|       |-- core/
|       |   |-- config/               Compile-time API base URL
|       |   |-- network/              HTTP client and safe API errors
|       |   |-- theme/                Shared Material theme/tokens
|       |   `-- widgets/              Shared async error panel
|       `-- features/
|           |-- auth/                 Login, session, biometric simulation
|           |-- home/                 Role shell and drawer navigation
|           |-- patient_profile/      Patient model/controller/form/portal
|           |-- access/               Consent, QR, scanner, doctor workspace
|           |-- clinical/             Timeline and encounter editor
|           |-- documents/            Upload/list/download/delete UI
|           |-- administration/       Admin dashboard
|           `-- health/               API health repository
|-- test/                             Flutter unit/widget tests and fakes
|-- backend/
|   |-- EmergencySystem.sln
|   |-- src/
|   |   |-- EmergencySystem.Api/      Controllers, middleware, rate limits
|   |   |-- EmergencySystem.Application/ DTOs, validators, interfaces
|   |   |-- EmergencySystem.Domain/   Entities/enums
|   |   `-- EmergencySystem.Infrastructure/
|   |       |-- services, Identity, EF Core, Gemini, seeding, migrations
|   `-- tests/
|       |-- EmergencySystem.Application.Tests/
|       `-- EmergencySystem.Api.Tests/
|-- docs/                             Architecture, runbooks, checkpoints
|-- scripts/                          Run, configure, migrate, verify scripts
|-- web/                              Flutter Web host shell and manifest
|-- android/ ios/ windows/ linux/ macos/  Generated native scaffolding
|-- pubspec.yaml
|-- global.json
`-- README.md
```

Generated `build/`, `.dart_tool/`, backend `bin/obj`, locally generated PDFs,
and secrets are not application source.

## 4. Main architecture pattern

The product is a **web-first layered modular monolith**:

```text
Flutter widget
    -> controller or feature-local state
    -> repository interface
    -> API repository implementation
    -> shared ApiClient
    -> HTTPS/JSON, multipart, or binary HTTP
    -> ASP.NET controller
    -> Application interface/validator
    -> Infrastructure service
    -> EF Core DbContext
    -> SQL Server
```

The backend is divided into API, Application, Domain, and Infrastructure
projects. It is not microservices. Flutter never connects directly to SQL
Server and never receives database or Gemini credentials.

### Current Frontend Architecture

`lib/main.dart` is the composition root. It creates one `ApiClient`, concrete
API repository objects, `SessionController`, and `AppController`, then injects
them into `EmergencySystemApp`. There is no service locator or global mutable
singleton.

The exact flow is:

1. A widget receives user input and performs immediate form validation.
2. A long-lived controller (`AppController`, `SessionController`,
   `PatientProfileController`, or `WorkspaceNavigationController`) or local
   widget state records loading/error/data status.
3. The widget/controller calls a repository interface such as
   `PatientProfileRepository` or `AccessRepository`.
4. Its `Api...Repository` implementation converts Dart models to/from the
   backend JSON contract and calls `ApiClient`.
5. `ApiClient` resolves the path against `AppConfig.apiBaseUri`, adds the
   in-memory Bearer token, applies a 15-second timeout, decodes JSON/problem
   details, and maps failures to `ApiException`.
6. A protected HTTP `401` schedules `SessionController.expireSession()`, which
   clears token/user/expiry and returns the root widget to the login page.
7. The notifier or local widget calls `notifyListeners`/`setState`, and the UI
   rebuilds with data, an error, or progress feedback.

Repositories are thin transport boundaries. Business authorization,
grant-expiry checks, document validation, account status, audit creation, and
clinical validation remain on the server.

### State management

- `AppController`: checking/online/offline startup health state.
- `SessionController`: signed out/signing in/signed in/signing out, current
  user, token expiry display value, and authentication errors.
- `PatientProfileController`: profile, ETag, load/save flags, server field
  errors, and concurrency messages.
- `WorkspaceNavigationController`: selected role-safe drawer destination.
- Other feature pages use private `StatefulWidget` fields for request data,
  busy state, errors, dialogs, and selections.
- `ListenableBuilder` connects `ChangeNotifier` state to widgets.

State is in memory. There is no persistence, hydration, Redux-style store, or
client cache of medical data.

### Repository/service/controller/model organization

Each Flutter feature normally contains:

- `*_models.dart` or a domain-named model file;
- a repository interface;
- an `Api...Repository` implementation in the same file;
- a page/panel/dialog that consumes the interface;
- a controller only where state is shared or complex enough to justify it.

Backend controllers are HTTP-only adapters. Application contracts/interfaces
define use cases and DTOs. Infrastructure services enforce and persist the use
cases. Domain entities contain stored state.

### Navigation and routing

There is no named-route or URL-route framework. `MaterialApp.home` displays a
single root state machine:

```text
API checking -> offline/retry OR login -> authenticated HomeShell -> role page
```

`HomeShell` chooses exactly one page from the authenticated role:

- Patient -> `PatientProfilePage`
- Doctor -> `DoctorAccessPage`
- Administrator -> `AdministrationPage`

Its hamburger drawer uses `WorkspaceNavigationController`. Patient drawer
destinations map to the existing four portal tabs. The doctor QR destination
opens a dialog and returns the selected destination to Authorized Patients.
No UI control switches a logged-in patient into a doctor or administrator
portal.

The one special URL input is a Medical ID token. `main.dart` reads
`medicalQr` primarily from the URL fragment and secondarily from the query
string. A signed-in doctor automatically redeems it during doctor-page
initialization.

### Responsive design strategy

- Pages use `SafeArea`, centered `ConstrainedBox` containers (usually 1200 px),
  scrolling, `Wrap`, and `LayoutBuilder` rather than fixed desktop canvases.
- Login switches from split brand/form at 900 px to one scrollable form.
- Patient overview uses two columns from 760 px and one below it.
- Patient editor groups fields responsively with `Wrap`/`LayoutBuilder`.
- Administrator accounts use a table from 760 px and cards below it.
- App-bar identity text hides below 760 px.
- QR scanner preview height is derived from viewport height and its dialog is
  scrollable, resolving the previous 67-pixel bottom overflow.
- The hamburger drawer is available at desktop and narrow widths.
- The doctor directory provides name search, access-status filters, live result
  counts, and rows that stack their action button below 620 px.

The automated narrow-width baseline is 390 px. Patient navigation, the Medical
ID card, QR scanner, and doctor credential/directory have explicit narrow tests.

### Reusable widgets/components

- `AsyncErrorPanel`: standardized error plus optional retry action.
- `BrandMark`: login/startup health-and-safety mark.
- `PatientMedicalIdHeader`: major patient identity card and actions.
- `ClinicalHistoryPanel`: reusable timeline for patient and doctor views.
- `MedicalDocumentsPanel`: patient-write or doctor-read-only mode based on
  `doctorGrantId`.
- `MedicalQrDialog`, `MedicalQrScannerDialog`, `ClinicalEncounterDialog`,
  `AiMedicalSummaryDialog`, `BiometricSimulationDialog`.
- App-private cards, badges, metrics, drawer tiles, and record rows remain
  private to their feature files.

## 5. Screens and implemented features

Status vocabulary:

- **Finished:** implemented end-to-end for thesis scope and automated tests.
- **Partial:** works but has identified manual-test or production gaps.
- **Simulation:** deliberately visual only; does not perform the real action.
- **Planned:** no current end-to-end implementation.

### Startup and offline gate

- **Files:** `lib/src/app/emergency_system_app.dart`,
  `lib/src/app/app_controller.dart`, `lib/src/features/health/health_repository.dart`
- **Classes:** `EmergencySystemApp`, `_AppRoot`, `_StartupPage`, `_OfflinePage`,
  `AppController`, `ApiHealthRepository`
- **Behavior:** checks the backend before exposing login; shows a deliberate
  loading page, then login or a retryable offline panel. It explicitly states
  that no medical data is cached.
- **API:** `GET /health`, without authorization.
- **State:** `ApiAvailability.checking/online/offline`; duplicate health checks
  are prevented.
- **Status:** Finished for startup. Later network loss is feature-local, not a
  global offline state.

### Login

- **Files:** `lib/src/features/auth/login_page.dart`, `auth_repository.dart`,
  `auth_models.dart`, `session_controller.dart`
- **Classes:** `LoginPage`, `_LoginFormPanel`, `SessionController`,
  `ApiAuthRepository`, `AppUser`, `LoginResult`
- **Behavior:** validates email/password, submits credentials, shows progress
  and a generic safe rejection, toggles password visibility, and uses browser
  autofill hints.
- **API:** `POST /api/v1/auth/login`. `GET /api/v1/auth/me` exists in the
  repository/backend but normal startup does not restore a prior session.
- **State/validation:** email required and syntactically valid; password
  required; controls disabled while signing in; server login rate limit is
  5 attempts/minute/IP and Identity locks an account after 5 failures for 15
  minutes.
- **Status:** Finished for password login. Registration/reset/remember-me are
  not implemented.

### Biometric sign-in preview

- **File:** `lib/src/features/auth/biometric_simulation_dialog.dart`
- **Class:** `BiometricSimulationDialog`
- **Behavior:** demonstrates ready, scanning, success, failure, and cancel UI.
  It waits 1.4 seconds to simulate verification and instructs the user to
  continue with a password.
- **API:** none.
- **Security state:** cannot call the authentication repository or create a
  session; collects no face/fingerprint/camera/Windows Hello data.
- **Status:** Simulation. Real passkeys are future work.

### Authenticated shell and role-aware drawer

- **Files:** `lib/src/features/home/home_shell.dart`,
  `lib/src/features/home/workspace_navigation.dart`
- **Classes:** `HomeShell`, `_WorkspaceDrawer`, `_PortalNavigation`,
  `WorkspaceNavigationController`, `WorkspaceDestination`
- **Behavior:** renders role-specific app bar, hamburger drawer, active
  destination, identity/role label, and sign out.
- **API:** no direct endpoint; logout clears local JWT. Child pages call their
  own APIs.
- **State:** destination initialized from the authenticated single role.
- **Status:** Finished. This navigation was checkpoint 11; checkpoint 14 is the
  current latest milestone.

### Patient Medical ID portal and overview

- **Files:** `lib/src/features/patient_profile/patient_profile_page.dart`,
  `patient_medical_id_header.dart`, `emergency_profile.dart`
- **Classes:** `PatientProfilePage`, `_PatientPortal`, `_PortalTabs`,
  `_OverviewGrid`, `PatientMedicalIdHeader`, `EmergencyProfile`, `Allergy`,
  `MedicalCondition`, `Medication`, `EmergencyContact`
- **Behavior:** loads the patient's real SQL-backed profile; displays name,
  date of birth, blood group, allergies, current medications, conditions, ICE
  contacts, physician, insurance, donor status, first-responder notes, update
  time, edit/refresh, QR, and ICE-contact actions.
- **API:** `GET /api/v1/patients/me/emergency-profile`.
- **State:** initial spinner; retry panel when no profile; non-blocking warning
  when stale data remains after refresh error; medical data is cleared from
  controller memory on disposal.
- **Status:** Finished for current profile fields.

### Patient profile editor

- **Files:** `lib/src/features/patient_profile/patient_profile_form.dart`,
  `patient_profile_controller.dart`, `patient_profile_repository.dart`
- **Classes:** `PatientProfileForm`, private draft/editor widgets,
  `PatientProfileController`, `ApiPatientProfileRepository`,
  `VersionedEmergencyProfile`
- **Behavior:** edits blood group and complete replacement lists for allergies,
  conditions, medications, and emergency contacts. It also edits optional
  physician, insurance, donor-status, and responder information. Identity
  fields are shown but managed separately. Dirty cancel asks for confirmation.
- **API:** `PUT /api/v1/patients/me/emergency-profile` with `If-Match: <ETag>`.
- **State/validation:** save/loading flags, server field errors, required blood
  group, required names, allergy severity, contact relationship/phone, length
  bounds, at most one primary contact, and server validation. A stale ETag
  becomes an actionable reload message. Child database IDs and timestamps are
  omitted from update JSON.
- **Status:** Finished for the checkpoint 12 schema. Legally binding directive
  fields remain deliberately excluded.

### Patient access permissions and audit

- **Files:** `lib/src/features/access/patient_access_panel.dart`,
  `access_repository.dart`, `access_models.dart`
- **Class:** `PatientAccessPanel`
- **Behavior:** lists eligible doctors, grants 30-minute/1-hour/4-hour/24-hour
  access, lists active/inactive grants, revokes active grants, and expands an
  access-history list.
- **API:**
  - `GET /api/v1/patients/me/emergency-access`
  - `POST /api/v1/patients/me/emergency-access`
  - `POST /api/v1/patients/me/emergency-access/{grantId}/revoke`
- **State:** local selected doctor email/duration, busy/error/dashboard data;
  action controls disable while busy.
- **Status:** Finished. Doctor-initiated requests are not implemented.

### Patient secure QR generation

- **Files:** `lib/src/features/access/medical_qr_dialog.dart`,
  `access_repository.dart`
- **Classes:** `MedicalQrDialog`, `MedicalQrAccess`
- **Behavior:** requests a five-minute one-use raw token, places it in a same-
  origin URL fragment, renders a QR, copies the link, and attempts revocation
  whenever the explicit close action is used. The dialog cannot be dismissed
  through the ordinary barrier/back path.
- **API:**
  - `POST /api/v1/patients/me/medical-qr`
  - `POST /api/v1/patients/me/medical-qr/revoke`
- **State:** issue/retry/copy/closing; token remains memory-only on the client;
  backend stores SHA-256 hash only.
- **Status:** Finished for thesis scope.

### Patient clinical history

- **Files:** `lib/src/features/clinical/clinical_history_panel.dart`,
  `clinical_repository.dart`, `clinical_models.dart`
- **Classes:** `PatientClinicalHistory`, `ClinicalHistoryPanel`,
  `ClinicalEncounter`, `ClinicalObservation`, `ClinicalPrescription`
- **Behavior:** fetches and displays an encounter timeline with doctor,
  complaint, notes, disposition, vital signs, and prescriptions.
- **API:** `GET /api/v1/patients/me/clinical-records`.
- **State:** load spinner, error message, empty state, loaded timeline.
- **Status:** Finished and read-only for patients.

### Patient medical documents

- **Files:** `lib/src/features/documents/medical_documents_panel.dart`,
  `document_repository.dart`, `document_models.dart`
- **Classes:** `MedicalDocumentsPanel`, `_DocumentDetailsDialog`,
  `ApiDocumentRepository`, `MedicalDocument`
- **Behavior:** picks PDF/JPEG/PNG with bytes, asks for category/optional
  description, uploads multipart data, lists metadata, downloads through the
  browser save flow, confirms deletion, and removes deleted items from UI.
- **API:**
  - `GET /api/v1/patients/me/documents`
  - `POST /api/v1/patients/me/documents` (multipart field `file`, plus
    `category` and optional `description`)
  - `GET /api/v1/patients/me/documents/{documentId}/content`
  - `DELETE /api/v1/patients/me/documents/{documentId}`
- **State/validation:** one panel-wide busy state; supported extensions in the
  picker; category set; description max 500. Server enforces maximum 5 MB,
  maximum 25 active documents, extension/MIME/signature agreement, ownership,
  and allowed type.
- **Status:** Finished for thesis scope, partial for production security.

### Doctor directory and access workspace

- **File:** `lib/src/features/access/doctor_access_page.dart`
- **Classes:** `DoctorAccessPage`, `_ClinicianCredential`, `_PatientDirectory`,
  `_PatientDirectoryRow`, `_ClinicalSnapshot`
- **Behavior:** concurrently loads all directory patients and the doctor's
  active grants. A row opens an existing authorized EHR or offers break-glass.
  The selected snapshot displays patient emergency data, access type/reason,
  expiry, clinical history, action buttons, and read-only documents.
- **API:**
  - `GET /api/v1/doctors/emergency-access`
  - `GET /api/v1/doctors/emergency-access/directory`
  - `GET /api/v1/doctors/emergency-access/{grantId}/snapshot`
  - `GET /api/v1/doctors/emergency-access/{grantId}/clinical-records`
  - doctor document endpoints listed below
- **State:** lists, selected access/snapshot, history, error, and one page-wide
  busy flag. Opening a record revalidates the grant on the backend and creates
  audit data.
- **Status:** Finished. Search/filter/grouping is pending.

### Doctor QR scanner and automatic redemption

- **Files:** `lib/src/features/access/medical_qr_scanner_dialog.dart`,
  `doctor_access_page.dart`, `lib/main.dart`
- **Classes/functions:** `MedicalQrScannerDialog`, `extractMedicalQrToken`,
  `_sameWebOrigin`, `DoctorAccessPage._redeemMedicalQr`
- **Behavior:** opens browser camera, scans QR only, validates the full scanned
  URL against the current web origin, extracts the token, redeems it, opens the
  snapshot, and displays a 15-minute confirmation. A QR URL opened directly is
  also redeemed after a doctor signs in.
- **API:** `POST /api/v1/doctors/emergency-access/medical-qr/redeem`.
- **State/errors:** duplicate scan ignored; unrelated/malformed QR rejected
  locally; expired/revoked/used tokens get a specific message; camera errors
  show permission recovery guidance. Backend endpoint is rate-limited.
- **Status:** Implemented and widget-tested. Physical webcam/permission behavior
  remains a manual browser test.

### Emergency break-glass

- **Files:** `lib/src/features/access/doctor_access_page.dart`,
  `access_repository.dart`
- **Classes:** `_BreakGlassDialog`, `DoctorAccessPage._breakGlass`
- **Behavior:** for a locked directory patient, asks the doctor for a specific
  reason, creates temporary emergency access, and opens the snapshot.
- **API:** `POST /api/v1/doctors/emergency-access/break-glass`.
- **State/validation:** reason required and at least 20 characters in Flutter;
  max 500; backend also validates. Access lasts 15 minutes and attempts are
  rate-limited to 3 per 5 minutes/IP. Actor, reason/grant, and later use are
  server-audited.
- **Status:** Finished for prototype scope.

### Doctor encounter creation, vital signs, and prescription

- **Files:** `lib/src/features/clinical/clinical_encounter_dialog.dart`,
  `clinical_repository.dart`, `clinical_models.dart`, `doctor_access_page.dart`
- **Classes:** `ClinicalEncounterDialog`, `ClinicalEncounterDraft`,
  `ClinicalObservation`, `ClinicalPrescription`
- **Behavior:** creates one append-only encounter during active access. It
  captures chief complaint, clinical notes, optional disposition, optional
  vitals, and zero or one prescription through the current UI. The saved record
  is prepended to the doctor timeline.
- **API:** `POST /api/v1/doctors/emergency-access/{grantId}/clinical-records`.
- **State/validation:** complaint and notes require at least 3 characters;
  limits are 200 and 2000; optional vital ranges are temperature 25-45 C,
  heart rate 20-250, systolic 40-300, diastolic 20-200, oxygen 50-100, and
  respiratory rate 4-80. If any prescription field is used, medication,
  dosage, frequency, and duration are required. Backend revalidates all fields,
  event date, doctor, and live grant.
- **Status:** Finished. Edit/correction/version history and multiple
  prescriptions in one UI submission are not implemented.

### Guarded AI medical summary

- **Files:** `lib/src/features/access/ai_medical_summary_dialog.dart`,
  `doctor_access_page.dart`, `access_repository.dart`,
  `backend/src/EmergencySystem.Infrastructure/Ai/GeminiMedicalSummaryService.cs`
- **Classes:** `AiMedicalSummaryDialog`, `AiMedicalSummary`,
  `GeminiMedicalSummaryService`
- **Behavior:** an authorized doctor requests a plain-text emergency handover
  based only on the current emergency snapshot and five most recent clinical
  encounters. It shows a prominent verification disclaimer, provider model,
  and temporary status. The result is not stored in the clinical record.
- **API:** `POST /api/v1/doctors/emergency-access/{grantId}/ai-summary`, which
  then calls Google Gemini server-to-server.
- **State/safety:** current default model setting is `gemini-3.7-flash`;
  provider key remains server-side; 5 requests per 5 minutes per authenticated
  subject; prompt forbids inference, diagnosis, and treatment; formatting is
  cleaned to remove Markdown markers.
- **Status:** Implemented. Automated API tests use a deterministic fake. A live
  Gemini request requires a configured secret, internet access, and explicit
  approval before sending even synthetic medical data externally.

### Doctor medical documents

- **Files:** `lib/src/features/documents/medical_documents_panel.dart`,
  `document_repository.dart`, `doctor_access_page.dart`
- **Behavior:** the shared document panel switches to read-only mode when given
  `doctorGrantId`; doctor can list/download but cannot upload/delete.
- **API:**
  - `GET /api/v1/doctors/emergency-access/{grantId}/documents`
  - `GET /api/v1/doctors/emergency-access/{grantId}/documents/{documentId}/content`
- **State/security:** grant is rechecked by backend; successful doctor download
  is audited; protected file response is marked `no-store` server-side.
- **Status:** Finished for prototype scope.

### Administrator dashboard

- **Files:** `lib/src/features/administration/administration_page.dart`,
  `administration_repository.dart`, `administration_models.dart`
- **Classes:** `AdministrationPage`, `_UserTable`, `_UserCard`, `_SummaryCard`,
  `ApiAdministrationRepository`
- **Behavior:** loads accounts, account-status audit, and emergency-access audit
  in parallel; displays totals; activates/deactivates another account after
  confirmation; provides refresh and responsive table/card forms.
- **API:**
  - `GET /api/v1/admin/users`
  - `PUT /api/v1/admin/users/{userId}/status`
  - `GET /api/v1/admin/account-audit`
  - `GET /api/v1/admin/access-audit`
- **State/security:** dashboard loading/error, set of user IDs being updated,
  action SnackBars; current administrator cannot deactivate self; server rotates
  target security stamp so existing JWT fails on its next API request. Admin
  audit contains metadata, not clinical content.
- **Status:** Finished for activation/deactivation. Account creation, deletion,
  role assignment, and audit filtering/paging UI are not implemented.

## 6. Authentication and role workflow

1. Root health check must succeed.
2. `LoginPage` sends email/password without an Authorization header.
3. ASP.NET Identity verifies active account, password, lockout, and roles.
4. Backend returns a signed HS256 JWT, token type, seconds to expiry, and safe
   current-user DTO.
5. `SessionController` stores the JWT only inside `ApiClient`; it is never put
   in `localStorage`, cookies, or a Dart persistent store.
6. `HomeShell` derives the page and drawer from `AppUser.singleRole`.
7. Backend role policies independently enforce every protected controller.
8. On logout, Flutter clears token, user, and expiry even if network is down.
   There is intentionally no API logout endpoint for the stateless JWT.
9. Any protected 401 schedules local expiry and returns to login with
   `Your session expired. Please sign in again.`

The access token default lifetime is 15 minutes. There is no refresh token and
no background expiration timer; an expired token is recognized on the next
protected request. Browser refresh always loses the in-memory session.

Supported roles are exactly `Patient`, `Doctor`, and `Administrator`. Flutter
rejects a user that has no supported single role rather than guessing access.

## 7. Core system workflows

### Patient consent

Patient login -> Access Permissions -> choose doctor/duration -> create grant
-> doctor sees active access -> doctor opens snapshot -> server audits view ->
patient sees audit -> patient revokes -> future doctor access is denied.

### QR consent

Patient displays QR -> server returns raw one-use token and stores only hash ->
QR contains same-origin URL fragment -> doctor scans or opens URL -> doctor
authenticates -> server atomically redeems valid unused token -> server creates
15-minute `QrConsented` grant -> snapshot opens and use is audited -> explicit
patient dialog close revokes any unused current token.

### Break-glass

Doctor chooses locked patient -> supplies reason -> backend verifies role,
reason, and rate limit -> creates 15-minute `BreakGlass` grant -> opens snapshot
-> patient/admin audit surfaces metadata. It is not a hidden bypass.

### Clinical record

Doctor opens a live grant -> creates encounter -> Flutter and backend validate
-> encounter is saved with doctor, patient, and exact grant foreign keys ->
patient and authorized doctor timelines read it. Current records are append-only
through the exposed API; there is no edit/delete endpoint.

### Documents

Patient selects allowed file -> metadata dialog -> multipart upload -> backend
validates ownership/type/size/signature/count -> SQL stores metadata and bytes
-> patient may download or soft-delete -> active-grant doctor may list/download
-> doctor download creates access audit.

## 8. Backend Dependencies

The frontend contract is path- and JSON-field-sensitive. Renaming endpoints,
enum strings, DTO keys, or required response headers without changing the Dart
repository/model will break the stated feature.

| Frontend feature | Backend dependency | Breaking-change effect |
| --- | --- | --- |
| Startup | `GET /health` | App stays on offline/retry screen |
| Login | `POST /api/v1/auth/login`; keys `accessToken`, `tokenType`, `expiresInSeconds`, `user` | Sign-in becomes protocol/rejection error |
| Current user helper | `GET /api/v1/auth/me` | Future session validation/restore helper fails; current cold start does not call it |
| Patient profile | GET/PUT `/api/v1/patients/me/emergency-profile`; response `ETag`; PUT `If-Match` | Load/save fails; missing ETag is deliberately treated as protocol error |
| Patient grant dashboard | GET/POST `/api/v1/patients/me/emergency-access` | Doctor choices/grants/audit or grant creation fails |
| Patient revoke | POST `/api/v1/patients/me/emergency-access/{id}/revoke` | Active grant cannot be revoked from UI |
| Patient QR | POST `/api/v1/patients/me/medical-qr`; POST `/revoke`; keys `token`, `expiresAtUtc` | QR cannot render/revoke |
| Doctor list | GET `/api/v1/doctors/emergency-access` | Existing authorizations disappear/error |
| Doctor directory | GET `/api/v1/doctors/emergency-access/directory` | Patient directory cannot render |
| Break-glass | POST `/api/v1/doctors/emergency-access/break-glass`; `patientProfileId`, `reason` | Emergency override fails |
| QR redemption | POST `/api/v1/doctors/emergency-access/medical-qr/redeem`; `token` | Scanner/direct-link flow fails after decoding |
| Snapshot | GET `/api/v1/doctors/emergency-access/{grantId}/snapshot` | Authorized EHR cannot open |
| Patient clinical history | GET `/api/v1/patients/me/clinical-records` | Patient timeline fails |
| Doctor clinical history | GET `/api/v1/doctors/emergency-access/{grantId}/clinical-records` | Snapshot history fails |
| Encounter creation | POST same doctor clinical path; draft JSON | Saving encounter fails or model parsing fails |
| AI summary | POST `/api/v1/doctors/emergency-access/{grantId}/ai-summary`; summary/model/disclaimer/timestamp | Summary dialog fails; provider/config errors appear as safe API error |
| Patient documents | GET/POST `/api/v1/patients/me/documents`; GET `/{id}/content`; DELETE `/{id}` | List/upload/download/delete fails |
| Doctor documents | GET `.../{grantId}/documents`; GET `.../{grantId}/documents/{id}/content` | Read-only record attachments fail |
| Administration | `/api/v1/admin/users`, user status PUT, account-audit, access-audit | Dashboard load or selected action fails |

Shared contract requirements:

- Enum strings are parsed exactly (`Patient`, `Doctor`, `Administrator`,
  `Consented`, `QrConsented`, `BreakGlass`, and backend audit values).
- Dates must be ISO-8601 parseable.
- IDs are serialized as strings/Guids.
- JSON must use the current camel-case names.
- File content endpoints must return bytes; multipart upload field must remain
  `file`.
- CORS must allow `Authorization`, `Content-Type`, `If-Match`,
  `If-None-Match`, methods GET/POST/PUT/DELETE/OPTIONS, and expose `ETag`.
- ProblemDetails `detail`, `title`, `code/type`, `traceId`, and `errors` are
  safely mapped when present.

## 9. Current database entities and relationships

Application tables:

| Entity/table | Main relationships and behavior |
| --- | --- |
| `PatientProfiles` | One-to-one with `AspNetUsers` through unique `UserId`; includes physician, insurance, donor status, and first-responder notes; owns medical lists, grants, QR tokens, encounters, documents; `Version` is concurrency token |
| `Allergies` | Many-to-one patient; cascade with patient |
| `MedicalConditions` | Many-to-one patient; cascade with patient |
| `Medications` | Many-to-one patient; cascade with patient |
| `EmergencyContacts` | Many-to-one patient; cascade with patient |
| `EmergencyAccessGrants` | Many-to-one patient; required doctor user; access type/reason/granted/expiry/revoked; owns audits; linked to encounters |
| `AccessAuditEvents` | Many-to-one grant; required actor user; append-only action/time |
| `MedicalQrTokens` | Many-to-one patient; optional redeeming doctor; optional unique one-to-one grant; unique SHA-256 `TokenHash`; concurrency token |
| `ClinicalEncounters` | Many-to-one patient, doctor, and exact access grant; owns optional observation and prescriptions |
| `ClinicalObservations` | Optional one-to-one encounter through unique `ClinicalEncounterId` |
| `Prescriptions` | Many-to-one encounter |
| `MedicalDocuments` | Many-to-one patient and uploader user; bytes plus metadata; soft deletion clears content in service logic |
| `AccountAdministrationEvents` | Required administrator and target Identity users; append-only status action/time |

ASP.NET Identity also creates:

- `AspNetUsers` (extended by `DisplayName`, `IsActive`, `CreatedAtUtc`);
- `AspNetRoles`;
- `AspNetUserRoles`;
- `AspNetUserClaims`;
- `AspNetRoleClaims`;
- `AspNetUserLogins`;
- `AspNetUserTokens`.

Important delete behavior: patient-owned medical collections generally
cascade with the patient profile; doctor/uploader/actor/admin user links use
`Restrict` to preserve authorship/audit history.

Applied source migrations are:

1. `20260728104911_InitialCreate`
2. `20260822074542_AddEmergencyAccess`
3. `20260902101505_AddBreakGlassAccess`
4. `20260905085640_AddClinicalWorkflow`
5. `20260907084702_AddMedicalQrAccess`
6. `20260907194120_AddAdministrationModule`
7. `20260908183102_AddMedicalDocuments`
8. `20260912142846_AddPatientEmergencyInformation`

## 10. Error, offline, loading, dialog, and browser behavior

### HTTP errors

`ApiClient` maps:

- 400/422 -> validation;
- 401 -> unauthorized plus scheduled session clearing;
- 403 -> forbidden;
- 404 -> not found;
- 409/412 -> conflict;
- 5xx -> generic server message without exposing internal details;
- timeout/network/protocol -> safe local messages.

Feature pages generally catch `ApiException` and show inline errors,
`AsyncErrorPanel`, SnackBars, or dialog retry state. Login deliberately changes
all 401 details to `The email or password is incorrect.`

### Offline handling

The initial health failure has a dedicated retry screen. Medical information
is not cached for offline access. After login, each feature handles a failed
request locally; there is no connectivity listener, request queue, automatic
retry, or offline edit synchronization.

### Loading states

- startup connection spinner;
- login button spinner/disabled controls;
- patient profile initial spinner and save spinner;
- access/doctor/admin page busy states;
- QR issue and scanner placeholders;
- documents linear progress indicator;
- clinical timeline spinner.

Some complex pages use one broad busy flag, so one action can temporarily
disable more controls than strictly necessary. This is acceptable but can be
refined later.

### Dialogs

Current dialogs cover biometric simulation, QR display, QR scanner, break-
glass reason, encounter creation, AI summary, document metadata, document
deletion, account status confirmation, dirty profile discard, ICE contacts,
and other small confirmations/feedback.

### Browser-specific behavior

- Camera access works on `localhost` during development; deployed camera use
  requires HTTPS and browser permission.
- Camera frames stay inside the browser; only decoded QR text reaches Dart.
- Patient and doctor QR pages must use the same origin because the scanner
  deliberately rejects other origins.
- Tokens are held only in JavaScript memory by the compiled Flutter app.
- Refreshing the page signs the user out.
- File selection/download depends on browser dialogs and `file_picker` web
  behavior.
- The web manifest supports standalone installation, but PWA/offline behavior
  is not implemented as an application feature.

## 11. Current Test Coverage

### Last completed full verification

The checkpoint 14 verification completed on 12 September 2026 reported:

- Flutter analyzer: no issues;
- Flutter tests: **43 passed**;
- backend Application tests: **6 passed**;
- backend API integration tests: **23 passed**;
- ASP.NET solution build: zero warnings and zero errors;
- Flutter Web release build: passed;
- the new EF migration was applied to local SQL Server.

### Flutter test inventory

`test/app/emergency_system_app_test.dart`:

- offline health retry;
- invalid login validation/error;
- narrow mobile login;
- biometric simulation never signs in;
- doctor cannot receive patient editor;
- patient view/edit/save/sign-out;
- patient drawer destination navigation;
- authenticated 390 x 760 navigation;
- doctor/admin drawer role isolation;
- admin review/deactivation.

`test/core/network/api_client_test.dart`:

- configured health URL without auth;
- Bearer token attachment;
- validation ProblemDetails/field errors;
- 412 conflict mapping;
- safe 5xx behavior;
- unauthorized callback/session behavior.

Feature tests:

- auth models and `SessionController` success/rejection/expiry clearing;
- emergency profile parsing/update JSON/optional arrays;
- patient profile repository GET ETag and PUT `If-Match`;
- profile controller load/save, stale ETag, sensitive-state clearing;
- Medical ID header narrow layout and ICE contact behavior;
- break-glass reason requirement;
- same-origin QR parsing, patient QR/revoke, short scanner dialog, automatic QR
  redemption after login, and camera workflow through a test seam;
- clinical timeline contents;
- patient document metadata/deletion.
- doctor patient-directory search, authorization filters, result counts, and
  narrow-layout overflow protection.
- authenticated About LifeGuard navigation and stored emergency-summary view.

There is no golden/screenshot test, end-to-end browser automation suite, or
coverage threshold.

### Backend test inventory

Application validator tests (5):

- valid/invalid emergency profiles, future DOB, primary contacts, collections,
  and E.164 phone;
- valid/invalid encounter, impossible vitals, and incomplete prescription.

API integration tests (23):

- health, login/me, generic invalid-password response;
- role denial for patient/admin/QR/break-glass routes;
- admin deactivation, self-deactivation denial, account audit, access metadata;
- patient profile save, stale/missing ETag, invalid-save atomicity;
- grant -> doctor view -> audit -> revoke denial;
- guarded AI with fake provider;
- document validation, ownership, doctor grant/download audit, deletion;
- break-glass reason/audit/access and rate limiting;
- one-use QR grant/audit/revocation/role boundaries;
- encounter creation/read and denial without active grant;
- exact CORS-origin behavior.

API tests use an in-memory SQLite database and test authentication setup via
`EmergencySystemApiFactory`; they do not prove production SQL Server behavior.

### Manual testing still required

- physical laptop-camera scan of a QR shown on the phone;
- camera denied/allowed/revoked permission in the actual target Chrome profile;
- browser download/save behavior for PDF/JPEG/PNG in presentation environment;
- visual review at several narrow and short sizes, especially doctor directory,
  snapshot action rows, long names, and long clinical text;
- live Gemini summary with explicit permission and synthetic data;
- complete demo with all three seeded accounts after a clean database setup;
- production HTTPS/CORS/origin configuration;
- native Android/iOS/desktop builds (out of current thesis scope);
- accessibility testing with keyboard, screen reader, zoom, and contrast tools.

## 12. Important UI Decisions Already Made

Preserve these unless the user explicitly requests a redesign:

1. One responsive Flutter web application serves all three roles.
2. The authenticated role controls the workspace; there is no insecure visual
   patient/doctor portal switch.
3. The React ZIP is a visual inspiration for navy/blue/teal clinical styling,
   cards, hierarchy, icons, texture, and hamburger navigation—not a source of
   mock security or fake medical behavior.
4. Core palette lives in `AppTheme`: navy `#0F172A`, slate `#1E293B`, canvas
   `#F1F5F9`, border `#E2E8F0`, blue `#2563EB`, teal `#0F766E`.
5. Patient presentation uses blue; clinician presentation uses teal; emergency
   override actions use restrained red.
6. Patient Medical ID header is the main visual identity surface and should
   remain real-data-driven.
7. The hamburger drawer exposes only safe destinations for the logged-in role.
8. Patient tab buttons and drawer selections stay synchronized.
9. No medical data is persisted in browser storage.
10. QR secrets use URL fragments, are one-use and short-lived, and are checked
    against the same origin.
11. Break-glass is explicit, reason-required, short-lived, and audited.
12. Administrator access does not imply clinical access.
13. AI output is temporary, plain text, clinician-only, and visibly requires
    human verification.
14. Biometrics are honestly labelled as a simulation and cannot authenticate.
15. Generated platform folders may remain; web is still the only current
    release target.

## 13. Known Problems and Pending Work

### Known limitations/risks in current frontend

1. **QR fragment is not removed after redemption.** `lib/main.dart` reads the
   token and `DoctorAccessPage` redeems it, but browser history/address cleanup
   is not implemented. The token is one-use and short-lived, yet removing it
   after processing would be cleaner.
2. **No automatic token-expiry timer.** `SessionController.expiresAtUtc` is
   recorded, but expiry is acted on only after a protected request returns 401.
3. **Page refresh signs out.** This is a deliberate effect of memory-only JWTs,
   but should be explained during the demonstration.
4. **Later network loss is not globally detected.** Only startup health has a
   full offline page. Feature actions show their own errors.
5. **Doctor directory narrow layout needs physical visual QA.**
   `_PatientDirectoryRow` in `doctor_access_page.dart` combines name/status and
   a labelled button in one `Row`; unusually narrow widths or long localized
   text may overflow. It is not a currently reproduced failure.
6. **Patient top tabs can become dense.** They use `Flexible` and ellipsis, and
   the drawer offers an accessible alternative, but four horizontal tabs at
   very narrow widths may truncate labels.
7. **One broad busy flag per feature.** Doctor and document panels may disable
   unrelated controls during a request.
8. **Download result feedback is limited.** A cancelled/unsupported browser
   save dialog may not give a dedicated success/cancel message.
9. **No camera retry button inside the open scanner.** Permission guidance asks
   the user to close, change permission, and reopen.
10. **No structured Markdown rendering for AI.** This is intentional; backend
    now asks for and cleans plain text after earlier output displayed `**`.
11. **No URL routing/deep-link state beyond QR token parsing.** Browser back and
    refresh do not preserve the selected portal tab or selected patient.
12. **No localization.** All UI is English and some widths assume current text.
13. **No complete accessibility preferences.** Some Semantics/tooltips exist,
    but text scaling, high contrast, reduced motion, focus order, and screen
    reader coverage remain pending.

### Backend/production gaps affecting the frontend

- Local CORS permits only `http://localhost:5000`; any different Flutter port
  causes browser-blocked calls until `Cors:AllowedOrigins` is updated.
- Remote camera use needs HTTPS.
- Gemini fails safely if key/model/network is unavailable.
- Documents lack malware scanning/content disarm, OCR, encryption deployment
  evidence, external object storage, and version history.
- Audit lists do not expose filtering/pagination UI; admin overview returns the
  latest limited set.
- There is no refresh-token/revocation-list architecture; security-stamp
  validation handles deactivated users on subsequent API requests.
- Real passkeys are not implemented.

### Pending feature milestones

1. **Accessibility/settings:** text-size, high contrast, reduced motion, session
   information, keyboard and screen-reader verification.
2. **Optional access request:** doctor request -> patient approve/reject ->
   expiry/purpose/status/audit. Existing direct patient grant already meets the
   essential consent use case.
3. **Final verification/evidence:** manual workflows, screenshots, security
   cases, deployment configuration, and thesis handover/test tables.

## 14. Next Steps in Priority Order

1. Manually inspect the drawer and role isolation in Chrome using patient,
   doctor, and administrator demo accounts.
2. Complete the phone-to-laptop physical QR scan and camera-permission checks.
3. Add accessibility/settings after core content is stable.
4. Add doctor access requests only if thesis time remains.
5. Perform final security, browser, responsive, SQL Server, deployment, and
   thesis-evidence verification.
6. Update this handover, `README.md`, checkpoint docs, and Chapter 4-6 evidence
    after each genuinely completed milestone.

## 15. Important Files to Read First

Recommended reading order for the next AI:

1. `docs/TECHNICAL_HANDOVER.md` (this document)
2. `README.md`
3. `pubspec.yaml`
4. `lib/main.dart`
5. `lib/src/app/emergency_system_app.dart`
6. `lib/src/core/network/api_client.dart`
7. `lib/src/features/auth/session_controller.dart`
8. `lib/src/features/home/home_shell.dart`
9. `lib/src/features/home/workspace_navigation.dart`
10. `lib/src/features/patient_profile/patient_profile_page.dart`
11. `lib/src/features/access/doctor_access_page.dart`
12. All six frontend repository files (`auth`, `patient_profile`, `access`,
    `clinical`, `documents`, `administration`)
13. `backend/src/EmergencySystem.Api/Program.cs`
14. All files in `backend/src/EmergencySystem.Api/Controllers/`
15. `backend/src/EmergencySystem.Infrastructure/DependencyInjection.cs`
16. `backend/src/EmergencySystem.Infrastructure/Persistence/ApplicationDbContext.cs`
17. Current Domain entities and Application contracts for the feature being
    changed
18. Relevant Infrastructure service and EF configuration/migration
19. `test/helpers/fakes.dart` and relevant Flutter tests
20. `backend/tests/EmergencySystem.Api.Tests/ApiIntegrationTests.cs`
21. `docs/DEVELOPMENT_CHECKPOINT_01.md` through `_11.md`, remembering that later
    checkpoints supersede older limitation statements
22. `docs/ARCHITECTURE.md` and `docs/THESIS_EXECUTION_PLAN.md`

Before editing a feature, use `rg` to locate every reference to its model,
route, DTO key, test fake, and endpoint.

## 16. Changes From Earlier Versions

- The project moved from an empty Flutter starter to a real Flutter Web +
  ASP.NET Core + SQL Server system.
- Firebase was removed from the MVP architecture. It may only be useful later
  for mobile push notifications; ASP.NET remains the source of truth.
- One web application with authenticated role routing replaced the prototype's
  insecure visual portal switch.
- Doctor and administrator placeholder landings were replaced with working
  doctor access/clinical and administrator account/audit modules.
- Consent grants, revocation, auditing, and break-glass became server-enforced,
  not simulated UI.
- Clinical history, encounters, vitals, and prescriptions were added as real
  SQL-backed records.
- The patient QR placeholder became a five-minute, one-use, hash-only token
  workflow. Later, checkpoint 7 added the built-in browser camera scanner, so
  checkpoint 5's statement that no scanner exists is obsolete.
- The scanner dialog was changed to be scrollable with viewport-dependent
  preview height after a 67-pixel bottom-overflow report.
- Administrator account activation/deactivation and audit views became real.
- Gemini AI summary became an implemented guarded server feature. After poor
  output containing Markdown asterisks, the prompt and backend cleanup were
  changed to enforce readable plain text.
- Medical document upload/list/download/soft-delete and doctor read-only access
  were added. CORS was updated to allow DELETE so Flutter Web deletion works.
- The proposed biometric feature was deliberately reduced to an honest UI
  simulation. It must never be described as real face/fingerprint/passkey
  authentication.
- Checkpoint 11 added the role-aware dark hamburger drawer and synchronized it
  with patient tabs and the doctor scanner.
- Checkpoint 12 added patient-reported physician, insurance, donor-status, and
  first-responder information across SQL Server, ASP.NET, Flutter, authorized
  doctor views, and guarded AI input. It deliberately did not add DNR/DNI.
- Checkpoint 13 added doctor-directory search and access filters, responsive
  credential/directory layouts, QR privacy guidance, and clearer AI safety
  guidance without changing the server-enforced access model.
- Checkpoint 14 added a role-neutral About LifeGuard presentation page and a
  patient-only printable summary of the already loaded SQL-backed profile. The
  summary explicitly labels its information as patient reported.
- The correct latest commit is `80011f1`; do not use the earlier mistyped
  `800codes1` identifier.

## 17. Git and workspace state at handover

- Remote: `https://github.com/bdallhmkhtar051-cell/Lifeguard-Medical-Emergency-System.git`
- Repository is private according to the project setup history; verify access
  in GitHub rather than assuming from the remote URL alone.
- Checkpoint 14 follows base commit `3111550`; use `git log -1 --oneline` for
  the exact checkpoint commit identifier.
- Locally generated thesis PDF/output artifacts were untracked:
  `LifeGuard_Thesis_Handover.pdf` and `output/`. Do not commit them unless the
  user explicitly decides to version generated evidence.
- This Markdown handover is intended to be versioned with checkpoint 14.

Recent history before this file:

```text
80011f1 feat: add role-aware workspace navigation
3c96d0c feat: add biometric sign-in simulation
ff5712e fix: allow document deletion from Flutter web
c066e1b feat: add secure medical document management
2695b86 fix: improve AI summary readability
a45c0a9 feat: add guarded AI medical summaries
395269c fix: make Medical ID scanner fit short screens
b0f7ad2 feat: scan Medical ID QR codes with web camera
c2ad26f feat: add secure administrator account management
17ad8c1 feat: add secure one-use Medical ID QR access
02346b2 feat: establish verified LifeGuard system baseline
```

## 18. Rules for the Next AI

The next AI must:

1. Treat the current repository as the primary source of truth.
2. Inspect existing code, tests, contracts, migrations, and checkpoint notes
   before creating or replacing code.
3. Preserve working functionality and the current security boundaries.
4. Avoid rewriting major sections unnecessarily; make the smallest coherent
   end-to-end change.
5. Keep Flutter and backend behavior synchronized whenever a DTO, validation
   rule, enum, path, or workflow changes.
6. Report a breaking API/schema/security/UI change before making it.
7. Clearly distinguish implemented behavior, partial behavior, simulations,
   planned work, and future research.
8. Never invent a backend endpoint or claim an API behavior without inspecting
   the controller/service/test.
9. Keep role authorization on the server; hiding Flutter widgets is not access
   control.
10. Never restore the prototype's free patient/doctor portal switch, plaintext
    PIN, fake GPS/SMS/dispatch, or unverified clinical decision support.
11. Never describe the biometric dialog as real authentication.
12. Never send medical data to Gemini or another external service without the
    existing backend safeguards and explicit permission for a live test.
13. Never commit real patient data, credentials, tokens, connection secrets,
    Gemini keys, database passwords, or generated secret configuration.
14. Preserve memory-only token handling unless the user explicitly accepts a
    reviewed alternative threat model.
15. Add/update Flutter tests, Application tests, API integration tests, and
    documentation in proportion to every change.
16. Run analysis/tests after changes and report exact results; do not turn an
    interrupted or partial run into a passing claim.
17. Preserve user changes and unrelated dirty-worktree files.
18. Use comments for security or non-obvious intent, not narration of obvious
    syntax.
19. Keep explanations simple enough for the thesis author to present, while
    leaving exact paths and contracts for technical continuation.
20. Do not call this a production-ready medical device. It is a thesis system
    prototype with real implemented workflows and explicitly documented limits.

## 19. Continuation checklist

When a new session starts:

- confirm `git status --short` and `git log -1 --oneline`;
- read this file and the latest checkpoint;
- confirm Flutter/Dart/.NET versions;
- ensure local secrets exist without printing them;
- start API and web on the fixed ports;
- sign in with synthetic accounts only;
- inspect the feature and its tests before editing;
- implement one bounded milestone across all necessary layers;
- run verification;
- manually exercise browser-specific behavior when relevant;
- update the handover/checkpoint/README;
- commit only the intended source files with a clear message.
