# Development Checkpoint 06 - Administrator User Management

Date: 2026-09-07

## Outcome

The Administrator role now opens a real system-administration dashboard. An
administrator can review every account, activate or deactivate another user,
review account-management history, and review emergency-access audit metadata.

## Security and authorization

- All administration endpoints require the server-side `AdministratorOnly`
  authorization policy.
- Patients and doctors receive `403 Forbidden`; hiding the page in Flutter is
  not treated as security.
- An administrator cannot deactivate their own account.
- Deactivation rotates the ASP.NET Identity security stamp. Existing access
  tokens are rejected on their next API request, and new logins are denied.
- Account status changes create append-only audit records containing the
  administrator, target account, action, and UTC timestamp.
- The system-access overview exposes audit metadata only. It does not return
  diagnoses, medications, observations, prescriptions, or clinical notes.
- Sensitive Identity fields such as password hashes and security stamps are
  never returned to Flutter.

## Database change

- Added `AccountAdministrationEvents` with restricted foreign keys to the
  administrator and target users.
- Added indexes for target user and event time.
- Migration: `20260907194120_AddAdministrationModule`.
- The migration was applied to the local SQL Server `EmergencySystem` database.

## API additions

- `GET /api/v1/admin/users`
- `PUT /api/v1/admin/users/{userId}/status`
- `GET /api/v1/admin/account-audit`
- `GET /api/v1/admin/access-audit`

## Flutter additions

- Replaced the administrator placeholder with a responsive dashboard.
- Added total, active, and inactive account summaries.
- Added desktop table and narrow-screen account-card layouts.
- Added confirmation before account activation or deactivation.
- Added account-management and emergency-access activity sections.
- Added loading, refresh, error, progress, and result-feedback states.

## Verification

- C# build: passed with zero warnings.
- Application tests: 5 passed.
- API integration tests: 21 passed.
- Dart analyzer: passed with no issues.
- Flutter tests: 31 passed.
- Flutter release web build: passed.

## Presentation workflow

1. Sign in as the administrator.
2. Show the three account summary cards and role-separated user list.
3. Deactivate the doctor account and show the new account-audit entry.
4. Prove the doctor can no longer use an existing session or sign in again.
5. Reactivate the doctor and show the second audit entry.
6. Show emergency-access activity and explain that it contains security
   metadata but no clinical record content.

## Deliberate limitations

- The administrator cannot create accounts or assign roles in this milestone.
- Accounts are deactivated rather than deleted so related audit and medical
  history remains intact.
- The audit overview displays the latest 100 events and does not yet provide
  date, user, or action filters.
