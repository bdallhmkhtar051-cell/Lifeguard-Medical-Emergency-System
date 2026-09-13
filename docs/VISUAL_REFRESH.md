# LifeGuard visual refresh

This styling pass introduces white cards and dialogs, a pale blue workspace,
blue-to-teal patient and doctor headers, softer borders and shadows, and clearer
form and button typography. Medical warning colours and existing workflows are
preserved. The existing high-contrast setting remains available.

## Review the result

Keep the API running. Stop the existing Flutter process before using the same
web port, then run:

```powershell
.\scripts\run-web.cmd -Mode release
```

The default remains debug mode for development. Release mode is the appropriate
comparison for perceived scrolling speed; no measured frame-time improvement
has been established by this change. It has no hot reload.

Review the patient overview, doctor workspace, profile forms, and AI dialog at
desktop and narrow widths. Check the high-contrast setting and 130% text size.
This is an initial visual refresh, not pixel-for-pixel React parity.

The complete 47-test Flutter suite passed and static analysis reported no
issues during final checkpoint 17 verification.
