# Development Checkpoint 19 - Camera-Backed Face Simulation

Date: 2026-09-14

## Outcome

The face-scan demonstration now opens the browser's front-facing camera and
shows its live preview beneath the animated scanning frame. After 3.2 seconds,
the interface displays a simulated success or unsuccessful result. Fingerprint
mode remains a visual-only demonstration.

## Honest implementation boundary

- The camera preview is real and requires Chrome camera permission.
- The scan line and identity-match result are simulated.
- No facial detection, facial recognition, liveness detection, or comparison
  against an enrolled identity is performed.
- The application does not capture, upload, save, or persist camera frames.
- Neither face nor fingerprint mode calls the login API or creates a session.
- Password authentication remains required.

This must be presented as a **camera-backed face-scan simulation**, not as real
biometric authentication.

## Verification

- Dart static analysis completed with no issues.
- The existing widget test uses fingerprint mode to verify that simulated
  success cannot call the authentication repository or sign the user in.
- Camera permission, preview, cancellation, and front-camera availability
  require a manual Chrome check on the presentation laptop.
