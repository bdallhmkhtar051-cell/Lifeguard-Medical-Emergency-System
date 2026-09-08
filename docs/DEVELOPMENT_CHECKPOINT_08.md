# Development Checkpoint 08 - Guarded AI Medical Summary

Date: 2026-09-08

## Outcome

An authorized doctor can generate a short AI summary from the patient's
current emergency profile and five most recent clinical encounters. The
summary is shown temporarily in the doctor portal and is not written into the
patient's medical record.

## Workflow

1. The doctor opens a patient through an active consent, QR, or break-glass
   access grant.
2. The doctor selects **Generate AI summary**.
3. ASP.NET verifies the doctor role and the active access grant again.
4. The backend sends only the authorized medical snapshot to Gemini.
5. Flutter displays the returned summary with its model, timestamp, and a
   clinical verification warning.

## Safety and security decisions

- The Gemini API key is stored in ASP.NET user secrets and never in Flutter.
- The endpoint inherits the existing doctor-only role policy and active-grant
  checks.
- Requests are limited to five per authenticated user every five minutes.
- The instruction forbids invented facts, diagnosis, and treatment advice.
- The interface tells the doctor to verify every detail against the source
  record.
- Generated text is temporary and is not stored as a clinical encounter.

## One-time local setup

Create a Gemini API key in Google AI Studio. Then run this command locally,
replacing the placeholder with the key. Do not paste the real key into source
code or commit it.

```powershell
dotnet user-secrets set "Gemini:ApiKey" "YOUR_GEMINI_API_KEY" --project backend\src\EmergencySystem.Api\EmergencySystem.Api.csproj
```

Restart the ASP.NET terminal after setting the secret. The configured model is
`gemini-3.7-flash` and can be changed through the `Gemini:Model` setting.

## Verification

- ASP.NET solution build: passed with zero warnings and zero errors.
- Application tests: 5 passed.
- API integration tests: 22 passed, including doctor authorization and patient
  rejection for the AI endpoint.
- Flutter analyzer: passed with no issues.
- AI/QR widget workflow: 5 passed.

The automated tests use a deterministic fake AI provider. A real summary needs
the local Gemini API key and internet access.
