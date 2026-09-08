# Development Checkpoint 07 - Web Camera Medical ID QR Scanner

Date: 2026-09-08

## Outcome

The Doctor portal now includes a built-in **Scan Medical ID QR** action. It
opens the browser camera, reads the QR displayed on a patient's phone, redeems
the existing one-use token, and opens the protected emergency snapshot.

## Workflow

1. The patient displays a newly issued Medical ID QR.
2. The doctor signs in on the laptop and selects **Scan Medical ID QR**.
3. Chrome requests camera permission when needed.
4. The doctor points the patient's QR toward the laptop webcam.
5. Flutter validates that the QR is a LifeGuard Medical ID link from the
   current application origin.
6. The existing ASP.NET redemption endpoint verifies the one-use token and
   creates 15 minutes of audited access.
7. The patient snapshot and clinical-record workflow open for the doctor.

## Security decisions

- The scanner accepts discoveries from QR codes only; other barcode formats
  are ignored.
- Unrelated websites and QR codes without a `medicalQr` token are rejected
  before anything is sent to the API.
- Camera images never leave the browser; Flutter receives only decoded text.
- The existing server rules remain unchanged: doctor authentication,
  five-minute QR expiry, one-time redemption, hash-only storage, rate
  limiting, and a 15-minute access grant.
- Denied camera permission produces a clear recovery message.

## Flutter changes

- Added `mobile_scanner` for supported browser camera access and QR decoding.
- Added `medical_qr_scanner_dialog.dart` for the camera preview, scan frame,
  permission errors, and invalid-QR handling.
- Added the scanner action to `doctor_access_page.dart`.
- Added tests for same-origin validation and the complete scan-to-snapshot
  flow.

## Verification

- Dart analyzer: passed with no issues.
- Flutter tests: 33 passed.
- Flutter release web build: passed.
- Live Chrome development build: running at `http://localhost:5000`.

## Presentation limitation

Browser camera access works on `localhost` for development. A remotely
deployed version must use HTTPS. The patient and doctor devices must use the
same LifeGuard web origin so an unrelated QR link cannot inject a token.
