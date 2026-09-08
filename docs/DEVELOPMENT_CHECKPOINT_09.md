# Development Checkpoint 09 - Secure Medical Documents

Date: 2026-09-08

## Outcome

Patients can upload, view, download, and remove supporting medical documents.
An authorized doctor can view and download those documents only while the
patient's access grant is active. Doctor downloads create a patient-visible
audit event.

This checkpoint gives the thesis a complete file-management workflow that can
be demonstrated through Flutter, ASP.NET Core, and SQL Server.

## Implemented workflow

### Patient workflow

1. The patient signs in and opens the **Documents** tab.
2. The patient chooses a PDF, JPEG, or PNG file.
3. The patient selects a category and may enter a description.
4. ASP.NET validates the identity, role, size, extension, content type, and
   file signature before saving the document.
5. The patient can download the saved file or remove it later.

### Doctor workflow

1. The doctor obtains an active consent, QR, or break-glass access grant.
2. The doctor opens the authorized patient's emergency record.
3. The patient's active documents appear in the medical-documents panel.
4. The doctor can download a document but cannot upload, change, or delete it.
5. Every successful doctor download creates an access-audit event.

Expired, revoked, missing, or another doctor's grants cannot list or download
the patient's documents.

## Chapter 4 design evidence

### Database entity

`MedicalDocument` contains:

- `Id` - primary key;
- `PatientProfileId` - required foreign key to `PatientProfile`;
- `UploadedByUserId` - required foreign key to the uploading Identity user;
- `FileName`, `ContentType`, `Category`, and optional `Description`;
- `SizeBytes` and the protected binary `Content`;
- `UploadedAtUtc` and optional `DeletedAtUtc` for soft deletion.

One `PatientProfile` can have many `MedicalDocument` records. Deleting a
patient profile cascades to its documents, while deleting the uploader account
is restricted so document authorship is not silently lost.

### API endpoints

Patient endpoints:

- `GET /api/v1/patients/me/documents`
- `POST /api/v1/patients/me/documents`
- `GET /api/v1/patients/me/documents/{documentId}/content`
- `DELETE /api/v1/patients/me/documents/{documentId}`

Doctor endpoints:

- `GET /api/v1/doctors/emergency-access/{grantId}/documents`
- `GET /api/v1/doctors/emergency-access/{grantId}/documents/{documentId}/content`

The controllers receive HTTP requests; `MedicalDocumentService` owns the
validation and authorization rules; Entity Framework Core persists the data
and migration `AddMedicalDocuments` creates the SQL Server table.

## Security decisions

- Only authenticated patients can manage their own documents.
- Doctors receive read-only access and must present their own active grant.
- The maximum file size is 5 MB and each patient may keep 25 active documents.
- Only PDF, JPEG, and PNG are accepted.
- Extension, MIME type, and binary file signature must agree.
- Uploaded files are not exposed from a public web folder.
- Deletion is soft deletion and clears the stored binary content.
- Successful doctor downloads are audited by the server.
- The response uses `no-store` so protected file responses are not deliberately
  cached by the application.

For this thesis prototype, binary data is stored in SQL Server so metadata and
content participate in the same protected persistence model. A production
deployment could use encrypted private object storage with only metadata and a
private object reference in SQL Server.

## Verification evidence for Chapters 5 and 6

- ASP.NET application tests: 5 passed.
- ASP.NET API integration tests: 23 passed.
- Flutter tests: 35 passed.
- Flutter analyzer: passed with no issues.
- SQL Server migration `AddMedicalDocuments`: applied successfully.
- The integration test proves file validation, patient ownership, grant-based
  doctor access, download content, audit creation, and patient deletion.
- The widget test proves that the Flutter patient panel lists and removes a
  document through the repository boundary.

## Suggested thesis screenshots

1. Patient **Documents** tab before upload.
2. File selection and metadata dialog.
3. Uploaded document card showing category, date, and size.
4. Doctor record showing the same document in read-only mode.
5. Patient access history showing the doctor download audit event.
6. SQL Server `MedicalDocuments` table with synthetic data only.
7. Automated test output showing the passing totals.

Use only synthetic documents and patient data in the report and presentation.

## Honest limitations and future work

- Malware scanning and content disarm are not implemented; these are required
  before accepting untrusted uploads in production.
- At-rest database encryption, backup restoration, and production key
  management still require deployment configuration.
- OCR and AI analysis of uploaded documents are not implemented.
- Document correction/version history is not implemented.
- The system remains a thesis prototype, not a certified clinical product.
