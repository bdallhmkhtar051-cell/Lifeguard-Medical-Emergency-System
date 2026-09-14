using EmergencySystem.Domain.Access;
using EmergencySystem.Domain.Clinical;
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
    private const string ExtendedHistoryMarker =
        "Synthetic LifeGuard longitudinal-history demonstration.";
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
        var doctor = await EnsureUserAsync(
            _options.Doctor,
            RoleNames.Doctor,
            cancellationToken);
        await EnsureUserAsync(
            _options.Administrator,
            RoleNames.Administrator,
            cancellationToken);

        var profile = await dbContext.PatientProfiles.SingleOrDefaultAsync(
            item => item.UserId == patient.Id,
            cancellationToken);
        if (profile is null)
        {
            var now = timeProvider.GetUtcNow();
            profile = new PatientProfile
            {
                Id = Guid.NewGuid(),
                UserId = patient.Id,
                FullName = _options.Patient.DisplayName.Trim(),
                DateOfBirth = new DateOnly(1997, 4, 12),
                BloodGroup = BloodGroup.OPositive,
                PrimaryPhysicianName = "Dr. Fadumo Abdi",
                PrimaryPhysicianPhone = "+252612345670",
                InsuranceProvider = "LifeGuard Demo Health",
                InsurancePolicyNumber = "DEMO-2026-001",
                OrganDonorStatus = OrganDonorStatus.Unknown,
                FirstResponderNotes =
                    "Synthetic demonstration note: keep the patient's rescue inhaler nearby.",
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
            };
            dbContext.PatientProfiles.Add(profile);

            await dbContext.SaveChangesAsync(cancellationToken);
        }

        await EnsureLongitudinalDemoRecordAsync(
            profile,
            doctor.Id,
            cancellationToken);
    }

    private async Task EnsureLongitudinalDemoRecordAsync(
        PatientProfile profile,
        Guid doctorUserId,
        CancellationToken cancellationToken)
    {
        // The fixed synthetic encounter makes this a one-time enrichment. It
        // does not overwrite later profile edits or duplicate on API restart.
        var baselineDate = new DateTimeOffset(
            2021, 3, 18, 9, 30, 0, TimeSpan.Zero);
        if (await dbContext.ClinicalEncounters.AnyAsync(
                item => item.PatientProfileId == profile.Id &&
                        item.OccurredAtUtc == baselineDate &&
                        item.ChiefComplaint == "Routine asthma follow-up",
                cancellationToken))
        {
            // Clean the internal marker written by an early local build so it
            // never appears repeatedly in the presentation timeline.
            var markedNotes = await dbContext.ClinicalEncounters
                .Where(item => item.PatientProfileId == profile.Id &&
                               item.ClinicalNotes.Contains(ExtendedHistoryMarker))
                .ToListAsync(cancellationToken);
            foreach (var encounter in markedNotes)
            {
                encounter.ClinicalNotes = encounter.ClinicalNotes
                    .Replace($" {ExtendedHistoryMarker}", string.Empty)
                    .Replace(ExtendedHistoryMarker, string.Empty)
                    .Trim();
            }
            if (markedNotes.Count > 0)
            {
                await dbContext.SaveChangesAsync(cancellationToken);
            }
            return;
        }

        AddExtendedOverview(profile.Id);

        var history = new[]
        {
            DemoEncounter(
                new DateTimeOffset(2021, 3, 18, 9, 30, 0, TimeSpan.Zero),
                "Routine asthma follow-up",
                "Stable interval symptoms. Inhaler technique and trigger avoidance reviewed.",
                "Routine follow-up advised in six months.",
                observation: new DemoObservation(36.7m, 76, 112, 72, 98, 16),
                prescriptions:
                [
                    new DemoPrescription(
                        "Budesonide inhaler", "200 mcg", "Twice daily", "90 days",
                        "Rinse mouth after use."),
                ]),
            DemoEncounter(
                new DateTimeOffset(2022, 4, 9, 11, 15, 0, TimeSpan.Zero),
                "Seasonal nasal congestion and sneezing",
                "Symptoms were consistent with the existing synthetic allergic-rhinitis history; no breathing distress documented.",
                "Discharged with routine follow-up advice.",
                observation: new DemoObservation(36.6m, 80, 116, 74, 99, 16),
                prescriptions:
                [
                    new DemoPrescription(
                        "Cetirizine", "10 mg", "Once daily as needed", "14 days",
                        "May cause drowsiness."),
                ]),
            DemoEncounter(
                new DateTimeOffset(2023, 1, 27, 16, 40, 0, TimeSpan.Zero),
                "Cough with mild wheezing",
                "Viral respiratory symptoms with mild asthma flare. Symptoms improved after use of the prescribed rescue inhaler.",
                "Home care with return precautions.",
                observation: new DemoObservation(37.4m, 92, 118, 76, 96, 20)),
            DemoEncounter(
                new DateTimeOffset(2024, 6, 14, 10, 5, 0, TimeSpan.Zero),
                "Intermittent heartburn",
                "Diet-associated reflux symptoms without documented alarm features. Lifestyle measures were discussed.",
                "Primary-care review if symptoms persist.",
                observation: new DemoObservation(36.5m, 74, 110, 70, 99, 15),
                prescriptions:
                [
                    new DemoPrescription(
                        "Omeprazole", "20 mg", "Once daily", "28 days",
                        "Take before breakfast."),
                ]),
            DemoEncounter(
                new DateTimeOffset(2025, 2, 3, 19, 20, 0, TimeSpan.Zero),
                "Shortness of breath after dust exposure",
                "Moderate synthetic asthma exacerbation after dust exposure. Oxygen saturation improved during observation.",
                "Discharged stable with an asthma review appointment.",
                observation: new DemoObservation(37.0m, 104, 124, 78, 94, 24)),
            DemoEncounter(
                new DateTimeOffset(2026, 2, 11, 8, 50, 0, TimeSpan.Zero),
                "Annual chronic-condition review",
                "Asthma control, allergies, medication adherence, emergency contacts, and action-plan awareness reviewed.",
                "Continue current documented medicines and routine monitoring.",
                observation: new DemoObservation(36.4m, 72, 114, 71, 99, 15)),
            DemoEncounter(
                new DateTimeOffset(2026, 8, 22, 14, 10, 0, TimeSpan.Zero),
                "Wheezing during exercise",
                "Mild exercise-associated wheeze. No chest pain, cyanosis, or loss of consciousness documented in this synthetic encounter.",
                "Stable for discharge; follow up with primary physician.",
                observation: new DemoObservation(36.8m, 88, 120, 76, 97, 18)),
        };

        foreach (var item in history)
        {
            AddEncounter(profile.Id, doctorUserId, item);
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private void AddExtendedOverview(Guid profileId)
    {
        dbContext.Allergies.AddRange(
            new Allergy
            {
                Id = Guid.NewGuid(), PatientProfileId = profileId,
                Name = "Ibuprofen", Reaction = "Wheezing (synthetic demo)",
                Severity = AllergySeverity.Moderate,
            },
            new Allergy
            {
                Id = Guid.NewGuid(), PatientProfileId = profileId,
                Name = "Latex", Reaction = "Contact rash (synthetic demo)",
                Severity = AllergySeverity.Mild,
            });
        dbContext.MedicalConditions.AddRange(
            new MedicalCondition
            {
                Id = Guid.NewGuid(), PatientProfileId = profileId,
                Name = "Allergic rhinitis",
                Notes = "Seasonal symptoms; synthetic thesis record.",
            },
            new MedicalCondition
            {
                Id = Guid.NewGuid(), PatientProfileId = profileId,
                Name = "Gastroesophageal reflux",
                Notes = "Intermittent symptoms; synthetic thesis record.",
            });
        dbContext.Medications.AddRange(
            new Medication
            {
                Id = Guid.NewGuid(), PatientProfileId = profileId,
                Name = "Budesonide inhaler", Dosage = "200 mcg",
                Frequency = "Twice daily",
            },
            new Medication
            {
                Id = Guid.NewGuid(), PatientProfileId = profileId,
                Name = "Cetirizine", Dosage = "10 mg",
                Frequency = "Once daily as needed",
            });
        dbContext.EmergencyContacts.Add(new EmergencyContact
        {
            Id = Guid.NewGuid(), PatientProfileId = profileId,
            Name = "Maryan Hassan", Relationship = "Mother",
            PhoneNumber = "+252612345679", IsPrimary = false,
        });
    }

    private void AddEncounter(
        Guid profileId,
        Guid doctorUserId,
        DemoEncounterData data)
    {
        var grantId = Guid.NewGuid();
        var encounterId = Guid.NewGuid();
        var grantedAt = data.OccurredAtUtc.AddHours(-1);
        var grant = new EmergencyAccessGrant
        {
            Id = grantId,
            PatientProfileId = profileId,
            DoctorUserId = doctorUserId,
            AccessType = EmergencyAccessType.Consented,
            GrantedAtUtc = grantedAt,
            ExpiresAtUtc = data.OccurredAtUtc.AddHours(8),
            AuditEvents =
            [
                new AccessAuditEvent
                {
                    Id = Guid.NewGuid(), ActorUserId = doctorUserId,
                    Action = AccessAuditAction.Granted, OccurredAtUtc = grantedAt,
                },
                new AccessAuditEvent
                {
                    Id = Guid.NewGuid(), ActorUserId = doctorUserId,
                    Action = AccessAuditAction.ClinicalRecordCreated,
                    OccurredAtUtc = data.OccurredAtUtc,
                },
            ],
        };
        var encounter = new ClinicalEncounter
        {
            Id = encounterId,
            PatientProfileId = profileId,
            DoctorUserId = doctorUserId,
            EmergencyAccessGrantId = grantId,
            ChiefComplaint = data.ChiefComplaint,
            ClinicalNotes = data.ClinicalNotes,
            Disposition = data.Disposition,
            OccurredAtUtc = data.OccurredAtUtc,
            CreatedAtUtc = data.OccurredAtUtc,
        };
        if (data.Observation is { } observation)
        {
            encounter.Observation = new ClinicalObservation
            {
                Id = Guid.NewGuid(),
                TemperatureCelsius = observation.TemperatureCelsius,
                HeartRateBpm = observation.HeartRateBpm,
                SystolicBloodPressure = observation.SystolicBloodPressure,
                DiastolicBloodPressure = observation.DiastolicBloodPressure,
                OxygenSaturationPercent = observation.OxygenSaturationPercent,
                RespiratoryRatePerMinute = observation.RespiratoryRatePerMinute,
            };
        }
        foreach (var prescription in data.Prescriptions)
        {
            encounter.Prescriptions.Add(new Prescription
            {
                Id = Guid.NewGuid(), MedicationName = prescription.MedicationName,
                Dosage = prescription.Dosage, Frequency = prescription.Frequency,
                Duration = prescription.Duration,
                Instructions = prescription.Instructions,
            });
        }
        dbContext.EmergencyAccessGrants.Add(grant);
        dbContext.ClinicalEncounters.Add(encounter);
    }

    private static DemoEncounterData DemoEncounter(
        DateTimeOffset occurredAtUtc,
        string chiefComplaint,
        string clinicalNotes,
        string disposition,
        DemoObservation? observation = null,
        IReadOnlyList<DemoPrescription>? prescriptions = null) => new(
            occurredAtUtc, chiefComplaint, clinicalNotes, disposition,
            observation, prescriptions ?? []);

    private sealed record DemoEncounterData(
        DateTimeOffset OccurredAtUtc,
        string ChiefComplaint,
        string ClinicalNotes,
        string Disposition,
        DemoObservation? Observation,
        IReadOnlyList<DemoPrescription> Prescriptions);

    private sealed record DemoObservation(
        decimal TemperatureCelsius,
        int HeartRateBpm,
        int SystolicBloodPressure,
        int DiastolicBloodPressure,
        int OxygenSaturationPercent,
        int RespiratoryRatePerMinute);

    private sealed record DemoPrescription(
        string MedicationName,
        string Dosage,
        string Frequency,
        string Duration,
        string Instructions);

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
