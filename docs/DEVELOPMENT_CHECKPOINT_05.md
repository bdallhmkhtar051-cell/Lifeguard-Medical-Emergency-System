# Development Checkpoint 05 — Secure Medical ID QR

Date: 2026-09-07

## Outcome

The patient Medical ID card now displays a real server-issued QR link. A doctor
who scans or opens the link must sign in with a Doctor account. Successful
redemption creates 15 minutes of read-and-document access and immediately opens
the same protected emergency snapshot used by consent and break-glass flows.

## Security and traceability

- The QR contains 256 bits of cryptographically random data.
- SQL Server stores only the SHA-256 token hash, never the raw QR secret.
- The invitation expires after five minutes and works once only.
- Issuing a new QR invalidates any previous unused QR for that patient.
- Closing the patient dialog revokes the unused token.
- The token is placed in the URL fragment, which is not sent to the static web
  host in an HTTP request.
- Redemption requires an authenticated, active Doctor account.
- Redemption is rate limited to 10 attempts per five minutes per IP address.
- The resulting access grant expires after 15 minutes.
- `QrRedeemed` is written to the existing patient-visible audit history.
- Snapshot and clinical APIs continue to verify the grant on the server.

## Database changes

- `MedicalQrTokens`: patient, token hash, issue/expiry/redeem/revoke times,
  redeeming doctor, resulting grant, and optimistic concurrency version.
- `EmergencyAccessType` now includes `QrConsented`.
- `AccessAuditAction` now includes `QrRedeemed`.
- Migration: `20260907084702_AddMedicalQrAccess`.

## API additions

- `POST /api/v1/patients/me/medical-qr`
- `POST /api/v1/patients/me/medical-qr/revoke`
- `POST /api/v1/doctors/emergency-access/medical-qr/redeem`

## Flutter additions

- **Display QR** now opens a real QR dialog rather than a placeholder message.
- The dialog displays expiry and one-use information and can copy the link.
- **Close and revoke** invalidates an unused QR before dismissing the dialog.
- A doctor opening the QR link is routed through normal login and then the
  token is redeemed automatically.
- Doctor and patient access views label the grant as QR consent.

## Verification

- C# build: passed with zero warnings.
- Application tests: 5 passed.
- API integration tests: 17 passed, including QR role enforcement, hash-only
  persistence, redemption replay prevention, revocation, snapshot access, and
  patient-visible auditing.
- Dart analyzer: passed with no issues.
- Flutter tests: 30 passed, including responsive QR display/revocation and
  automatic doctor redemption.
- Flutter release web build: passed.
- SQL Server migration `20260907084702_AddMedicalQrAccess` was applied to the
  local `EmergencySystem` database.

## Presentation workflow

For a one-computer demonstration, keep the patient signed in in the normal
browser window, copy the QR link, and open it in an incognito window. Sign in
as the doctor there. For a deployed HTTPS build, a phone camera can open the
same link directly.

## Deliberate limitations

- There is no built-in camera-scanner page. The QR is scanned by the phone or
  browser camera and opens the LifeGuard web link.
- A localhost QR is reachable only from the same computer. Cross-device
  scanning requires an HTTPS deployment address accessible to both devices.
- QR access does not remove authentication or grant permanent access.
