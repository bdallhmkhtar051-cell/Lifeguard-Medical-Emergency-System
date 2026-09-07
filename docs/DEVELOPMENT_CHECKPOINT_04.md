# Development Checkpoint 04 — Clinical Workflow

Date: 2026-09-05

## Outcome

Doctors can now create an append-only clinical encounter while a valid patient
consent or break-glass grant is active. Each encounter supports physician notes,
structured vital observations, disposition, and a prescription. Patients can see
the resulting record in a read-only clinical timeline.

## Security and traceability

- The API, not the Flutter interface, verifies the doctor's role and active grant.
- A record is linked to the patient, doctor, and exact access grant used.
- Creating a record adds a `ClinicalRecordCreated` event to the patient audit log.
- Emergency-profile fields remain read-only for the doctor; the doctor can only
  append a new clinical encounter.
- Server validation rejects impossible vital ranges, future/old encounter dates,
  excessive text, and incomplete prescriptions.
- Clinical API responses use `Cache-Control: no-store` behavior.

## Database additions

- `ClinicalEncounters`: complaint, notes, disposition, doctor, patient, grant,
  clinical time, and creation time.
- `ClinicalObservations`: temperature, heart rate, blood pressure, oxygen
  saturation, and respiratory rate; zero or one observation set per encounter.
- `Prescriptions`: medication, dosage, frequency, duration, and instructions.
- Migration: `20260905085640_AddClinicalWorkflow`.

## API additions

- `GET /api/v1/doctors/emergency-access/{grantId}/clinical-records`
- `POST /api/v1/doctors/emergency-access/{grantId}/clinical-records`
- `GET /api/v1/patients/me/clinical-records`

## Flutter additions

- Doctor snapshot contains the clinical timeline and **New encounter** form.
- Patient portal contains a **Clinical history** tab.
- The timeline shows the doctor, time, notes, disposition, vitals, and medication.
- Forms perform immediate validation; the API repeats validation before storage.

## Verification

- C# build: passed with zero warnings.
- Application tests: 5 passed.
- API integration tests: 14 passed.
- Dart analyzer: passed with no issues.
- Flutter tests: 28 passed.
- Flutter release web build: passed.
- Live SQL Server/API check: created a synthetic encounter; doctor and patient
  both read it; vitals, prescription, and audit event were verified.

## Deliberate limitations

- Existing records cannot be silently edited or deleted. Correction/amendment
  workflow can be added later if required.
- The current form creates up to one prescription at a time, while the backend
  already supports up to ten prescriptions per encounter.
- This is a thesis demonstration workflow, not a certified clinical EHR.
