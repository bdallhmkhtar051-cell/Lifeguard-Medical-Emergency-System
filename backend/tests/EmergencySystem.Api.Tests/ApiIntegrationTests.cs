using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using EmergencySystem.Application.Access;
using EmergencySystem.Application.Authentication;
using EmergencySystem.Application.Clinical;
using EmergencySystem.Application.Profiles;
using EmergencySystem.Domain.Access;
using EmergencySystem.Domain.Identity;
using EmergencySystem.Domain.Patients;
using EmergencySystem.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace EmergencySystem.Api.Tests;

public sealed class ApiIntegrationTests
{
    private static readonly JsonSerializerOptions JsonOptions = CreateJsonOptions();

    [Fact]
    public async Task Health_is_available_without_authentication()
    {
        using var factory = new EmergencySystemApiFactory();
        await factory.InitializeAsync();
        using var client = CreateClient(factory);

        var response = await client.GetAsync("/health");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var payload = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("healthy", payload.GetProperty("status").GetString());
    }

    [Fact]
    public async Task Patient_can_login_and_read_current_user()
    {
        using var factory = new EmergencySystemApiFactory();
        await factory.InitializeAsync();
        using var client = CreateClient(factory);

        var login = await LoginAsync(
            client,
            EmergencySystemApiFactory.PatientEmail);
        var response = await client.GetAsync("/api/v1/auth/me");
        var currentUser = await response.Content
            .ReadFromJsonAsync<CurrentUserResponse>(JsonOptions);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.NotNull(currentUser);
        Assert.Equal(EmergencySystemApiFactory.PatientEmail, currentUser.Email);
        Assert.Contains(RoleNames.Patient, currentUser.Roles);
        Assert.True(currentUser.HasEmergencyProfile);
        Assert.Equal("Bearer", login.TokenType);
        Assert.InRange(login.ExpiresInSeconds, 850, 900);
    }

    [Fact]
    public async Task Invalid_password_returns_generic_problem_details()
    {
        using var factory = new EmergencySystemApiFactory();
        await factory.InitializeAsync();
        using var client = CreateClient(factory);

        var response = await client.PostAsJsonAsync(
            "/api/v1/auth/login",
            new LoginRequest
            {
                Email = EmergencySystemApiFactory.PatientEmail,
                Password = "IncorrectPassword!123",
            });

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
        Assert.Equal(
            "application/problem+json",
            response.Content.Headers.ContentType?.MediaType);
        var problem = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("Authentication failed", problem.GetProperty("title").GetString());
    }

    [Fact]
    public async Task Doctor_cannot_read_a_patient_profile()
    {
        using var factory = new EmergencySystemApiFactory();
        await factory.InitializeAsync();
        using var client = CreateClient(factory);
        await LoginAsync(client, EmergencySystemApiFactory.DoctorEmail);

        var response = await client.GetAsync(
            "/api/v1/patients/me/emergency-profile");

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
        Assert.Equal(
            "application/problem+json",
            response.Content.Headers.ContentType?.MediaType);
    }

    [Fact]
    public async Task Patient_can_update_profile_and_stale_etag_is_rejected()
    {
        using var factory = new EmergencySystemApiFactory();
        await factory.InitializeAsync();
        using var client = CreateClient(factory);
        await LoginAsync(client, EmergencySystemApiFactory.PatientEmail);

        var initialResponse = await client.GetAsync(
            "/api/v1/patients/me/emergency-profile");
        var initialProfile = await initialResponse.Content
            .ReadFromJsonAsync<EmergencyProfileResponse>(JsonOptions);
        var initialEtag = initialResponse.Headers.ETag;

        Assert.Equal(HttpStatusCode.OK, initialResponse.StatusCode);
        Assert.NotNull(initialProfile);
        Assert.NotNull(initialEtag);
        Assert.All(initialProfile.Allergies, item => Assert.NotEqual(Guid.Empty, item.Id));
        Assert.All(initialProfile.MedicalConditions, item => Assert.NotEqual(Guid.Empty, item.Id));
        using (var scope = factory.Services.CreateScope())
        {
            var databaseVersion = await scope.ServiceProvider
                .GetRequiredService<ApplicationDbContext>()
                .PatientProfiles
                .AsNoTracking()
                .Select(profile => profile.Version)
                .SingleAsync();
            Assert.Equal(
                Guid.Parse(initialEtag.Tag.Trim('"')),
                databaseVersion);
        }

        var update = ValidUpdate("Updated Test Patient");
        var updateResponse = await PutProfileAsync(client, update, initialEtag.Tag);
        var updatedProfile = await updateResponse.Content
            .ReadFromJsonAsync<EmergencyProfileResponse>(JsonOptions);

        Assert.Equal(HttpStatusCode.OK, updateResponse.StatusCode);
        Assert.NotNull(updatedProfile);
        Assert.Equal("Updated Test Patient", updatedProfile.FullName);
        Assert.NotNull(updateResponse.Headers.ETag);
        Assert.NotEqual(initialEtag.Tag, updateResponse.Headers.ETag.Tag);

        var staleResponse = await PutProfileAsync(client, update, initialEtag.Tag);
        Assert.Equal(HttpStatusCode.PreconditionFailed, staleResponse.StatusCode);

        var persistedResponse = await client.GetAsync(
            "/api/v1/patients/me/emergency-profile");
        var persistedProfile = await persistedResponse.Content
            .ReadFromJsonAsync<EmergencyProfileResponse>(JsonOptions);
        Assert.Equal("Updated Test Patient", persistedProfile?.FullName);
    }

