# LifeGuard dual QR access contract

**Status:** Implemented by the ASP.NET Core backend and Flutter Web interface.

## Purpose

LifeGuard uses one doctor scanner for two QR formats. Identification and
authorization remain separate: no permanent QR can unlock clinical data.

## Temporary consent QR

- Created by the signed-in patient on demand.
- Contains the existing short-lived random token in a same-origin link.
- Valid for five minutes and one redemption.
- A signed-in doctor redeeming it receives the existing fifteen-minute
  `QrConsented` access grant.
- Expired, revoked, malformed, or previously redeemed tokens are rejected.

## Permanent emergency identification QR

- Every patient owns a stable random `EmergencyMedicalId`.
- Payload format: `LIFEGUARD:EMERGENCY:1:{32-character GUID}`.
- It contains no medical information, login credential, consent, or grant.
- Only an authenticated Doctor can resolve it.
- Resolution returns only the internal patient-profile identifier and patient
  name needed for confirmation and the existing break-glass workflow.
- Resolution does not create an access grant and does not expose clinical data.
- A patient can rotate the identifier, immediately invalidating printed copies
  of the previous QR.

## Implemented scanner routing

```text
Temporary QR -> existing redemption endpoint -> consented access
Permanent QR -> emergency identification endpoint -> locked patient screen
Other QR     -> generic unsupported/invalid message
```

The locked patient screen requires the doctor to invoke the existing
break-glass workflow, provide a 20-500 character reason, and receive the
existing fifteen-minute audited `BreakGlass` grant.

The patient interface displays the permanent identifier separately from the
temporary consent QR. It provides a printable emergency-card view and a
confirmed replacement action. Replacing the identifier immediately makes old
cards, bracelets, screenshots and other printed copies invalid.

While a doctor has a patient record open, Flutter revalidates the active grant
every five seconds without downloading the clinical record or recording extra
view events. Revocation, server-reported expiry, or local expiry closes the
displayed record. Manual refresh performs the same protected check immediately.
This removes data from the current interface; it cannot make information that
was already viewed unknown to the clinician.

## API contract

| Method | Route | Role | Effect |
|---|---|---|---|
| `GET` | `/api/v1/patients/me/emergency-medical-id` | Patient | Returns the patient's identifier and permanent QR payload. |
| `POST` | `/api/v1/patients/me/emergency-medical-id/rotate` | Patient | Replaces the permanent identifier and invalidates the old payload. |
| `POST` | `/api/v1/doctors/emergency-access/medical-qr/identify-emergency` | Doctor | Resolves a permanent QR to minimal patient identity only. |

The patient rotation and doctor-resolution operations use the existing bounded
Medical QR rate-limit policy. Invalid, unknown, or replaced permanent payloads
return the same generic not-found response.

## Explicit exclusions

- No doctor-to-patient notification or pending request workflow.
- No automatic access from a permanent QR.
- No clinical fields in the identification response.
- No anonymous, Patient-role, or Administrator-role resolution.
- No native lock-screen integration or physical bracelet production.
