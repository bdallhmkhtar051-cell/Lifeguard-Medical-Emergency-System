# Development Checkpoint 18 - Longitudinal Synthetic Patient Record

Date: 2026-09-14

## Outcome

The Development environment now enriches the fictional Amina Hassan account
with enough structured data to demonstrate a multi-year medical record. This
is presentation data only and does not represent a real person.

The overview includes three allergies, three conditions, three current
medications, and two emergency contacts when combined with the original demo
record. The clinical timeline includes seven encounters dated from March 2021
to August 2026. Encounters contain varied vital signs, clinical notes,
dispositions, and selected prescriptions.

## Data integrity and safety

- Seeding runs only when `DemoSeed:Enabled` is true in Development or Testing.
- A fixed baseline encounter prevents duplicate history on later API restarts.
- The enrichment does not overwrite later patient profile edits.
- Every historical encounter links to the fictional doctor and its own expired
  consent grant, preserving the system's authorization relationship model.
- Historical grant and clinical-creation audit records are also synthetic.
- No new database table or migration was required.

## Verification

- The complete backend Release suite passed: 6 Application tests and 24 API
  integration tests.
- The API started successfully against local SQL Server.
- SQL Server accepted seven encounters, seven observations, three historical
  prescriptions, seven expired grants, and their audit records.
- A second API start detected the baseline and did not duplicate the timeline.

## Presentation use

Sign in as the demo patient and compare the **Medical ID** overview with the
**Medical history** timeline. Explain that the data demonstrates how LifeGuard
organizes longitudinal emergency information; it must always be described as
synthetic thesis data rather than a real clinical history.
