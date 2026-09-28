# LifeGuard final verification report

## Latest repository verification — 28 September 2026

The source and tests prepared for the final repository commit passed **93 tests: 13 application, 25 API integration and 55 Flutter**, with zero failures. Backend Release compilation, dependency restore and Flutter analysis passed. The Flutter Web release build produced `build/web`; a separately captured build completed with exit code 0.

Evidence: [full run](../thesis/verification-2026-09-28-full.log) and [confirmed release build](../thesis/verification-2026-09-28-web-build.log). PowerShell's first output-capture wrapper returned exit code 1 after treating Flutter's informational Wasm notice on stderr as a native-command error, despite the successful build. The direct build confirmation resolved that capture ambiguity. No application code was changed during this verification.

The 27 September local startup checks returned HTTP 200 from both the web root and API health endpoint. SQL Server startup and health evidence below remains dated 22 September; live startup was not repeated as part of the 28 September automated suite. Manual checks and evaluation limitations below still apply.

Application source, migrations, tests, verification transcripts and the screenshot caption index are included in version control. Thesis writing handovers, generated documents, screenshot images/archives and browser profiles remain local. The existing technical handover was removed from the current tracked tree while preserving the local file; older Git commits retain its previous contents.

## Previous full verification — 22 September 2026

**Evidence review and fresh run:** 22 September 2026
**Source:** local working tree based on commit `4f90c77a9af35c4bec1da5a706bbe699270af687`, with subsequent uncommitted changes.

## Executive result

The complete verification of the current QR and break-glass code passed **93 tests** (13 application, 25 API integration and 55 Flutter). Flutter static analysis and the Web release build also passed. The local API started against SQL Server and returned HTTP 200 from `/health`.

The 15 September run recorded 76 passing tests and one biometric-preview timeout. The corrected test passed in the full 16 September suite (77 tests), whose log also ends with a successful Web build. These are historical results, not the basis for the 22 September current-code result.

Missing manual evidence does not mean a feature is missing or was never tested. Screenshots and user-reported success are recorded separately from specifically verified test sequences.

## Fresh results

| Check | Result on 22 September | Evidence |
|---|---|---|
| Backend Release restore/build | Passed | Raw transcript |
| Application tests | 13 passed; no failures/skips | Raw transcript |
| API integration tests | 25 passed; no failures/skips | Raw transcript |
| Flutter dependency restore | Passed | Raw transcript |
| Flutter static analysis | Passed; no issues found | Raw transcript |
| Flutter tests | 55 passed, 0 failed | Raw transcript; QR, access and biometric tests included |
| Flutter Web release build | Passed | `Built build\web` in raw transcript |
| Live API and SQL Server startup | Passed | Development API queried SQL Server tables and listened on port 5080 |
| Live local health request | Passed | HTTP 200: `{"status":"healthy","service":"EmergencySystem.Api"}` |

Local startup and SQL observations are recorded in [live-api-sql-check-2026-09-22.md](../thesis/live-api-sql-check-2026-09-22.md). This is a diagnostic record, not an independently captured server-log transcript.

Fresh raw output: [verification-2026-09-22-full.log](../thesis/verification-2026-09-22-full.log). Historical logs: [16 September passing run](../thesis/verification-2026-09-16.log) and [15 September failed run](../thesis/verification-2026-09-15.log). Previously reported focused tests are subsets of the current suites; do not add their counts to 93.

The first successful 22 September run was captured by a PowerShell transcript that retained only wrapper output, not the child process's test lines. The same script was rerun without code changes and its full output was captured directly in the linked log: 13 + 25 + 55 passed, analysis passed, and `build/web` was produced. The incomplete wrapper transcript is not used as raw evidence.

The first 22 September attempt stopped during NuGet restore because the sandbox could not reach the vulnerability-data service (`NU1900`); its [transcript](../thesis/verification-2026-09-22.log) is preserved. The authorized network-enabled rerun completed successfully. A first sandboxed API startup also lacked Windows Event Log access; outside the sandbox the API and SQL connection succeeded. These environmental failures do not change the successful rerun result.

Reproduction from repository root:

```powershell
.\scripts\verify-all.cmd
```

### Historical failure and test correction on 16 September

Test: `biometric preview is clearly simulated and never signs in`.
File: `test/app/emergency_system_app_test.dart:81`.
Failure: `pumpAndSettle timed out`.

The camera placeholder contains an indefinitely animated loading spinner in the widget-test environment. Waiting for all animations to settle before selecting the fingerprint tab therefore timed out. On 16 September the test was changed to pump the dialog transition for a bounded interval before selecting the existing fingerprint test path. The focused test passed. Its existing failure/success and no-sign-in assertions remain, with additional checks that continuing returns to the login page without authenticating. Application camera/simulation code was not changed. The researcher separately confirmed the real browser preview works; this is manual evidence, not a camera-device test performed by the widget suite.

### Historical checks and boundaries

The 13 September report recorded local configuration alignment and a basic secret-pattern scan; those checks were not repeated today. Today's live startup established SQL Server connectivity and health, while the automated API integration suite still uses **in-memory SQLite** and a **fake AI summary provider**. Neither the suite nor the health check verifies live Gemini.

## Automated coverage and important limits

Primary source: `backend/tests/EmergencySystem.Api.Tests/ApiIntegrationTests.cs`; setup: `EmergencySystemApiFactory.cs` in the same folder.