    [Fact]
    public async Task Invalid_profile_is_rejected_without_changing_persisted_data()
    {
        using var factory = new EmergencySystemApiFactory();
        await factory.InitializeAsync();
        using var client = CreateClient(factory);
        await LoginAsync(client, EmergencySystemApiFactory.PatientEmail);

        var initialResponse = await client.GetAsync(
            "/api/v1/patients/me/emergency-profile");
        var etag = Assert.IsType<EntityTagHeaderValue>(initialResponse.Headers.ETag);
        var invalidUpdate = ValidUpdate("X") with
        {
            DateOfBirth = DateOnly.FromDateTime(DateTime.UtcNow).AddDays(1),
        };

        var invalidResponse = await PutProfileAsync(
            client,
            invalidUpdate,
            etag.Tag);

        Assert.Equal(HttpStatusCode.BadRequest, invalidResponse.StatusCode);
        Assert.Equal(
            "application/problem+json",
            invalidResponse.Content.Headers.ContentType?.MediaType);

        var persistedResponse = await client.GetAsync(
            "/api/v1/patients/me/emergency-profile");
        var persistedProfile = await persistedResponse.Content
            .ReadFromJsonAsync<EmergencyProfileResponse>(JsonOptions);
        Assert.Equal("Test Patient", persistedProfile?.FullName);
    }

    [Fact]
    public async Task Put_requires_an_explicit_etag_precondition()
    {
        using var factory = new EmergencySystemApiFactory();
        await factory.InitializeAsync();
        using var client = CreateClient(factory);
        await LoginAsync(client, EmergencySystemApiFactory.PatientEmail);

        var response = await client.PutAsJsonAsync(
            "/api/v1/patients/me/emergency-profile",
            ValidUpdate("Updated Test Patient"),
            JsonOptions);

        Assert.Equal((HttpStatusCode)428, response.StatusCode);
    }

    [Fact]
    public async Task Patient_grant_enables_audited_doctor_view_and_revocation_blocks_it()
    {
        using var factory = new EmergencySystemApiFactory();
        await factory.InitializeAsync();
        using var patientClient = CreateClient(factory);
        using var doctorClient = CreateClient(factory);
        await LoginAsync(patientClient, EmergencySystemApiFactory.PatientEmail);
        await LoginAsync(doctorClient, EmergencySystemApiFactory.DoctorEmail);

        var emptyAccess = await doctorClient.GetFromJsonAsync<DoctorAccessResponse[]>(
            "/api/v1/doctors/emergency-access", JsonOptions);
        Assert.Empty(Assert.IsType<DoctorAccessResponse[]>(emptyAccess));

        var grantResponse = await patientClient.PostAsJsonAsync(
            "/api/v1/patients/me/emergency-access",
            new GrantEmergencyAccessRequest(EmergencySystemApiFactory.DoctorEmail, 60),
            JsonOptions);
        var grant = await grantResponse.Content
            .ReadFromJsonAsync<EmergencyAccessGrantResponse>(JsonOptions);
        Assert.Equal(HttpStatusCode.OK, grantResponse.StatusCode);
        Assert.NotNull(grant);
        Assert.True(grant.IsActive);

        var doctorAccess = await doctorClient.GetFromJsonAsync<DoctorAccessResponse[]>(
            "/api/v1/doctors/emergency-access", JsonOptions);
        var available = Assert.Single(Assert.IsType<DoctorAccessResponse[]>(doctorAccess));
        Assert.Equal(grant.Id, available.GrantId);

        var snapshotResponse = await doctorClient.GetAsync(
            $"/api/v1/doctors/emergency-access/{grant.Id}/snapshot");
        var snapshot = await snapshotResponse.Content
            .ReadFromJsonAsync<DoctorEmergencySnapshotResponse>(JsonOptions);
        Assert.Equal(HttpStatusCode.OK, snapshotResponse.StatusCode);
        Assert.Equal("Test Patient", snapshot?.Profile.FullName);

        var dashboard = await patientClient.GetFromJsonAsync<PatientAccessDashboardResponse>(
            "/api/v1/patients/me/emergency-access", JsonOptions);
        Assert.NotNull(dashboard);
        Assert.Contains(dashboard.AuditHistory, item => item.Action == AccessAuditAction.Granted);
        Assert.Contains(dashboard.AuditHistory, item => item.Action == AccessAuditAction.Viewed);

        var revokeResponse = await patientClient.PostAsync(
            $"/api/v1/patients/me/emergency-access/{grant.Id}/revoke", null);
        Assert.Equal(HttpStatusCode.NoContent, revokeResponse.StatusCode);

        var deniedSnapshot = await doctorClient.GetAsync(
            $"/api/v1/doctors/emergency-access/{grant.Id}/snapshot");
        Assert.Equal(HttpStatusCode.NotFound, deniedSnapshot.StatusCode);
    }

