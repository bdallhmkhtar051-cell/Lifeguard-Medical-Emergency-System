using EmergencySystem.Domain.Identity;
using EmergencySystem.Domain.Patients;
using EmergencySystem.Application.Ai;
using EmergencySystem.Infrastructure.Identity;
using EmergencySystem.Infrastructure.Persistence;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Microsoft.Extensions.Logging;

namespace EmergencySystem.Api.Tests;

internal sealed class EmergencySystemApiFactory : WebApplicationFactory<Program>
{
    public const string PatientEmail = "patient.test@emergency.test";
    public const string DoctorEmail = "doctor.test@emergency.test";
    public const string AdministratorEmail = "admin.test@emergency.test";
    public const string Password = "TestingOnly!123";

    private readonly SqliteConnection _connection = new("Data Source=:memory:");
    private bool _initialized;

    public EmergencySystemApiFactory()
    {
        _connection.Open();
    }

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");
        builder.ConfigureLogging(logging => logging.ClearProviders());
        builder.ConfigureAppConfiguration((_, configuration) =>
        {
            // Test configuration must be deterministic and must not inherit a
            // developer's local user-secrets or machine connection strings.
            configuration.Sources.Clear();
            configuration.AddInMemoryCollection(
                new Dictionary<string, string?>
                {
                    ["ConnectionStrings:DefaultConnection"] = "Server=unused",
                    ["Jwt:Issuer"] = "EmergencySystem.Api.Tests",
                    ["Jwt:Audience"] = "EmergencySystem.Api.Tests.Client",
                    ["Jwt:SigningKey"] =
                        "test-only-signing-key-with-at-least-sixty-four-characters-123456789",
                    ["Jwt:AccessTokenMinutes"] = "15",
                    ["Cors:AllowedOrigins:0"] = "http://localhost:5000",
                    ["DemoSeed:Enabled"] = "false",
                    ["AllowedHosts"] = "*",
                });
        });

        builder.ConfigureServices(services =>
        {
            services.RemoveAll<ApplicationDbContext>();
            services.RemoveAll<DbContextOptions<ApplicationDbContext>>();
            services.RemoveAll<IDbContextOptionsConfiguration<ApplicationDbContext>>();
            services.RemoveAll<IAiMedicalSummaryService>();

            services.AddSingleton(_connection);
            services.AddDataProtection().UseEphemeralDataProtectionProvider();
            services.AddDbContext<ApplicationDbContext>((serviceProvider, options) =>
                options.UseSqlite(
                    serviceProvider.GetRequiredService<SqliteConnection>()));
            services.AddSingleton<IAiMedicalSummaryService, FakeAiMedicalSummaryService>();
        });
    }

    public async Task InitializeAsync()
    {
        if (_initialized)
        {
            return;
        }

        using var scope = Services.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        await dbContext.Database.EnsureCreatedAsync();

        var roleManager = scope.ServiceProvider
            .GetRequiredService<RoleManager<IdentityRole<Guid>>>();
        foreach (var role in RoleNames.All)
        {
            var result = await roleManager.CreateAsync(new IdentityRole<Guid>(role));
            Assert.True(result.Succeeded, IdentityErrors(result));
        }

        var userManager = scope.ServiceProvider
            .GetRequiredService<UserManager<ApplicationUser>>();
        var patient = await CreateUserAsync(
            userManager,
            PatientEmail,
            "Test Patient",
            RoleNames.Patient);
        await CreateUserAsync(
            userManager,
            DoctorEmail,
            "Test Doctor",
            RoleNames.Doctor);
        await CreateUserAsync(
            userManager,
            AdministratorEmail,
            "Test Administrator",
            RoleNames.Administrator);

        dbContext.PatientProfiles.Add(new PatientProfile
        {
            Id = Guid.NewGuid(),
            UserId = patient.Id,
            FullName = "Test Patient",
            DateOfBirth = new DateOnly(1997, 4, 12),
            BloodGroup = BloodGroup.OPositive,
            UpdatedAtUtc = DateTimeOffset.UtcNow,
            Version = Guid.NewGuid(),
            Allergies =
            [
                new Allergy
                {
                    Id = Guid.NewGuid(),
                    Name = "Penicillin",
                    Reaction = "Anaphylaxis",
                    Severity = AllergySeverity.Severe,
                },
            ],
            MedicalConditions =
            [
                new MedicalCondition
                {
                    Id = Guid.NewGuid(),
                    Name = "Asthma",
                    Notes = "Synthetic test record",
                },
            ],
            Medications =
            [
                new Medication
                {
                    Id = Guid.NewGuid(),
                    Name = "Salbutamol",
                    Dosage = "100 mcg",
                    Frequency = "As needed",
                },
            ],
            EmergencyContacts =
            [
                new EmergencyContact
                {
                    Id = Guid.NewGuid(),
                    Name = "Test Contact",
                    Relationship = "Sibling",
                    PhoneNumber = "+252612345678",
                    IsPrimary = true,
                },
            ],
        });
        await dbContext.SaveChangesAsync();

        _initialized = true;
    }

    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
        if (disposing)
        {
            _connection.Dispose();
        }
    }

    private static async Task<ApplicationUser> CreateUserAsync(
        UserManager<ApplicationUser> userManager,
        string email,
        string displayName,
        string role)
    {
        var user = new ApplicationUser
        {
            Id = Guid.NewGuid(),
            UserName = email,
            Email = email,
            EmailConfirmed = true,
            DisplayName = displayName,
            IsActive = true,
            CreatedAtUtc = DateTimeOffset.UtcNow,
        };
        var createResult = await userManager.CreateAsync(user, Password);
        Assert.True(createResult.Succeeded, IdentityErrors(createResult));

        var roleResult = await userManager.AddToRoleAsync(user, role);
        Assert.True(roleResult.Succeeded, IdentityErrors(roleResult));
        return user;
    }

    private static string IdentityErrors(IdentityResult result) =>
        string.Join(
            "; ",
            result.Errors.Select(error => $"{error.Code}: {error.Description}"));
}
