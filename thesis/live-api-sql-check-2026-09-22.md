# LifeGuard local API and SQL Server startup check — 22 September 2026

This is a short record of the live local check performed after the automated suite. It is separate from the integration tests, which use in-memory SQLite.

1. A request to `http://localhost:5080/health` before startup could not connect because no API process was listening.
2. The first API startup inside the restricted sandbox could not complete because the process lacked Windows Event Log access while reporting a database-connection error. That attempt does not establish an application defect.
3. The same `scripts/run-api.cmd` startup was retried with the required local permissions. It queried the local `EmergencySystem` SQL Server database, including role, user and patient-profile tables, and logged `Now listening on: http://localhost:5080`.
4. A GET request to `http://localhost:5080/health` returned HTTP **200** with `{"status":"healthy","service":"EmergencySystem.Api"}`.
5. The temporary API verification process was then stopped.

This check establishes local startup, SQL connectivity and the health response. It does not establish production deployment, database backup/recovery, live Gemini, load capacity or clinical safety. No credentials or connection-string values are recorded here.