| Area | Inspected automated evidence | Limit |
|---|---|---|
| Login and roles | Credential rejection, role restrictions, administrator self-deactivation protection | Not a full security audit |
| Patient profile | Save, validation and stale ETag rejection | Test persistence uses SQLite |
| Consent | Grant, authorized snapshot, revoke, then snapshot rejection | Not a manually timed expiry check |
| QR | Temporary issue/redemption/reuse rules and permanent-ID identity-only, rotation and access-gating checks | Widget and API tests do not exercise a physical camera or printed card |
| Documents | Disguised-file rejection, 128 KB synthetic PDF upload, doctor upload, download, audit, deletion and subsequent not-found | Download checks PDF prefix, not full byte equality or saved-file validity |
| Administrator | Deactivation rejects existing session and new login, with audit | Inspected test does not complete reactivation/restored login |
| AI | Authorization and guarded output using fake provider | Not live Gemini or clinical-accuracy verification |
| Clinical records | Authorized creation/read and unauthorized creation rejection; break-glass denial of clinical tools | Synthetic content, not clinical validation |
| Break-glass | Minimum-necessary data shaping and denial of history, documents and AI through an emergency grant | Not a clinical safety certification or manually timed expiry test |
| Flutter | Selected UI, controller, role navigation, permanent QR, foldable grants, narrow layout and biometric simulation checks | Not actual browser permissions, screen reader or printing |

## Manual evidence reconciliation

References correspond to the 35 active screenshots and `thesis/SCREENSHOT_CAPTIONS.md`, including the 21 September permanent-QR and minimum-necessary break-glass update. The researcher confirmed in Chrome that the updated emergency-only view, normal-consent route, grant-list layout, revocation closure and camera shutdown worked with synthetic data. These are user-reported observations, not a signed test register for every negative case.

| ID | Check | Available evidence | Remaining specific confirmation |
|---|---|---|---|
| M01 | Patient portal | 01-08 show overview/history/editor; user reported walkthrough success | Screens themselves are evidenced; do not repeat merely to prove they exist |
| M02 | Edit and refresh | Editor and validation images; automated save tests | Before/save/reload observation |
| M03 | Consent lifecycle | 11-12 show collapsible controls and an active grant; automated grant/use/revoke/deny passed; researcher reported prompt closure after revocation | Separately timed expiry and a fully recorded browser sequence |
| M04 | QR on phone | 13 shows the temporary consent QR; 13_02 shows the permanent emergency ID | Actual phone display confirmation if claimed as a device test |
| M05 | Physical QR scan | 22 shows the dual scanner; 22_02 shows permanent-identity confirmation; researcher reported successful permanent-QR routing | A dated, step-by-step device record if the thesis claims formal physical testing |
| M06 | QR negative cases | Automated reuse rejection passed | Browser reuse rejection and expired-token rejection separately |
| M07 | Break-glass/audit | 22_03, 23_01 and 29 show the reason gate, minimum-necessary record and activity; researcher confirmed restricted view | Correlated steps if claiming a complete formally recorded sequence |
| M08 | Encounter creation | 04-05 show history/prescription; automated creation passed | Distinguish manual creation from seeded history |
| M09 | Patient documents | 10 shows stored files; user reported upload success after fixes | Download/open or byte-check, followed by deletion |
| M10 | Live Gemini | 25 shows summary output; prior user demonstration | Output is evidenced, but image alone does not identify provider; provider-specific successful request evidence needed |
| M11 | Biometrics/camera | 18-19 show labelled simulation and actual camera preview | Allowed preview visibly evidenced; denied/revoked/recovery sequence and browser no-sign-in check not fully recorded |
| M12 | Administrator | 28-29 show controls/audit; automated deactivation denial passed | Browser deactivate/reject/reactivate/successful login |
| M13 | Print / Save PDF | Print action visible in 01 | Print preview and checked saved PDF |
| M14 | Responsive layout | Selected automated coverage; settings image 15 | Manual 390 px width at 130% text |
| M15 | Accessibility | Settings and selected widget checks | Keyboard-only and actual screen-reader observations |
| M16 | Doctor upload | `24_Doctor_Document_Upload.png` shows the dialog; automated upload passed and user reported uploads working | Explicit doctor upload followed by patient document-list confirmation |

For a previously completed manual check, record the actual steps, observed result, tester and date if known. Specific user attestation is useful evidence; a recording is not mandatory. Do not invent dates or convert ambiguous “all good” replies into every listed test passing.

## Next verification steps

1. Retain the 22 September passing transcript and the earlier historical transcripts; do not replace dated evidence with a fictional single run.
2. If claiming formal physical-device coverage, record the QR/camera steps, permission-denied recovery and timed expiry with synthetic data.
3. If claiming end-to-end document or administrator coverage, record downloaded-file integrity/deletion and account reactivation with restored login.
4. Establish provider-specific live Gemini evidence without exposing keys if that claim is needed; check saved print output and manual accessibility separately.

## Evaluation boundaries

- No formal latency percentiles, load, throughput, memory or concurrent-user measurements were located. Test durations are not performance benchmarks.
- Production HTTPS, production CORS/origins, backups and monitoring are not verified by local tests.
- Native Android/iOS/desktop releases are outside the current web thesis scope.
- Newer package notices are not test failures; avoid unrelated upgrades before presentation.
- Camera preview is a biometric **simulation**, not actual face recognition.

## Final status

**Current-code automated verification: 93 passed, 0 failed; Flutter analysis and Web release build passed.**
**Live local API/SQL startup and health: passed.**
**Manual evidence: partially documented, with screenshots and user-reported success; specific sequences remain unconfirmed.**
**Production readiness and formal performance: not established.**