    [Fact]
    public async Task Doctor_break_glass_requires_reason_and_creates_audited_temporary_access()
    {
        using var factory = new EmergencySystemApiFactory();
        await factory.InitializeAsync();
        using var patientClient = CreateClient(factory);
        using var doctorClient = CreateClient(factory);
        await LoginAsync(patientClient, EmergencySystemApiFactory.PatientEmail);
        await LoginAsync(doctorClient, EmergencySystemApiFactory.DoctorEmail);

        var directory = await doctorClient
            .GetFromJsonAsync<DoctorPatientDirectoryResponse[]>(
                "/api/v1/doctors/emergency-access/directory",
                JsonOptions);
        var patient = Assert.Single(
            Assert.IsType<DoctorPatientDirectoryResponse[]>(directory));

        var invalidResponse = await doctorClient.PostAsJsonAsync(
            "/api/v1/doctors/emergency-access/break-glass",
            new BreakGlassAccessRequest(patient.PatientProfileId, "Too vague"),
            JsonOptions);
        Assert.Equal(HttpStatusCode.BadRequest, invalidResponse.StatusCode);

        const string reason =
            "Patient is unconscious and immediate allergy verification is required.";
        var overrideResponse = await doctorClient.PostAsJsonAsync(
            "/api/v1/doctors/emergency-access/break-glass",
            new BreakGlassAccessRequest(patient.PatientProfileId, reason),
            JsonOptions);
        var emergencyAccess = await overrideResponse.Content
            .ReadFromJsonAsync<DoctorAccessResponse>(JsonOptions);

        Assert.Equal(HttpStatusCode.OK, overrideResponse.StatusCode);
        Assert.NotNull(emergencyAccess);
        Assert.Equal(EmergencyAccessType.BreakGlass, emergencyAccess.AccessType);
        Assert.Equal(reason, emergencyAccess.EmergencyReason);
        Assert.InRange(
            emergencyAccess.ExpiresAtUtc - DateTimeOffset.UtcNow,
            TimeSpan.FromMinutes(14),
            TimeSpan.FromMinutes(16));

        var snapshotResponse = await doctorClient.GetAsync(
            $"/api/v1/doctors/emergency-access/{emergencyAccess.GrantId}/snapshot");
        var snapshot = await snapshotResponse.Content
            .ReadFromJsonAsync<DoctorEmergencySnapshotResponse>(JsonOptions);
        Assert.Equal(HttpStatusCode.OK, snapshotResponse.StatusCode);
        Assert.Equal(EmergencyAccessType.BreakGlass, snapshot?.AccessType);
        Assert.Equal(reason, snapshot?.EmergencyReason);

        var dashboard = await patientClient
            .GetFromJsonAsync<PatientAccessDashboardResponse>(
                "/api/v1/patients/me/emergency-access",
                JsonOptions);
        Assert.NotNull(dashboard);
        Assert.Contains(
            dashboard.Grants,
            item => item.AccessType == EmergencyAccessType.BreakGlass &&
                    item.EmergencyReason == reason);
        Assert.Contains(
            dashboard.AuditHistory,
            item => item.Action == AccessAuditAction.BreakGlassActivated);
        Assert.Contains(
            dashboard.AuditHistory,
            item => item.Action == AccessAuditAction.Viewed);
    }

