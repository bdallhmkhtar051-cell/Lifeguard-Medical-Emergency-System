# Medical emergency thesis execution plan

Plan date: 2026-07-28

This plan targets a thesis-ready, end-to-end prototype in eight weeks, with a
credible 60–70% functional milestone after four weeks. It does not claim to be
a production-certified medical platform.

## Provisional thesis direction

Recommended working title:

> Design and Implementation of a Role-Based Emergency Medical Information,
> Consent, and Audit System

Alternative shorter title:

> Lifeguard Medical ID and Emergency Access System

The final title, problem statement, and objectives must be checked against the
correct medical project-description document and approved by the supervisor.

## Provisional problem

During an emergency, responders may need a small amount of reliable patient
information quickly, while patients need control and visibility over access to
their sensitive records. Existing prototype concepts demonstrate the desired
screens but do not persist data, enforce authorization, or create trustworthy
audit history. The thesis will design and evaluate a role-based web system that
balances timely emergency access with consent and accountability.

## Provisional objectives

### General objective

Design, implement, and evaluate a secure, role-based emergency medical
information system for patients, doctors, and administrators.

### Specific objectives

1. Model patient emergency information and clinical encounters in SQL Server.
2. Implement authentication and server-enforced role-based authorization.
3. Allow patients to maintain emergency profiles and control time-limited
   doctor access.
4. Provide doctors with a concise emergency snapshot and authorized clinical
   record workflow.
5. Implement a controlled break-glass process and append-only access audit.
6. Evaluate functional correctness, usability, response time, and access
   control using synthetic data and repeatable tests.

## Scope

### Must have for the thesis

- Responsive Flutter web application.
- Patient, doctor, and administrator roles.
- Real sign-in and sign-out.
- Persistent SQL Server data through ASP.NET Core.
- Patient emergency-profile CRUD.
- Allergies, conditions, medications, blood group, and emergency contacts.
- Normal consent/access request.
- Time-limited consent and revocation.
- Emergency break-glass access with a required reason.
- Read-only emergency snapshot.
- Doctor-created encounters and prescriptions/observations.
- Server-created access audit history visible to the patient.
- Real QR access token or link, if it can be completed without weakening
  security.
- Automated API tests for critical authorization paths.
- Deployed or presentation-ready release with synthetic demonstration data.

### Should have after the core is stable

- Patient and doctor dashboards.
- Device-backed WebAuthn/passkey sign-in, using the device's face, fingerprint,
  PIN, or security key without collecting biometric data.
- Search and filtering.
- Account administration.
- Basic printable/exportable report.
- Accessibility and responsive-layout pass.
- Database backup/restore demonstration.
- Usability questionnaire and summarized evaluation.

### Could have only if the schedule is ahead

- Simple document attachment with strict size/type rules.
- An SOS event using browser location, clearly labelled as a demonstration.
- Firebase Cloud Messaging for a later Android patient application.
- A small administrator analytics view.

### Not in this thesis build

- AI diagnosis or triage.
- Biometrics, blockchain, or real ambulance dispatch.
- Full hospital EHR or FHIR integration.
- Native Windows application.
- Separate doctor mobile application.
- Real patient data.

## What “60–70% complete” means

By the end of week 4, the following vertical slice must work with persisted
data:

1. A patient, doctor, and administrator can sign in with different permissions.
2. A patient can create and edit an emergency profile.
3. A doctor cannot view it without authorization.
4. The patient can grant time-limited access.
5. The doctor can view the emergency snapshot while access is valid.
6. The doctor can use break-glass access only after providing a reason.
7. Every view, grant, revocation, and override creates a server-side audit
   event.
8. The patient can see the resulting access history.
9. The Flutter web app, ASP.NET API, and SQL Server run together.
10. The main use-case diagram, initial ERD, architecture, Chapters 1–3 draft,
    and test plan exist.

This is a stronger milestone than having 70% of screens. It proves the hardest
security and data path end to end.

## Calendar plan

The clarified calendar provides 50 calendar days from July 28 through
September 15 for development, followed by 15 days from September 16–30 for
testing and finalization.

