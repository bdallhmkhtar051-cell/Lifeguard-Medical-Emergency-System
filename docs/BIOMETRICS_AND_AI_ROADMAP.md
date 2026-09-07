# Biometrics and AI roadmap

Decision date: 2026-07-28

## Decision

Implement real **device-backed passkey authentication** as the biometric goal
for the web thesis. Do not build a fingerprint database, a face-template
database, or a custom recognition algorithm.

Keep AI outside the implementation scope and describe it as future work. If a
small AI experiment is considered after the feature freeze, it must use
synthetic data, run through the ASP.NET backend, require human review, and never
make a diagnosis, triage decision, prescription, or emergency-dispatch
decision.

## Authentication and authorization are different

Biometric/passkey authentication answers:

> Is this the account holder who controls the registered device credential?

Consent and role authorization answer:

> Is this authenticated doctor allowed to access this patient's information
> for this purpose at this time?

A successful face or fingerprint check must never bypass patient consent,
doctor role checks, time limits, or the audited break-glass process.

## Recommended web biometric design

Use WebAuthn/passkeys:

```text
1. User signs in and chooses "Add a passkey"
2. ASP.NET generates a one-time registration challenge
3. Flutter Web asks the browser to create a WebAuthn credential
4. Windows Hello / phone / security key verifies the user locally
5. The device signs the challenge
6. ASP.NET verifies it and stores the public credential in SQL Server

Later sign-in:

1. ASP.NET sends a new one-time challenge
2. Browser asks the device for user verification
3. Device may use face, fingerprint, device PIN, or another configured method
4. Device signs the challenge
5. ASP.NET verifies the signature and signs the user in
```

The server stores a public key and credential metadata, not a fingerprint image,
face image, or reusable biometric template. The W3C specification explicitly
states that biometric data is used locally and is not revealed to the relying
web application.

ASP.NET Core Identity in .NET 10 has passkey registration and authentication
support. Its default template is Blazor-specific, so the Flutter client will
need small custom API endpoints plus browser WebAuthn integration. Dart's
recommended browser-integration tools are `package:web` and
`dart:js_interop`.

Primary references:

- [W3C Web Authentication Level 3](https://www.w3.org/TR/webauthn-3/)
- [ASP.NET Core Identity passkeys](https://learn.microsoft.com/en-us/aspnet/core/security/authentication/passkeys/?view=aspnetcore-10.0)
- [Dart JavaScript interoperability](https://dart.dev/interop/js-interop)

## What the web application can and cannot know

The browser can return signed proof that the authenticator performed user
verification. The normal web flow does not give the application the user's
fingerprint, facial scan, or retinal/iris data.

The operating system chooses an available verification method. It may show:

- Windows Hello face or fingerprint;
- Android fingerprint/face or screen lock;
- Touch ID or Face ID;
- a security key;
- a device PIN as an accessibility/recovery option.

Therefore the interface should say **Sign in with a passkey** or
**Use device verification**, not promise **Fingerprint sign-in** on every
device. The website generally should not claim that a particular biometric was
used; it knows that user verification succeeded.

Retina/iris recognition is excluded. Ordinary browsers and most consumer
devices do not expose a general retinal/iris sensor API to web applications.

## Difficulty and time

| Approach | Thesis suitability | Difficulty | Realistic time |
| --- | --- | ---: | ---: |
| WebAuthn/passkey using device face/fingerprint | Recommended and real | Medium | 8–12 focused working days |
| Fake biometric animation/timer | Weak evidence; UI mock only | Easy | 1–2 days |
| Browser webcam plus custom face matching | Research demo, not strong authentication | Hard | 3–6 weeks for a limited prototype |
| Production-grade face recognition with liveness/anti-spoofing | Outside scope | Very hard | Multiple months and specialist review |
| Raw phone/laptop fingerprint capture from a web page | Not available through standard web APIs | Not feasible as a normal web feature | Requires native/vendor hardware work |
| External USB fingerprint scanner with vendor SDK | Possible only for selected hardware | Hard and device-specific | 3–8+ weeks plus hardware |

The 8–12 day passkey estimate includes:

- ASP.NET registration and assertion endpoints;
- SQL/Identity credential storage;
- Flutter Web browser interop;
- add, name, list, and remove-passkey screens;
- password/recovery fallback;
- HTTPS/origin configuration;
- audit events and negative tests;
- testing on more than one browser/device.

It assumes ordinary password authentication and role authorization are already
working. Do not begin passkeys before that foundation is stable.

## Presentation and testing approach

Use both real and virtual authenticators:

- **Live presentation:** register and sign in with Windows Hello face on the
  development laptop. The machine exposes a Windows Hello facial-recognition
  software device and an HP IR camera; enrollment still needs to be verified.
- **Fingerprint demonstration:** use an Android phone with an enrolled
  fingerprint if one is available. The same WebAuthn implementation should be
  exercised; no fingerprint-specific server code is needed.
- **Automated testing:** use a standards-based virtual authenticator to test
  successful verification, failed verification, unknown credentials, and
  replay/challenge failures.
- **Fallback:** retain password/recovery sign-in and a short backup video. Do
  not replace a failed live biometric prompt with a fake success animation.

### Definition of done

Passkey authentication is complete only when:

1. A signed-in user can register and name a passkey.
2. Only public credential material is stored by the server.
3. The user can sign out and sign in with that passkey.
4. A wrong origin, expired/wrong challenge, unknown credential, or failed user
   verification is rejected.
5. The user can list and revoke registered passkeys.
6. Registration, authentication, failure, and removal create server audit
   events without recording biometric data.
7. Account recovery is documented and tested.
8. The flow works through HTTPS on the presentation deployment.

## AI as future work

Potential future research directions:

- clinician-reviewed summarization of a patient's timeline;
- extraction of structured fields from uploaded documents;
- multilingual explanation of non-diagnostic patient instructions;
- anomaly detection in administrative audit events;
- natural-language search over approved synthetic records.

Future AI architecture:

```text
Flutter -> ASP.NET authorization/redaction layer -> AI adapter -> provider
                       |
                       +-> audit, feature flag, consent, human confirmation
```

Rules for any future AI capability:

- Never place an AI provider key in Flutter.
- Send the minimum necessary information and default to synthetic/de-identified
  data.
- Require a clinician to review generated content before it is saved.
- Label output as generated and record model/version/time.
- Do not allow generated output to overwrite source medical records.
- Define failure, privacy, bias, retention, and opt-out behavior first.
- Keep deterministic emergency information available when AI is unavailable.

For this thesis, these are recommendations in the conclusion/future-work
chapter, not claims about implemented functionality.
