# Development checkpoint 15: accessibility and settings

**Completed:** 12 September 2026

## Outcome

Every authenticated LifeGuard role now has an Accessibility & Settings page.
Its controls affect the current workspace session and do not change medical
records, user permissions, or backend configuration.

## Implemented behavior

- Text size can be set to 100%, 110%, 120%, or 130%.
- High contrast strengthens theme borders, outlines, and control colors.
- Reduced motion sets Flutter's `MediaQuery.disableAnimations` preference.
- Reset restores all three preferences to their defaults.
- Session information displays the authenticated name, email, role, and the
  real expiry calculated from the JWT login response.
- The page explains that tokens remain in application memory and are cleared
  by sign-out or browser refresh.

## Scope boundary

Preferences are intentionally session scoped and are not written to SQL
Server or browser storage. This avoids creating another personal-data store.
Reduced motion communicates a platform preference; third-party components may
still control their own internal animation. Manual keyboard and screen-reader
checks remain part of final presentation testing.

## Main files

- `lib/src/features/home/accessibility_settings_page.dart`
- `lib/src/features/home/home_shell.dart`
- `lib/src/features/home/workspace_navigation.dart`
- `lib/src/core/theme/app_theme.dart`
- `test/app/emergency_system_app_test.dart`

## Verification

- Flutter analyzer: no issues found.
- Flutter tests: **44 passed**.
- Application tests: **6 passed**.
- API integration tests: **23 passed**.
- Automated accessibility test enables high contrast and reduced motion,
  raises text to 130% at 390-pixel width, verifies the applied environment,
  resets it, and confirms there is no layout exception.