| Dates | System work | Thesis/evidence work | Exit condition |
| --- | --- | --- | --- |
| Jul 28–31 | Correct requirements; install .NET 10; repository decision; ASP.NET/Flutter/SQL shells | Finalize provisional title, scope, users, use cases, and Chapter 1 outline | Approved scope and client-to-API health check |
| Aug 1–7 | SQL schema/migrations; Identity/password sign-in; roles; seeded synthetic users | Literature-search plan; related-system comparison; initial ERD/architecture | Real sign-in and protected endpoint |
| Aug 8–14 | Patient profile, allergies, conditions, medications, contacts; responsive patient screens | Chapter 2 and methodology draft; data dictionary and test cases | Patient data persists end to end |
| Aug 15–21 | Access request, time-limited consent, revocation, break-glass reason, emergency snapshot, audit | Update diagrams and security test cases | Core secure patient-to-doctor journey works |
| Aug 22–28 | Doctor encounters/observations/prescriptions; administrator basics; real QR token/link | Chapter 4 implementation notes and screenshots | Defined 60–70% milestone passes |
| Aug 29–Sep 5 | WebAuthn/passkey registration, sign-in, revocation, recovery, and audit | Biometrics design/evaluation section and threat analysis | Actual device-backed sign-in works, or is removed without blocking core login |
| Sep 6–10 | Responsive/accessibility pass; validation/error states; remaining core defects | Chapter 4 draft and user manual | Feature-complete release candidate |
| Sep 11–15 | Deployment; seed/reset demo; backup video; feature freeze | Chapters 1–4 revision and Chapter 5 test protocol | No new features after Sep 15 |
| Sep 16–20 | Functional, authorization, security, and regression tests | Record reproducible results and evidence | Critical workflows pass |
| Sep 21–25 | Performance/usability testing and defect correction | Chapter 5 results and discussion | Test findings and fixes documented |
| Sep 26–30 | Final regression, backup/restore, presentation rehearsal | Chapter 6, appendices, slides, formatting, citations | Submission/defense package ready |

## Schedule fallback

If development slips:

- Protect the consent/audit vertical slice first.
- Drop attachments, SOS, analytics, and native mobile work.
- Drop passkeys by September 5 if they threaten the stable password login,
  patient records, consent, or audit trail.
- Freeze features on September 15 even if optional work is incomplete.

Do not cut authorization, audit logging, tests, or thesis writing to preserve a
decorative feature.

## Effort assumption

The calendar assumes roughly 20–30 focused hours each week and regular
supervisor feedback. At less than about 15 hours per week, reduce the scope to
the defined consent/audit vertical slice plus testing and documentation. A real
production medical/dispatch platform would take a team and substantially
longer; the deadline is realistic only for a controlled thesis prototype.

## Acceptance and defense demonstration

The final demonstration should be deterministic:

1. Reset or seed a synthetic patient, doctor, and administrator.
2. Sign in as the patient and show the emergency profile.
3. Sign in as the doctor and show that unauthorized access is denied.
4. Grant access as the patient and view the snapshot as the doctor.
5. Add an encounter or observation.
6. Revoke access and prove that a later request is denied.
7. Perform break-glass access with a reason.
8. Return to the patient and show every event in the access history.
9. Show relevant SQL records, API tests, ERD, and measured results.

Keep screenshots and a short backup video in case the network or presentation
machine fails.

## Evaluation plan

Collect evidence that can be reported in Chapter 5:

- **Functional tests:** expected result for every core use case.
- **Authorization tests:** patient ownership, doctor consent, expired/revoked
  consent, role denial, and break-glass audit.
- **Performance:** API response-time samples for sign-in, profile retrieval,
  emergency snapshot, and audit queries using a defined synthetic dataset.
- **Usability:** a small questionnaire with clearly stated participant count
  and limitations.
- **Reliability:** validation/error behavior and backup/restore exercise.
- **Security:** evidence that protected endpoints reject missing, invalid, and
  wrong-role tokens.

Do not invent clinical effectiveness claims. The evaluation is of the software
prototype and its workflows.

## Immediate decisions

1. Supply the correct medical project-description document; the current Word
   file is a shop ERP brief.
2. Confirm the working title and exact user roles with the supervisor.
3. Confirm whether GitHub/GitLab is mandatory; the guideline says it is.
4. Use synthetic data and obtain approval before involving any real users.
5. Decide whether the final demonstration must be deployed online or can run on
   a controlled local network.

Until those answers arrive, environment setup, system diagrams, the API shell,
authentication spike, and synthetic data model can proceed without committing
to optional features.

## Coding and explanation workflow

For each implementation portion:

1. State the use case and acceptance criteria before coding.
2. Implement the smallest end-to-end slice.
3. Add comments for security decisions, non-obvious business rules, and unusual
   algorithms. Avoid comments that merely repeat a line of code.
4. Add or update automated tests with the implementation.
5. In the chat handoff, explain the data flow, files changed, important code,
   validation performed, limitations, and the next slice.
6. Keep a short thesis-ready implementation note and screenshot/evidence list.

Codex can produce most repetitive implementation code, but the student must be
able to explain the architecture, data model, authorization decisions, tests,
and limitations during the defense.
