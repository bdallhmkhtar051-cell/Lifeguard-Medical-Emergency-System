# Development Checkpoint 17 - Visual Biometrics and Clinician Uploads

Date: 2026-09-13

## Outcome

The login experience now provides separate face-recognition and fingerprint
visualizations. Both show ready, animated scanning, success, and unsuccessful
states. They are thesis simulations only: they do not activate a camera or
fingerprint reader, store biometric data, or create an authenticated session.

An authorized doctor can now attach a real PDF, JPEG, or PNG clinical document
to the open patient's record. Available categories include discharge summary,
lab report, referral letter, prescription document, medical certificate,
imaging, and other.

## Doctor upload security

- Upload is available only inside a patient record opened through an active
  consent, QR, or break-glass grant.
- `POST /api/v1/doctors/emergency-access/{grantId}/documents` verifies the
  authenticated Doctor role and that the grant belongs to that doctor.
- The 25 MB limit, extension/MIME/signature checks, and 25-document
  patient limit still apply.
- `UploadedByUserId` records the clinician who attached the document.
- A `MedicalDocumentUploaded` event is added to the patient's audit history.
- Doctors cannot delete patient documents.

## Verification

- Release verification completed on 13 September 2026.
- 6 Application tests and 24 API integration tests passed.
- Flutter analysis reported no issues and all 47 Flutter tests passed.
- The Flutter Web release build completed and produced `build/web`.
- The focused API integration workflow proves authorized doctor upload and its
  audit event, including a valid PDF larger than the former hidden 64 KB server
  request limit.
- Flutter tests prove the biometric visualization cannot sign in and that the
  authorized doctor sees the clinical upload action.

Only synthetic files and patient information may be used in demonstrations.
