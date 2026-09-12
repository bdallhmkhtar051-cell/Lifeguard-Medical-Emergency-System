# LifeGuard final verification report

**Verification date:** 12 September 2026  
**Source checkpoint:** `a21b4d2`  
**Scope:** automated Release verification, configuration audit, secret-pattern
scan, live API startup, local SQL Server connectivity, and health response.

## Executive result

The automated and live-startup portions of final verification passed. The
system is ready for the remaining physical browser demonstration checks. Those
checks are deliberately listed as pending rather than reported as completed.

## Verified results

| Verification | Result | Evidence |
|---|---:|---|
| Backend Release restore/build | Passed | All projects restored and compiled during `verify-all.cmd` |
| Application tests | 6 passed | No failures or skipped tests |
| API integration tests | 23 passed | No failures or skipped tests |
| Flutter dependency restore | Passed | Dependencies resolved successfully |
| Flutter static analysis | Passed | No issues found |
| Flutter tests | 44 passed | No failures |
| Flutter Web release build | Passed | `build/web` produced successfully |
| Live API startup | Passed | Listening on `http://localhost:5080` |
| Local SQL Server connectivity | Passed | EF Core successfully queried roles, users, and patient profile data |
| Health endpoint | Passed | HTTP 200: `{"status":"healthy","service":"EmergencySystem.Api"}` |
| Configuration alignment | Passed | Web `5000` -> API `5080`; CORS permits `http://localhost:5000` |
| Basic committed-secret pattern scan | Passed | No Google API key or private-key pattern found outside test/build output |

## Reproduction command

From the repository root:

```powershell
.\scripts\verify-all.cmd
```

This command runs backend Release tests, restores Flutter dependencies, runs
analysis and Flutter tests, and creates the Flutter Web release build.

## What the automated tests currently prove

- login validation, rejected credentials, session creation and expiry clearing;
- role isolation among patient, doctor, and administrator workspaces;
- patient profile loading, editing, validation and optimistic concurrency;
- access granting, expiry, revocation, audit history and break-glass reason;
- one-use QR issue/redemption logic and scanner test seam;
- clinical timeline, encounter data, vital signs and prescriptions;
- medical-document metadata, access rules and deletion behavior;
- AI-summary authorization and safe presentation behavior;
- biometric simulation cannot create a real authenticated session;
- doctor directory search/filtering and narrow-screen organization;
- About, printable summary, accessibility settings and 130% narrow layout.

## Physical checks still required

These require the user's Chrome browser, camera, phone, operating-system print
dialog, or human inspection and are not marked as passed yet:

| ID | Manual check | Evidence to capture |
|---|---|---|
| M01 | Patient login and complete portal walkthrough | Screenshot of Medical ID overview |
| M02 | Patient edits one safe synthetic field and refreshes | Before/after screenshots or short recording |
| M03 | Patient grants doctor access, then revokes it | Permission and audit screenshots |
| M04 | Patient displays one-use QR on phone | Phone screenshot with synthetic account only |
| M05 | Doctor scans phone QR with laptop camera | Scanner and authorized EHR screenshots |
| M06 | Reusing the same QR is rejected | Error screenshot |
| M07 | Doctor break-glass reason and resulting patient audit | Doctor dialog and patient audit screenshots |
| M08 | Doctor creates a synthetic encounter | Timeline screenshot |
| M09 | Patient uploads/downloads/deletes a non-sensitive test document | Documents screenshot |
| M10 | AI summary succeeds with configured Gemini key | Summary plus warning screenshot |
| M11 | Biometric simulation is visibly labelled and does not sign in | Login simulation screenshot |
| M12 | Administrator reviews and safely toggles a demo account | Admin screenshot; restore account afterward |
| M13 | Print / Save PDF opens the browser print dialog | Print-preview screenshot |
| M14 | 390-pixel responsive view at 130% text | Chrome responsive screenshot |
| M15 | Keyboard-only navigation and screen-reader labels | Signed checklist and observations |

## Known non-blocking observations

- Flutter reported newer dependency versions outside current constraints. This
  is not a failed verification; dependency upgrades should be handled as a
  separate tested change, not immediately before the thesis presentation.
- The web release build may report a Cupertino icon-font notice while still
  completing successfully. The application uses Material icons and the build
  artifact is produced.
- Camera access on a remote host requires HTTPS. Localhost is permitted by
  modern browsers, subject to the user approving camera permission.
- The Gemini summary requires its user-secret API key and internet access.

## Final status

**Automated readiness: passed.**  
**Local API and SQL startup: passed.**  
**Physical browser evidence: pending user-assisted execution of M01-M15.**
