# Checkpoint 02 — controlled doctor access and audit

## Outcome

The system now demonstrates the thesis's central security journey with
synthetic data:

1. A patient selects an active doctor and grants access for 15 minutes to 24
   hours.
2. The API stores the grant and a `Granted` audit event.
3. The doctor sees only active, unrevoked grants and opens a read-only emergency
   snapshot.
4. Opening the snapshot creates a server-side `Viewed` audit event.
5. The patient can revoke the grant; the API records `Revoked` and immediately
   rejects subsequent snapshot requests.

Expiry, ownership, doctor role, and revocation are enforced by ASP.NET Core and
SQL-backed queries. Flutter does not decide whether access is valid.

## Demonstration

Run the API and web app, then:

1. Sign in with the synthetic patient account.
2. Scroll to **Doctor emergency access**.
3. Choose the demo doctor, choose a duration, and select **Grant access**.
4. Sign out and sign in as the synthetic doctor.
5. Open the authorized patient snapshot.
6. Return to the patient account and expand **Access history** to show the
   grant and view events.
7. Select **Revoke**, return to the doctor, and show that the record is no
   longer available.

Use the locally configured demo passwords. Never place those passwords in this
document, source control, screenshots, or thesis appendices.

## Main implementation locations

- Domain: `backend/src/EmergencySystem.Domain/Access/`
- API/service: `PatientAccessController`, `DoctorAccessController`, and
  `EmergencyAccessService`
- Migration: `20260822074542_AddEmergencyAccess`
- Flutter: `lib/src/features/access/`
- Security test: `Patient_grant_enables_audited_doctor_view_and_revocation_blocks_it`

## Verification

- Flutter analyzer: no issues.
- Flutter tests: 26 passed.
- ASP.NET tests: 12 passed.
- EF model: no pending model changes.
- Anonymous doctor endpoint check: HTTP 401.

## Deliberate limitations

- Break-glass access is not part of this checkpoint.
- Audit events are append-only through the application API; stronger
  database-level immutability can be evaluated later.
- QR links and passkeys will build on this access model rather than bypass it.
