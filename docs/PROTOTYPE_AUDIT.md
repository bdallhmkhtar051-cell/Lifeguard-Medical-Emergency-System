# Prototype and source-material audit

Audit date: 2026-07-28

## Materials reviewed

- `IST Thesis Guidelines.pdf`
- `the project structure.docx`
- `lifeguard-medical-id-system (1).zip`
- `pulseemergency---medcommand-&-triage.zip`

The archives were inspected as reference material. Their source code has not
been copied into the Flutter application.

## Important document mismatch

`the project structure.docx` is titled **Shop Development Specification**. It
defines retail/wholesale ERP features such as POS, inventory, purchasing,
accounting, debt collection, and multi-branch reporting. It contains no
medical-emergency project description. A correct medical thesis description is
still required before the final title, problem statement, objectives, and
requirements can be approved.

## What the prototypes really are

Both ZIP files are presentation-oriented React/TypeScript prototypes. They
contain useful visual ideas and workflow concepts, but they are not working
medical systems and do not use the selected thesis stack.

| Area | Lifeguard prototype | PulseEmergency prototype |
| --- | --- | --- |
| UI | Polished patient, doctor, consent, emergency, timeline, and ID screens | Polished patient and doctor dashboards, records, contacts, SOS, and access log |
| Data | One hard-coded patient; in-memory state | Hard-coded patients; in-memory state |
| Backend | None | Small Express/Gemini server not connected to the UI |
| Authentication | Role switch/simulated access | Plaintext client-side PIN/simulated override |
| Database | None | None |
| QR | Decorative/random visual | Decorative visual |
| SOS/dispatch | Static or timed simulation | Five-second state change; no GPS or dispatch |
| Biometrics | Timers that always succeed | Not implemented |
| AI | Direct client Gemini calls | Standalone server endpoints; UI does not call them |
| Testing | None | None |
| Main value | UX and feature discovery | UX and workflow discovery |

## Useful ideas to reimplement correctly

- Separate patient, doctor, and administrator experiences.
- A concise emergency medical snapshot.
- Patient-controlled, time-limited consent.
- A carefully controlled emergency break-glass path.
- A visible access/audit history.
- Medical timeline and doctor-created encounter records.
- Emergency contacts.
- A real QR token that resolves through the secured API.

## Behaviors that must not be copied

- Client-side role switching as authorization.
- Plaintext access PINs or passwords.
- Medical data stored only in browser state or unencrypted local storage.
- Fake QR codes, biometrics, blockchain, dispatch, or uploads presented as real.
- Directly exposing an AI key in the web client.
- Sending patient information to an AI service without an approved privacy and
  safety design.
- Mutable or client-generated audit logs.
- AI-generated medical decisions.

## Thesis-guideline implications

The institutional guideline requires:

- a defined problem, objectives, scope, and significance;
- related work and a research gap;
- methodology, technologies, and architecture;
- use-case/ERD or equivalent system diagrams;
- implementation, testing, performance analysis, and discussion;
- conclusion and future recommendations;
- database integration;
- a GitHub or GitLab repository;
- preferably a deployed system;
- source code, a functional system/prototype, thesis document, and slides;
- APA 7 citations and academic integrity.

The evaluation weights are:

| Component | Weight |
| --- | ---: |
| Problem definition | 10% |
| Literature review | 15% |
| Methodology | 15% |
| Implementation | 25% |
| Results and analysis | 15% |
| Documentation | 10% |
| Presentation | 10% |

Implementation is the largest single item, but 75% of the evaluation is not
implementation. Writing, diagrams, testing evidence, and the final defense must
progress alongside the code.
