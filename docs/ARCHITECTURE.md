# Recommended thesis architecture

Status: provisional until the correct medical-system description is supplied.
The reviewed `the project structure.docx` describes a shop ERP and must not be
used as the requirements document for this system.

## Decision

Build a responsive, web-first modular monolith:

```text
Patients / Doctors / Administrators
                 |
                 v
        Flutter Web application
        role-based screens/routes
                 |
              HTTPS/JSON
                 |
                 v
        ASP.NET Core 10 Web API
        -----------------------
        Authentication
        Authorization and consent
        Medical-record use cases
        Validation
        Audit logging
                 |
              EF Core 10
                 |
                 v
             SQL Server
```

Use one Flutter web application for the thesis. A browser already covers
desktop and laptop users, so a native Windows application would add work
without adding thesis value. A separate patient-focused Flutter mobile
application can be added after the web system is stable. It should reuse the
same API and, where useful, shared Dart packages rather than copying the whole
web interface.

## Why this stack

- Flutter supplies one responsive user interface for all three roles and gives
  a practical route to Android/iOS later.
- ASP.NET Core owns security, validation, business rules, and the API boundary.
- Entity Framework Core maps the domain model to a relational database and
  manages schema migrations.
- SQL Server is already installed locally and can store the strongly related
  medical, consent, encounter, and audit data.
- A modular monolith is much faster to build, test, explain, and deploy than
  microservices while still allowing clear feature boundaries.

The Flutter client must never connect directly to SQL Server. Database
credentials and privileged queries belong only in the backend.

## Firebase decision

Firebase is not required for the thesis MVP. ASP.NET Core can provide the API,
authentication, authorization, validation, and background work needed by the
initial web system. Using both Firebase Authentication and ASP.NET Identity at
the beginning would create two identity boundaries with no clear thesis
benefit.

Firebase Cloud Messaging may be added later when a patient mobile app needs
push notifications while it is in the background or closed. If that happens,
ASP.NET Core remains the source of truth and sends narrowly scoped
notifications through FCM. Do not send diagnoses, medications, or other
sensitive medical details in notification text.

## Application shape

Keep the repository simple:

```text
/
  lib/                         Flutter web client
    src/
      app/
      core/
        auth/
        config/
        networking/
        routing/
        theme/
      features/
        authentication/
        patient_profile/
        emergency_snapshot/
        consent/
        clinical_records/
        audit/
        administration/
  backend/
    EmergencySystem.sln
    src/
      EmergencySystem.Api/
      EmergencySystem.Application/
      EmergencySystem.Domain/
      EmergencySystem.Infrastructure/
    tests/
      EmergencySystem.Api.Tests/
      EmergencySystem.Application.Tests/
  docs/
```

This is a layered modular monolith, not a requirement to create an abstraction
for every class. Add a feature when its first end-to-end use case is built.

## Thesis roles and permissions

| Capability | Patient | Doctor | Administrator |
| --- | --- | --- | --- |
| View own emergency profile | Yes | With authorized access | Support only |
| Edit own profile and contacts | Yes | No | Support only |
| View another patient's clinical data | No | Consent or break-glass | No |
| Add encounter/clinical note | No | With authorized access | No |
| Manage users and account status | No | No | Yes |
| View personal access history | Yes | Own activity | Security oversight |
| Change or delete audit history | No | No | No |

An administrator must not automatically receive unrestricted clinical access.
Administration and clinical care are different responsibilities.

## Required modules

1. **Authentication and role-based access**
   - Register or seed thesis users.
   - Sign in and sign out.
   - ASP.NET Core Identity with short-lived JWT access tokens.
   - Optional device-backed passkey sign-in after password authentication is
     stable.
   - Server-side role and ownership checks on every protected operation.

2. **Patient emergency profile**
   - Demographics required for identification.
   - Blood group, allergies, chronic conditions, current medications.
   - Emergency contacts.
   - Patient-controlled editing with validation.

