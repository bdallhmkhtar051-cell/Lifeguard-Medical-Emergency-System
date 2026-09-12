# LifeGuard thesis demonstration runbook

Use synthetic demo information only. Close unrelated applications and browser
tabs before presenting. Keep this file open on a second device if possible.

## Before the presentation

1. Restart the laptop and connect it to power.
2. Confirm SQL Server is running.
3. Confirm the demo patient, doctor and administrator passwords privately.
4. Put the phone and laptop on a stable connection.
5. Open two PowerShell terminals in the LifeGuard repository.
6. In terminal 1 run:

   ```powershell
   .\scripts\run-api.cmd
   ```

7. Wait for `Now listening on: http://localhost:5080`.
8. In terminal 2 run:

   ```powershell
   .\scripts\run-web.cmd
   ```

9. Allow Chrome camera access when prompted.
10. Keep backup screenshots available in case the camera or internet fails.

## Recommended 8-10 minute judge demonstration

### 1. Problem and architecture — 60 seconds

Open **Menu -> About LifeGuard**.

Say:

> LifeGuard is a responsive Flutter Web medical emergency information system.
> Flutter communicates with an ASP.NET Core API, and Entity Framework Core
> stores the records in SQL Server. The API enforces authentication, roles,
> consent and audit rules; the interface does not grant itself access.

### 2. Patient Medical ID — 90 seconds

Sign in as the patient and show:

- the Medical ID card;
- blood group, allergies, medications and conditions;
- emergency contacts, physician, insurance, donor status and responder notes;
- the printable emergency summary.

Explain that these values are patient reported and must be clinically checked.

### 3. Consent and QR — 2 minutes

Show **Access permissions & audit** and grant the demo doctor temporary access.
Then display the patient's one-use Medical ID QR.

Explain:

- the raw token is shown only temporarily;
- the database stores a hash rather than the raw token;
- it expires after five minutes and works once;
- redemption creates only 15 minutes of audited access.

### 4. Doctor workflow — 2 minutes

Sign out and sign in as the doctor. Show directory search and filters, then
open the authorized patient. Demonstrate:

- read-only emergency profile;
- clinical history;
- creating a synthetic encounter with vitals/prescription;
- read-only documents;
- guarded AI summary and its verification warning.

If practical, scan the phone QR with the laptop camera. Otherwise explain that
the same workflow is already open and use the backup evidence screenshot.

### 5. Emergency access and auditing — 90 seconds

Choose a locked synthetic patient, select **Break glass**, and enter a specific
reason longer than 20 characters. Explain the 15-minute limit and show the
patient-visible audit entry afterward.

### 6. Administration and accessibility — 60 seconds

Briefly show the administrator's role-restricted account/audit view. Then show
**Accessibility & settings**, including text size, high contrast, reduced
motion, and real session-expiry information.

### 7. Honest conclusion — 30 seconds

Say:

> The selected thesis requirements are implemented as a working web system,
> not only a visual prototype. Biometrics remain an explicitly labelled
> simulation. Real passkeys, production deployment hardening and a patient
> mobile application are future work.

## Recovery plan

- **API unavailable:** confirm terminal 1 is still running, then refresh Chrome.
- **Login rejected:** use the configured demo credential; never show passwords
  on a slide or in source code.
- **Camera denied:** Chrome site settings -> Camera -> Allow, then reopen scan.
- **QR expired/used:** issue a new QR from the patient account.
- **Gemini unavailable:** show the stored backup screenshot and explain that the
  backend fails safely; do not claim a live result.
- **Database unavailable:** start SQL Server, restart the API, and confirm the
  `/health` response before continuing.

## Presentation wording to avoid

Do not say that:

- biometrics, face recognition, fingerprints or passkeys are real;
- AI diagnoses or recommends treatment;
- patient-entered donor/insurance information is officially verified;
- the application works offline;
- the system is production certified or deployed;
- every React prototype idea was copied exactly.
