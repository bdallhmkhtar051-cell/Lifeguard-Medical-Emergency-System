# LifeGuard System Screenshot Captions

These captions describe the implemented LifeGuard prototype using synthetic demonstration data. Replace `Figure X` with the final chapter-based numbering required by the thesis document (for example, Figure 5.1, Figure 5.2, and so on).

## Patient and shared interfaces

| File | Suggested figure title | Explanation |
|---|---|---|
| `01_patient_medical_id_card.png` | Figure X: Patient Medical ID dashboard | The updated dashboard presents the patient's core Medical ID and clearly separates the temporary consent QR from the permanent emergency-identification QR, alongside printable-summary and emergency-contact actions. |
| `02_patient_overview_top.png` | Figure X: Patient medical overview—verified allergies and prescriptions | The upper section of the medical overview displays verified allergies with severity levels alongside the patient's active prescriptions and dosage information. |
| `03_patient_overview_bottom.png` | Figure X: Patient medical overview—conditions and emergency information | The lower section presents chronic conditions, emergency contacts, care and coverage details, organ-donor status, and first-responder notes. |
| `04_clinical_history_vitals.png` | Figure X: Clinical encounter history and vital signs | The clinical timeline records previous encounters and shows the attending clinician, assessment notes, disposition, date, and vital-sign measurements for each visit. |
| `05_clinical_history_prescription.png` | Figure X: Prescription recorded within a clinical encounter | This detailed view demonstrates how a prescribed medicine, dose, frequency, duration, and clinical instruction are retained as part of an encounter. |
| `06_patient_profile_edit_form.png` | Figure X: Editing critical and coordination information | The emergency-profile form allows the patient to update blood group and optional coordination information such as primary physician and insurance details. |
| `07_patient_profile_edit_medical_details.png` | Figure X: Editing responder notes and allergy records | This portion of the profile form allows the patient to maintain first-responder information and structured allergy records, including reactions and severity. |
| `08_01_patient_profile_medical_conditions.png` | Figure X: Editing patient medical conditions | The medical-conditions section supports adding, reviewing, and removing chronic or high-risk conditions together with explanatory notes. |
| `08_02_patient_profile_medications.png` | Figure X: Editing patient medication details | The medication section records each medicine with its dosage and frequency so that current treatment information remains structured and readable. |
| `08_03_patient_profile_emergency_contacts.png` | Figure X: Editing emergency contacts | The emergency-contact form records a contact's name, relationship, and phone number and allows one contact to be designated as primary. |
| `08_04_patient_profile_validation_error.png` | Figure X: Patient-profile input validation | The required-field message demonstrates client-side validation preventing an incomplete emergency contact from being saved. |
| `10_patient_documents_page.png` | Figure X: Patient medical-document repository | The documents page lists uploaded PDF and image records with their category and size and provides controls for uploading, downloading, and deleting documents. |
| `11_patient_access_permissions.png` | Figure X: Patient access controls with collapsible records | The patient can select an authorized doctor and access duration, while the collapsible grant and history sections keep a long access record easy to navigate. |
| `12_patient_doctor_access_granted.png` | Figure X: Active patient-consented doctor grant | The expanded grant section shows a meaningful active patient-consent grant, its expiry time, and the patient's immediate revoke control. |
| `13_patient_medical_qr.png` | Figure X: Temporary one-use consent QR | The patient can generate a five-minute, one-use QR whose successful redemption gives the authenticated doctor a time-limited consented access grant. |
| `13_02_patient_permanent_emergency_qr.png` | Figure X: Permanent emergency identification QR | The reusable opaque QR identifies the patient to an authenticated doctor but does not open medical information or create an access grant by itself. |
| `14_patient_hamburger_menu.png` | Figure X: Patient navigation menu | The responsive side menu provides role-appropriate navigation to the medical overview, clinical history, documents, access controls, system information, accessibility settings, and sign-out function. |
| `15_patient_accessibility_settings.png` | Figure X: Accessibility and session preferences | The settings interface allows the current user to adjust text size, strengthen contrast, reduce motion, and restore default presentation preferences. |
| `16_01_patient_about_architecture.png` | Figure X: LifeGuard system architecture information | The About page identifies the implemented Flutter Web, ASP.NET Core API, Entity Framework Core, SQL Server, ASP.NET Core Identity, and JWT-based architecture. |
| `16_02_patient_about_capabilities.png` | Figure X: LifeGuard roles and emergency-workflow capabilities | This section summarizes the implemented capabilities of patients, doctors, and administrators and explains the controlled break-glass emergency workflow. |
| `17_login_page.png` | Figure X: LifeGuard authentication interface | The login screen accepts email and password credentials, confirms API connectivity, and provides entry to the clearly labelled biometric demonstration. |
| `18_Fingerprint_Simulation.png` | Figure X: Fingerprint verification simulation | The fingerprint interface visually demonstrates the proposed biometric workflow without accessing a physical fingerprint reader, storing biometric data, or replacing password authentication. |
| `19_face_scan_camera_simulation.png` | Figure X: Camera-backed face verification simulation | The face-scan demonstration displays the laptop's live camera preview with an animated scanning frame; it performs no facial recognition and saves no image or video. |