3. **Consent and emergency access**
   - Patient grants time-limited doctor access.
   - Doctor can request normal access.
   - A break-glass path requires a reason and creates a prominent audit event.
   - Emergency access is read-only until normal authorization is granted.

4. **Emergency snapshot**
   - A deliberately small, readable summary.
   - Allergies, critical conditions, medications, blood group, and contacts.
   - No AI-generated diagnosis or treatment recommendation.

5. **Clinical records**
   - Authorized doctors can add encounters, diagnoses/observations, and
     prescriptions.
   - Records persist in SQL Server and include author and timestamp.
   - Corrections create history; they do not silently overwrite authorship.

6. **Audit trail**
   - Append-only access events generated by the server.
   - Actor, patient, action, outcome, reason, timestamp, and correlation ID.
   - Patients can see who accessed their information.

7. **Administration**
   - User and role management.
   - Account activation/deactivation.
   - Security/audit overview without editing clinical content.

## Initial data model

The precise ERD will be finalized with the medical requirements, but the MVP
needs these concepts:

- `ApplicationUser` and Identity role tables
- `PatientProfile`
- `Allergy`
- `MedicalCondition`
- `Medication`
- `EmergencyContact`
- `ConsentGrant`
- `AccessRequest`
- `EmergencyAccessEvent`
- `Encounter`
- `ClinicalObservation`
- `Prescription`
- `AuditEvent`

Use database-generated identifiers, UTC timestamps, foreign keys, constraints,
and optimistic concurrency where records can be edited. Use synthetic thesis
data only.

## Security baseline

- HTTPS between Flutter and the API.
- Password hashing through ASP.NET Core Identity; never store plaintext PINs or
  passwords.
- Store passkey public credentials only; biometric images/templates remain on
  the user's device and must never be collected by the application.
- Authorization enforced in the API, never only by hiding a Flutter button.
- Time-limited access and explicit revocation.
- Break-glass reason, confirmation, and server-side audit event.
- Rate limiting on sign-in and access-code endpoints.
- Input validation, bounded upload sizes, and safe file types if uploads are
  later enabled.
- No medical data, tokens, passwords, or connection strings in logs.
- Secrets kept out of Git and out of the compiled Flutter application.
- Backups and restoration should be demonstrated with synthetic data before
  the defense.

This is a thesis prototype, not a certified clinical or emergency-dispatch
product. Production use would require legal, privacy, clinical-safety,
security, accessibility, and operational review in the deployment country.

## Passkeys and future AI

The targeted biometric capability is WebAuthn/passkey authentication backed by
the device's Windows Hello, phone biometric, security key, or PIN. It is one
cross-platform authentication flow, not separate face-recognition and
fingerprint subsystems. See
[BIOMETRICS_AND_AI_ROADMAP.md](BIOMETRICS_AND_AI_ROADMAP.md).

AI remains future work. A future AI adapter would sit behind ASP.NET
authorization, minimization, auditing, feature flags, and human review. The
Flutter client must never call an AI provider directly with medical data.

## Explicitly deferred

These prototype ideas are attractive in a presentation but would endanger the
deadline or create unsafe claims:

- AI diagnosis, treatment advice, or automated triage
- raw fingerprint capture, stored biometric templates, or custom face matching
- blockchain records
- real ambulance dispatch integration
- live cross-hospital EHR interoperability
- OCR of paper medical documents
- legal advance directives such as one-click DNR/DNI
- native Windows, iOS, and Android releases during the core milestone

They may be presented as future work or clearly labelled simulations, but they
must not be described as implemented capabilities.

## Source-control requirement

The supplied institutional guideline explicitly requires a GitHub or GitLab
repository. Bitbucket alone may therefore fail a literal requirement. Confirm
this with the supervisor, or use GitHub/GitLab as the thesis repository and
mirror to Bitbucket only if needed.