    [Fact]
    public async Task Patient_cannot_activate_doctor_break_glass_endpoint()
    {
        using var factory = new EmergencySystemApiFactory();
        await factory.InitializeAsync();
        using var client = CreateClient(factory);
        await LoginAsync(client, EmergencySystemApiFactory.PatientEmail);

        var response = await client.PostAsJsonAsync(
            "/api/v1/doctors/emergency-access/break-glass",
            new BreakGlassAccessRequest(Guid.NewGuid(), new string('A', 30)),
            JsonOptions);

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task Doctor_can_create_clinical_record_during_access_and_patient_can_read_it()
    {
        using var factory = new EmergencySystemApiFactory();
        await factory.InitializeAsync();
        using var patientClient = CreateClient(factory);
        using var doctorClient = CreateClient(factory);
        await LoginAsync(patientClient, EmergencySystemApiFactory.PatientEmail);
        await LoginAsync(doctorClient, EmergencySystemApiFactory.DoctorEmail);

        var grantResponse = await patientClient.PostAsJsonAsync(
            "/api/v1/patients/me/emergency-access",
            new GrantEmergencyAccessRequest(EmergencySystemApiFactory.DoctorEmail, 60),
            JsonOptions);
        var grant = await grantResponse.Content
            .ReadFromJsonAsync<EmergencyAccessGrantResponse>(JsonOptions);
        Assert.NotNull(grant);

        var request = new CreateClinicalEncounterRequest(
            "Shortness of breath",
            "Patient assessed, treated, and stable after observation.",
            "Discharged with respiratory follow-up",
            DateTimeOffset.UtcNow,
            new ClinicalObservationInput(37.2m, 92, 125, 78, 97, 19),
            [new PrescriptionInput(
                "Salbutamol", "100 mcg", "As needed", "7 days", "Use spacer")]);
        var createResponse = await doctorClient.PostAsJsonAsync(
            $"/api/v1/doctors/emergency-access/{grant.Id}/clinical-records",
            request,
            JsonOptions);
        var created = await createResponse.Content
            .ReadFromJsonAsync<ClinicalEncounterResponse>(JsonOptions);

        Assert.Equal(HttpStatusCode.Created, createResponse.StatusCode);
        Assert.NotNull(created);
        Assert.Equal("Test Patient", created.PatientName);
        Assert.Equal("Test Doctor", created.DoctorName);
        Assert.Equal(97, created.Observation?.OxygenSaturationPercent);
        Assert.Single(created.Prescriptions);

        var doctorHistory = await doctorClient
            .GetFromJsonAsync<ClinicalEncounterResponse[]>(
                $"/api/v1/doctors/emergency-access/{grant.Id}/clinical-records",
                JsonOptions);
        Assert.Single(Assert.IsType<ClinicalEncounterResponse[]>(doctorHistory));

        var patientHistory = await patientClient
            .GetFromJsonAsync<ClinicalEncounterResponse[]>(
                "/api/v1/patients/me/clinical-records",
                JsonOptions);
        Assert.Single(Assert.IsType<ClinicalEncounterResponse[]>(patientHistory));

        var dashboard = await patientClient
            .GetFromJsonAsync<PatientAccessDashboardResponse>(
                "/api/v1/patients/me/emergency-access", JsonOptions);
        Assert.Contains(
            dashboard!.AuditHistory,
            item => item.Action == AccessAuditAction.ClinicalRecordCreated);
    }

    [Fact]
    public async Task Doctor_cannot_create_clinical_record_without_active_access()
    {
        using var factory = new EmergencySystemApiFactory();
        await factory.InitializeAsync();
        using var doctorClient = CreateClient(factory);
        await LoginAsync(doctorClient, EmergencySystemApiFactory.DoctorEmail);

        var response = await doctorClient.PostAsJsonAsync(
            $"/api/v1/doctors/emergency-access/{Guid.NewGuid()}/clinical-records",
            new CreateClinicalEncounterRequest(
                "Emergency assessment",
                "No active grant should prevent this record from being created.",
                null,
                null,
                null,
                []),
            JsonOptions);

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task Break_glass_attempts_are_rate_limited()
    {
        using var factory = new EmergencySystemApiFactory();
        await factory.InitializeAsync();
        using var client = CreateClient(factory);
        await LoginAsync(client, EmergencySystemApiFactory.DoctorEmail);

        for (var attempt = 0; attempt < 3; attempt++)
        {
            var invalid = await client.PostAsJsonAsync(
                "/api/v1/doctors/emergency-access/break-glass",
                new BreakGlassAccessRequest(Guid.NewGuid(), "Too vague"),
                JsonOptions);
            Assert.Equal(HttpStatusCode.BadRequest, invalid.StatusCode);
        }

        var limited = await client.PostAsJsonAsync(
            "/api/v1/doctors/emergency-access/break-glass",
            new BreakGlassAccessRequest(Guid.NewGuid(), "Too vague"),
            JsonOptions);
        Assert.Equal(HttpStatusCode.TooManyRequests, limited.StatusCode);
    }

    [Fact]
    public async Task Cors_allows_only_the_configured_flutter_origin()
    {
        using var factory = new EmergencySystemApiFactory();
        await factory.InitializeAsync();
        using var client = CreateClient(factory);

        using var allowedRequest = CreatePreflight("http://localhost:5000");
        var allowedResponse = await client.SendAsync(allowedRequest);
        Assert.Equal(
            "http://localhost:5000",
            allowedResponse.Headers.GetValues("Access-Control-Allow-Origin").Single());

        using var deniedRequest = CreatePreflight("https://untrusted.example");
        var deniedResponse = await client.SendAsync(deniedRequest);
        Assert.False(deniedResponse.Headers.Contains("Access-Control-Allow-Origin"));
    }

    private static HttpClient CreateClient(EmergencySystemApiFactory factory) =>
        factory.CreateClient(
            new Microsoft.AspNetCore.Mvc.Testing.WebApplicationFactoryClientOptions
            {
                BaseAddress = new Uri("https://localhost"),
                AllowAutoRedirect = false,
            });

    private static async Task<LoginResponse> LoginAsync(
        HttpClient client,
        string email)
    {
        var response = await client.PostAsJsonAsync(
            "/api/v1/auth/login",
            new LoginRequest
            {
                Email = email,
                Password = EmergencySystemApiFactory.Password,
            });
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var login = await response.Content.ReadFromJsonAsync<LoginResponse>(JsonOptions);
        Assert.NotNull(login);
        Assert.False(string.IsNullOrWhiteSpace(login.AccessToken));
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", login.AccessToken);
        return login;
    }

    private static async Task<HttpResponseMessage> PutProfileAsync(
        HttpClient client,
        UpdateEmergencyProfileRequest update,
        string etag)
    {
        using var request = new HttpRequestMessage(
            HttpMethod.Put,
            "/api/v1/patients/me/emergency-profile")
        {
            Content = JsonContent.Create(update, options: JsonOptions),
        };
        request.Headers.TryAddWithoutValidation("If-Match", etag);
        return await client.SendAsync(request);
    }

    private static UpdateEmergencyProfileRequest ValidUpdate(string fullName) =>
        new()
        {
            FullName = fullName,
            DateOfBirth = new DateOnly(1997, 4, 12),
            BloodGroup = BloodGroup.OPositive,
            Allergies =
            [
                new AllergyInput
                {
                    Name = "Penicillin",
                    Reaction = "Anaphylaxis",
                    Severity = AllergySeverity.Severe,
                },
            ],
            MedicalConditions =
            [
                new MedicalConditionInput
                {
                    Name = "Asthma",
                    Notes = "Carries an inhaler",
                },
            ],
            Medications =
            [
                new MedicationInput
                {
                    Name = "Salbutamol",
                    Dosage = "100 mcg",
                    Frequency = "As needed",
                },
            ],
            EmergencyContacts =
            [
                new EmergencyContactInput
                {
                    Name = "Test Contact",
                    Relationship = "Sibling",
                    PhoneNumber = "+252612345678",
                    IsPrimary = true,
                },
            ],
        };

    private static HttpRequestMessage CreatePreflight(string origin)
    {
        var request = new HttpRequestMessage(HttpMethod.Options, "/health");
        request.Headers.TryAddWithoutValidation("Origin", origin);
        request.Headers.TryAddWithoutValidation(
            "Access-Control-Request-Method",
            "GET");
        return request;
    }

    private static JsonSerializerOptions CreateJsonOptions()
    {
        var options = new JsonSerializerOptions(JsonSerializerDefaults.Web);
        options.Converters.Add(new JsonStringEnumConverter(allowIntegerValues: false));
        return options;
    }
}