## Doctor interfaces

| File | Suggested figure title | Explanation |
|---|---|---|
| `20_Doctor_Dashboard.png` | Figure X: Doctor dashboard | The clinician dashboard identifies the signed-in doctor, displays the number of currently authorized patients, indicates the active clinical and audit modes, and provides QR-scanning and refresh controls. |
| `21_Doctor_Patient_Search.png` | Figure X: Doctor patient directory and access status | The directory allows a doctor to search and filter patient records while distinguishing authorized, locked, and emergency break-glass access states. |
| `22_Doctor_QR_Scanner.png` | Figure X: Dual-purpose Medical ID QR scanner | The same laptop-camera scanner accepts either a temporary consent QR or a permanent emergency-identification QR while keeping their access outcomes distinct. |
| `22_02_doctor_permanent_qr_identity_confirmation.png` | Figure X: Identity-only permanent QR result | After a permanent QR scan, the doctor can confirm the matched patient while the record remains locked; no access grant is created at this stage. |
| `22_03_doctor_break_glass_reason.png` | Figure X: Required emergency justification | To continue from identity confirmation, the authenticated doctor must enter a specific emergency reason before activating an audited 15-minute break-glass grant. |
| `23_01_doctor_emergency_access_summary.png` | Figure X: Minimum-necessary break-glass summary | The consolidated emergency-only view shows the audited reason, blood group, severe allergies, primary emergency contact, active medications, critical conditions, and first-responder notes. Clinical history, documents, insurance, AI tools, and encounter creation remain locked. |
| `24_Doctor_Document_Upload.png` | Figure X: Doctor clinical-document upload | The doctor can select a supported patient document, assign its clinical category, add optional notes, and attach it to the authorized patient's record. |
| `25_Doctor_AI_Medical_Summary.png` | Figure X: AI-assisted medical summary | The guarded AI function organizes existing patient data into overview, alert, condition, medication, and emergency-contact sections for clinician review rather than autonomous diagnosis. |
| `26_Doctor_Profile_Settings.png` | Figure X: Doctor professional-profile settings | The doctor can maintain self-reported professional title, hospital, department, licence number, and telephone information, with the unverified status clearly disclosed. |
| `27_Doctor_Navigation_Menu.png` | Figure X: Doctor navigation menu | The clinician menu provides access only to doctor-authorized functions, including the patient directory, QR scanner, professional profile, system information, accessibility settings, and sign out. |

## Administrator interfaces

| File | Suggested figure title | Explanation |
|---|---|---|
| `28_Administrator_Dashboard.png` | Figure X: Administrator dashboard and user accounts | The administrator dashboard summarizes total, active, and inactive accounts and lists the patient, doctor, and administrator users with their roles and current status. It permits the administrator to activate or deactivate other accounts while preventing self-deactivation. |
| `29_Administrator_Emergency_Access_Audit.png` | Figure X: Administrator emergency-access audit | The emergency-access activity list gives the administrator a metadata-only record of consented and break-glass events, including the doctor, patient, action, access type, and timestamp, without exposing the patient's clinical content. |

## Review notes

- The active set contains 35 useful screenshots. Replaced versions and the obsolete split `23_02` emergency-details image are retained under `screenshots/excluded/pre-update-2026-09-21` rather than deleted.
- The replacement face-scan screenshot shows the actual live camera preview. Confirm that its visible background contains no private information before inserting it into the thesis.
- The replacement clinical-prescription screenshot includes sufficient encounter context for use as a supporting detail figure.
- The QR-scanner, permanent-identity confirmation, and break-glass-reason images document the new emergency path without claiming that identification alone grants access.
- All displayed names and medical details should remain identified as synthetic thesis demonstration data.
