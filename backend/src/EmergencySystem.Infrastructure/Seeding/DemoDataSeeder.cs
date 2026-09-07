using EmergencySystem.Domain.Identity;
using EmergencySystem.Domain.Patients;
using EmergencySystem.Infrastructure.Configuration;
using EmergencySystem.Infrastructure.Identity;
using EmergencySystem.Infrastructure.Persistence;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Options;

namespace EmergencySystem.Infrastructure.Seeding;

internal sealed class DemoDataSeeder(
    RoleManager<IdentityRole<Guid>> roleManager,
    UserManager<ApplicationUser> userManager,
    ApplicationDbContext dbContext,
    IOptions<DemoSeedOptions> options,
    IHostEnvironment environment,
    TimeProvider timeProvider)
    : IDemoDataSeeder
{
    private readonly DemoSeedOptions _options = options.Value;

    public async Task SeedAsync(CancellationToken cancellationToken = default)
    {
        if (!_options.Enabled)
        {
            return;
        }

        if (!environment.IsDevelopment() && !environment.IsEnvironment("Testing"))
        {
            throw new InvalidOperationException(
                "Synthetic demo accounts may only be seeded in Development or Testing.");
        }

        ValidateConfiguration();

        foreach (var roleName in RoleNames.All)
        {
            if (!await roleManager.RoleExistsAsync(roleName))
            {
                var result = await roleManager.CreateAsync(
                    new IdentityRole<Guid>(roleName));
                EnsureSucceeded(result, $"create the {roleName} role");
            }
        }

        var patient = await EnsureUserAsync(
            _options.Patient,
            RoleNames.Patient,
            cancellationToken);
        await EnsureUserAsync(
            _options.Doctor,
            RoleNames.Doctor,
            cancellationToken);
        await EnsureUserAsync(
            _options.Administrator,
            RoleNames.Administrator,
            cancellationToken);

        if (!await dbContext.PatientProfiles.AnyAsync(
                profile => profile.UserId == patient.Id,
                cancellationToken))
        {
            var now = timeProvider.GetUtcNow();
            dbContext.PatientProfiles.Add(new PatientProfile
            {
                Id = Guid.NewGuid(),
                UserId = patient.Id,
                FullName = _options.Patient.DisplayName.Trim(),
                DateOfBirth = new DateOnly(1997, 4, 12),
                BloodGroup = BloodGroup.OPositive,
                UpdatedAtUtc = now,
                Version = Guid.NewGuid(),
                Allergies =
                [
                    new Allergy
                    {
                        Id = Guid.NewGuid(),
                        Name = "Penicillin",
                        Reaction = "Synthetic demo allergy",
                        Severity = AllergySeverity.Severe,
                    },
                ],
                MedicalConditions =
                [
                    new MedicalCondition
                    {
                        Id = Guid.NewGuid(),
                        Name = "Asthma",
                        Notes = "Synthetic demo condition",
                    },
                ],
                Medications =
                [
                    new Medication
                    {
                        Id = Guid.NewGuid(),
                        Name = "Salbutamol inhaler",
                        Dosage = "100 mcg",
                        Frequency = "As needed",
                    },
                ],
                EmergencyContacts =
                [
                    new EmergencyContact
                    {
                        Id = Guid.NewGuid(),
                        Name = "Hodan Hassan",
                        Relationship = "Sibling",
                        PhoneNumber = "+252612345678",
                        IsPrimary = true,
                    },
                ],
            });

            await dbContext.SaveChangesAsync(cancellationToken);
        }
    }

    private async Task<ApplicationUser> EnsureUserAsync(
        DemoUserOptions account,
        string role,
        CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();

        var user = await userManager.FindByEmailAsync(account.Email.Trim());
        if (user is null)
        {
            user = new ApplicationUser
            {
                Id = Guid.NewGuid(),
                UserName = account.Email.Trim(),
                Email = account.Email.Trim(),
                EmailConfirmed = true,
                DisplayName = account.DisplayName.Trim(),
                IsActive = true,
                CreatedAtUtc = timeProvider.GetUtcNow(),
            };

            var createResult = await userManager.CreateAsync(user, account.Password);
            EnsureSucceeded(createResult, $"create synthetic {role} user");
        }

        if (!await userManager.IsInRoleAsync(user, role))
        {
            var roleResult = await userManager.AddToRoleAsync(user, role);
            EnsureSucceeded(roleResult, $"assign the {role} role");
        }

        return user;
    }

    private void ValidateConfiguration()
    {
        ValidateAccount(_options.Patient, nameof(_options.Patient));
        ValidateAccount(_options.Doctor, nameof(_options.Doctor));
        ValidateAccount(_options.Administrator, nameof(_options.Administrator));
    }

    private static void ValidateAccount(DemoUserOptions account, string name)
    {
        if (string.IsNullOrWhiteSpace(account.Email) ||
            string.IsNullOrWhiteSpace(account.DisplayName) ||
            string.IsNullOrWhiteSpace(account.Password))
        {
            throw new InvalidOperationException(
                $"DemoSeed:{name} requires Email, DisplayName, and a Password supplied through user-secrets or environment variables.");
        }
    }

    private static void EnsureSucceeded(IdentityResult result, string operation)
    {
        if (result.Succeeded)
        {
            return;
        }

        var errors = string.Join(
            "; ",
            result.Errors.Select(error => $"{error.Code}: {error.Description}"));
        throw new InvalidOperationException(
            $"Unable to {operation}. {errors}");
    }
}
