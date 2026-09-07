# Development environment audit

Audit date: 2026-07-28

## Current machine status

| Area | Status | Notes |
| --- | --- | --- |
| Flutter | Ready | Stable 3.35.3 with Dart 3.9.2; project is pinned locally to the clean `C:\tools\flutter` copy |
| VS Code | Ready | Dart, Flutter, C#, C# Dev Kit, and SQL Server extensions are installed |
| Web target | Ready | Chrome and Edge are detected; local development uses web port 5000 |
| ASP.NET Core | Ready | .NET SDK 10.0.302 is installed project-locally and pinned by `global.json` |
| SQL Server | Ready | SQL Server 2022 Developer is running; `EmergencySystem` is migrated and seeded |
| SQL tools | Ready | SSMS and the VS Code MSSQL extension are installed |
| Git | Ready locally | Repository is initialized on `main`; the initial checkpoint is being committed |
| Thesis remote | Action pending | A private GitHub remote requires one interactive account sign-in |
| Android | Later | Internet permission is prepared, but no emulator/device is configured and Gradle has an Avast certificate blocker |
| iOS | Requires a Mac | Xcode and Apple signing are unavailable on Windows |
| Windows desktop | Not required | The thesis is web-first; missing C++ workload does not block it |
| Firebase | Not required now | Do not install Firebase tooling for the MVP |
| Face/passkey demo | Hardware detected | Windows Hello facial-recognition device and HP IR camera are present; Hello enrollment must still be confirmed |
| Fingerprint demo | External device needed | No fingerprint reader was detected; use an enrolled Android phone if available |

## Already-installed VS Code support

The important extensions are present:

- Dart
- Flutter
- C#
- C# Dev Kit
- MS SQL
- GitLens and Error Lens as optional helpers

The workspace recommendations now match the selected Flutter + ASP.NET + SQL
Server architecture. More extensions will not make the system better; add one
only when a concrete workflow needs it.

## Completed backend foundation

### .NET 10

The Microsoft .NET 10.0.302 SDK is installed under the ignored `.dotnet`
directory. Both repository `global.json` files pin this SDK. Repository scripts
use that copy first and fall back to a compatible system `dotnet` command.

```powershell
.\.dotnet\dotnet.exe --info
```

The local SDK is intentionally not committed. A new development machine must
install a .NET 10 SDK either system-wide or under `.dotnet`.

### SQL Server

The selected local instance is the default `localhost` SQL Server 2022
Developer instance. The development connection uses Windows integrated
authentication and encrypted transport with local certificate trust. EF Core
applied migration `20260728104911_InitialCreate` to database
`EmergencySystem`.

The verified synthetic dataset contains three users, three roles, one patient
profile, and one related allergy, condition, medication, and contact. Apply
later migrations with:

```powershell
.\scripts\update-database.cmd
```

### Local secrets and demo seed

The JWT signing key and demo passwords are stored with .NET user secrets
outside this repository. On a fresh machine and fresh development database,
generate new values with:

```powershell
.\scripts\configure-development-secrets.cmd
```

The script prints newly generated synthetic demo passwords once. Do not use
`-Force` against an existing seeded database unless the database is also reset,
because changing configuration does not rewrite existing Identity passwords.

### VS Code workflow

Workspace recommendations cover Dart, Flutter, C#, C# Dev Kit, SQL Server,
GitLens, Error Lens, and YAML. `tasks.json` supplies:

- API run on port 5080;
- Flutter Web run on port 5000;
- development-secret configuration;
- EF migration application;
- complete backend/Flutter verification.

`launch.json` supplies a Chrome Flutter debug configuration with the matching
API URL and web origin.

### Source control

The institutional guideline explicitly requires GitHub or GitLab. The local
repository uses branch `main`; its private GitHub remote is completed only
after the developer authorizes GitHub CLI through the browser. Bitbucket can be
a mirror, but should not be the sole thesis repository unless the supervisor
accepts it in writing.

## Flutter SDK note

Two Flutter SDK copies were found:

- clean project SDK: `C:\tools\flutter`
- damaged old copy under the user's Downloads folder

The ignored `.vscode/settings.json` pins this workspace to the clean SDK.
Reopen VS Code and confirm the Flutter status bar uses `C:\tools\flutter`.
The current SDK can begin the thesis; schedule any Flutter upgrade at a clean
checkpoint and rerun all tests rather than changing it during a critical demo
week.

## Android blocker for later mobile work

An Android build reached Gradle, but the Android Studio JDK did not trust the
certificate presented after Avast HTTPS inspection. When Android work begins:

1. Configure an approved Avast HTTPS-scanning exception for the relevant Java
   process and official Gradle/Maven/Google repositories, or use an
   administrator-approved trust-store process.
2. Do not disable TLS validation and do not use plain HTTP repositories.
3. Create an Android emulator or connect a physical device.
4. Re-run `flutter build apk --debug`.

This does not block the web-first thesis.

## Verification commands

```powershell
flutter doctor -v
.\scripts\verify-all.cmd
.\.dotnet\dotnet.exe --info
git status
```

Checkpoint 01 passed backend tests, Flutter analysis and tests, a release web
build, a Wasm compatibility dry run, SQL migration verification, and live
role/ETag API checks. See
[DEVELOPMENT_CHECKPOINT_01.md](DEVELOPMENT_CHECKPOINT_01.md) for exact evidence.

## Not required now

- Firebase CLI
- FlutterFire CLI
- Node.js for application development
- Firebase Data Connect
- a Windows native build toolchain
- iOS tooling on this Windows machine

If Firebase Cloud Messaging is added for a later mobile phase, introduce only
the messaging capability after the core web/API/SQL system is stable.

## Biometric test preparation

The target is WebAuthn/passkey authentication, not raw biometric capture. Before
the scheduled passkey work:

1. Confirm Windows Hello Face can enroll and unlock the development laptop.
2. Identify an Android phone with an enrolled fingerprint for a second-device
   test, if available.
3. Use HTTPS on the deployed test domain.
4. Keep password/recovery access available.
5. Follow [BIOMETRICS_AND_AI_ROADMAP.md](BIOMETRICS_AND_AI_ROADMAP.md) for the
   implementation and test boundaries.
