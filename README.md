# Medical Emergency Lifeguard System

Thesis project for a role-based emergency medical information, consent, and
audit system.

## Current direction

- **Client:** one responsive Flutter web application for patients, doctors,
  and administrators
- **Backend:** ASP.NET Core 10 Web API
- **Data:** Entity Framework Core and SQL Server
- **Authentication:** ASP.NET Core Identity with server-enforced roles
- **Biometric concept:** a clearly labelled UI simulation; passwords remain the
  only implemented sign-in method and no biometric data is collected
- **Firebase:** not part of the MVP; Cloud Messaging may be added for a later
  patient mobile application
- **AI:** guarded Gemini medical summaries generated through the ASP.NET backend
- **Later client:** a focused Flutter Android/iOS patient application using the
  same API

Ten development checkpoints are implemented. A seeded patient can sign in,
maintain an SQL-backed emergency profile, grant a doctor time-limited access,
revoke it, and inspect the resulting access history. Doctors see only
authorized snapshots, can append clinical encounters, and every opened
snapshot is audited.

Implemented at checkpoint 01:

- layered ASP.NET Core solution targeting .NET 10;
- ASP.NET Core Identity, short-lived JWTs, role policies, lockout, and login
  rate limiting;
- EF Core migration and a normalized SQL Server patient emergency profile;
- responsive Flutter Web sign-in and patient profile view/edit flow;
- optimistic concurrency with HTTP ETags;
- safe synthetic development seed data stored behind local user secrets;
- automated application, API integration, networking, model, controller, and
  widget tests.

Implemented at checkpoint 02:

- patient-selected doctor access lasting from 15 minutes to 24 hours;
- server-enforced expiry, ownership, role checks, and immediate revocation;
- read-only doctor emergency snapshots;
- grant, view, and revoke audit history visible to the patient;
- normalized SQL grant/audit tables and end-to-end authorization tests.

Implemented at checkpoints 03 and 04:

- doctor break-glass access with a required reason, a 15-minute limit, rate
  limiting, and patient-visible auditing;
- append-only doctor clinical encounters with structured vital observations
  and prescriptions;
- read-only patient and doctor clinical timelines linked to the exact access
  grant used.

Implemented at checkpoint 05:

- a real five-minute, one-use Medical ID QR link issued by the server;
- hash-only QR-token persistence and explicit unused-token revocation;
- authenticated doctor redemption into 15 minutes of audited access;
- automatic doctor redemption after the QR opens the Flutter web application.

Implemented at checkpoints 06 to 08:

- administrator account management with server-enforced administrator access;
- browser-camera scanning for the secure Medical ID QR workflow;
- doctor-only, rate-limited AI summaries generated from an actively authorized
  medical record, with clinical verification warnings.

Implemented at checkpoint 09:

- patient upload, listing, download, and soft deletion of PDF, JPEG, and PNG
  medical documents;
- read-only doctor document access enforced by an active patient access grant;
- server validation of file size, extension, MIME type, and binary signature;
- SQL Server document persistence and audited doctor downloads.

Implemented at checkpoint 10:

- an explicitly labelled biometric sign-in simulation on the login screen;
- ready, scanning, success, failure, and cancellation states;
- a security boundary that prevents the simulation from creating a session;
- automated proof that the real authentication repository is never called.

Real WebAuthn/passkeys and production hardening/deployment are future work.

## Start here

1. Use the [checkpoint 01 runbook](docs/DEVELOPMENT_CHECKPOINT_01.md) to run
   and verify the working system.
2. Demonstrate the [checkpoint 02 access workflow](docs/DEVELOPMENT_CHECKPOINT_02.md).
3. Demonstrate the [checkpoint 05 secure QR workflow](docs/DEVELOPMENT_CHECKPOINT_05.md).
4. Review the [checkpoint 08 AI summary workflow](docs/DEVELOPMENT_CHECKPOINT_08.md).
5. Demonstrate the [checkpoint 09 medical-document workflow](docs/DEVELOPMENT_CHECKPOINT_09.md).
6. Demonstrate the [checkpoint 10 biometric simulation](docs/DEVELOPMENT_CHECKPOINT_10.md).
7. Review the [recommended architecture](docs/ARCHITECTURE.md).
8. Follow the [dated thesis execution plan](docs/THESIS_EXECUTION_PLAN.md).
9. Review the [development-environment audit](docs/ENVIRONMENT_SETUP.md).
10. Read the [source-material audit](docs/PROTOTYPE_AUDIT.md) and supply the
   correct medical project-description document.
11. Keep the [biometrics and AI roadmap](docs/BIOMETRICS_AND_AI_ROADMAP.md) as
   the design for a future real passkey implementation.

## Run locally

Open two PowerShell terminals from the repository root:

```powershell
# Terminal 1
.\scripts\run-api.cmd

# Terminal 2
.\scripts\run-web.cmd
```

The fixed Flutter port is important: the development API permits
`http://localhost:5000`, not a random browser origin. The app calls
`http://localhost:5080`.

Run the complete automated checkpoint:

```powershell
.\scripts\verify-all.cmd
```

The same commands are available from VS Code under **Terminal > Run Task**.

For a fresh machine or intentionally reset development database, follow the
secret and migration setup in the checkpoint runbook. Secrets and generated
demo passwords are not committed.

## Flutter platform folders

Flutter generated Android, iOS, web, Windows, Linux, and macOS platform folders
when the project was created. Keeping them does not slow the web application at
runtime: Flutter builds only the selected target. The thesis targets web first;
unused native platforms can remain unbuilt.

## Useful direct checks

```powershell
flutter pub get
flutter analyze
flutter test
flutter build web --release --dart-define=API_BASE_URL=http://localhost:5080
```

## Data and safety

Use synthetic patients only. Never commit real medical data, `.env` files,
database passwords, access tokens, signing keys, or service-account
credentials. Localhost settings in the repository are development defaults and
must be overridden for an HTTPS deployment.
