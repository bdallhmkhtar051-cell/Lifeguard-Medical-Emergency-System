# LifeGuard thesis evidence checklist

Save screenshots with synthetic data under a dated folder outside source code,
for example `thesis-evidence/2026-09-12/`. Do not capture passwords, API keys,
JWTs, QR token URLs, real patient information, or terminal secret output.

## Chapter 4 — implementation evidence

- [ ] Login screen and clearly labelled biometric simulation
- [ ] Patient Medical ID overview
- [ ] Patient editor and validation
- [ ] Role-aware hamburger menu
- [ ] Consent grant/revoke and access audit
- [ ] One-use QR display and doctor scanner
- [ ] Doctor directory search/filter
- [ ] Authorized doctor snapshot
- [ ] Break-glass dialog and emergency warning
- [ ] Clinical encounter/timeline
- [ ] Medical documents
- [ ] Guarded AI summary
- [ ] Administrator overview
- [ ] About LifeGuard architecture page
- [ ] Printable emergency summary
- [ ] Accessibility settings
- [ ] SQL Server table/relationship evidence without secret values

## Chapter 5 — test and result evidence

- [ ] `verify-all.cmd` final success output
- [ ] Test table: 6 Application + 23 API + 44 Flutter = **73 passed**
- [ ] Live `/health` HTTP 200 result
- [ ] Patient role cannot access doctor/admin controls
- [ ] Doctor role cannot edit the patient-owned profile
- [ ] Unauthorized/expired access rejection
- [ ] Reused or expired QR rejection
- [ ] Break-glass reason and audit evidence
- [ ] Invalid document rejection and valid document workflow
- [ ] Narrow Chrome layout at 390 px
- [ ] Accessibility layout at 130% text
- [ ] Camera-permission result
- [ ] Observed limitations and recovery behavior

## Chapter 6 — conclusion and future work

- [ ] State which objectives were achieved using evidence from Chapters 4-5
- [ ] Explain that the working system improves on the visual React prototype
- [ ] Record biometric authentication as a simulation
- [ ] Record real WebAuthn/passkeys as future work
- [ ] Record production hosting, HTTPS and operational monitoring as future work
- [ ] Record a focused patient mobile application as future work
- [ ] Record optional doctor-initiated access requests as future enhancement
- [ ] Avoid introducing new implementation details not present in the repository

## Screenshot register

| ID | File name | Role | Feature shown | Chapter/figure | Passed/issue |
|---|---|---|---|---|---|
| S01 |  |  |  |  |  |
| S02 |  |  |  |  |  |
| S03 |  |  |  |  |  |
| S04 |  |  |  |  |  |
| S05 |  |  |  |  |  |
| S06 |  |  |  |  |  |
| S07 |  |  |  |  |  |
| S08 |  |  |  |  |  |
| S09 |  |  |  |  |  |
| S10 |  |  |  |  |  |

## Manual-test record

| Test ID | Date | Browser/device | Expected result | Actual result | Pass/fail | Notes |
|---|---|---|---|---|---|---|
| M01 |  |  |  |  |  |  |
| M02 |  |  |  |  |  |  |
| M03 |  |  |  |  |  |  |
| M04 |  |  |  |  |  |  |
| M05 |  |  |  |  |  |  |
| M06 |  |  |  |  |  |  |
| M07 |  |  |  |  |  |  |
| M08 |  |  |  |  |  |  |
| M09 |  |  |  |  |  |  |
| M10 |  |  |  |  |  |  |
| M11 |  |  |  |  |  |  |
| M12 |  |  |  |  |  |  |
| M13 |  |  |  |  |  |  |
| M14 |  |  |  |  |  |  |
| M15 |  |  |  |  |  |  |
