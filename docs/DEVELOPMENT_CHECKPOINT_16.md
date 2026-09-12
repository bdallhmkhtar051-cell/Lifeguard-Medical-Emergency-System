# Development checkpoint 16: doctor professional profile

**Completed:** 12 September 2026

## Outcome

Doctors can open **Professional profile** from their authenticated hamburger
drawer and maintain professional details used to describe their workplace and
role. The data is stored in SQL Server and is never presented as independently
verified credentialing.

## Implemented behavior

- Doctor-only GET and PUT endpoints at `/api/v1/doctors/me/profile`.
- Editable professional title, hospital or organization, department, licence
  number, and professional phone number.
- Existing Identity display name and email are shown read-only.
- Empty values are normalized to `null`; surrounding whitespace is removed.
- Server-side maximum lengths protect the API independently of Flutter.
- Patients and administrators cannot use the doctor-only endpoints.
- The drawer returns cleanly between Professional profile and Patients.

## Safety boundary

The page states that the information is self-reported and that a supplied
licence number is not independently verified by LifeGuard. This milestone does
not add a medical-regulator integration, credential verification, document
proof, or administrator approval workflow.

## Main files

- `backend/src/EmergencySystem.Api/Controllers/DoctorProfileController.cs`
- `backend/src/EmergencySystem.Infrastructure/Identity/ApplicationUser.cs`
- `backend/src/EmergencySystem.Infrastructure/Persistence/PatientProfileConfiguration.cs`
- `backend/src/EmergencySystem.Infrastructure/Persistence/Migrations/20260912181412_AddDoctorProfessionalProfile.cs`
- `lib/src/features/access/doctor_profile_page.dart`
- `lib/src/features/access/access_models.dart`
- `lib/src/features/access/access_repository.dart`
- `lib/src/features/access/doctor_access_page.dart`
- `lib/src/features/home/home_shell.dart`
- `test/features/access/doctor_profile_test.dart`
- `backend/tests/EmergencySystem.Api.Tests/ApiIntegrationTests.cs`

## Verification

- SQL Server migration applied successfully.
- Flutter analyzer: no issues found.
- Flutter tests: **45 passed**.
- Application tests: **6 passed** (unchanged suite).
- API integration tests: **24 passed**.
- Flutter Web release build: passed.

## Presentation walkthrough

1. Sign in with the seeded doctor account.
2. Open the hamburger menu and choose **Professional profile**.
3. Enter synthetic hospital and department details, then save.
4. Leave the page, return, and show that SQL-backed values remain.
5. Point out the self-reported and unverified-licence warning.
