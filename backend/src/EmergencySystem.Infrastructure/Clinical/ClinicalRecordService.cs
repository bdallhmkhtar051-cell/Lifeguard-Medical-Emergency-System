using EmergencySystem.Application.Clinical;
using EmergencySystem.Application.Common;
using EmergencySystem.Domain.Access;
using EmergencySystem.Domain.Clinical;
using EmergencySystem.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace EmergencySystem.Infrastructure.Clinical;

internal sealed class ClinicalRecordService(
    ApplicationDbContext dbContext,
    TimeProvider timeProvider) : IClinicalRecordService
{
    public async Task<IReadOnlyList<ClinicalEncounterResponse>?> GetForDoctorAsync(
        Guid doctorUserId,
        Guid grantId,
        CancellationToken cancellationToken = default)
    {
        var grant = await ActiveGrantAsync(doctorUserId, grantId, cancellationToken);
        if (grant is null) return null;
        return await HistoryAsync(grant.PatientProfileId, cancellationToken);
    }

    public async Task<ClinicalEncounterResponse?> CreateAsync(
        Guid doctorUserId,
        Guid grantId,
        CreateClinicalEncounterRequest request,
        CancellationToken cancellationToken = default)
    {
        var now = timeProvider.GetUtcNow();
        var errors = ClinicalRecordValidator.Validate(request, now);
        if (errors.Count > 0) throw new RequestValidationException(errors);

        var grant = await ActiveGrantAsync(doctorUserId, grantId, cancellationToken);
        if (grant is null) return null;

        var encounter = new ClinicalEncounter
        {
            Id = Guid.NewGuid(),
            PatientProfileId = grant.PatientProfileId,
            DoctorUserId = doctorUserId,
            EmergencyAccessGrantId = grant.Id,
            ChiefComplaint = request.ChiefComplaint!.Trim(),
            ClinicalNotes = request.ClinicalNotes!.Trim(),
            Disposition = Clean(request.Disposition),
            OccurredAtUtc = request.OccurredAtUtc ?? now,
            CreatedAtUtc = now,
        };

        if (request.Observation is { } observation && HasValues(observation))
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

        foreach (var item in request.Prescriptions!)
        {
            encounter.Prescriptions.Add(new Prescription
            {
                Id = Guid.NewGuid(),
                MedicationName = item.MedicationName!.Trim(),
                Dosage = item.Dosage!.Trim(),
                Frequency = item.Frequency!.Trim(),
                Duration = item.Duration!.Trim(),
                Instructions = Clean(item.Instructions),
            });
        }

        dbContext.ClinicalEncounters.Add(encounter);
        dbContext.AccessAuditEvents.Add(new AccessAuditEvent
        {
            Id = Guid.NewGuid(),
            EmergencyAccessGrantId = grant.Id,
            ActorUserId = doctorUserId,
            Action = AccessAuditAction.ClinicalRecordCreated,
            OccurredAtUtc = now,
        });
        await dbContext.SaveChangesAsync(cancellationToken);

        var doctorName = await dbContext.Users
            .Where(item => item.Id == doctorUserId)
            .Select(item => item.DisplayName)
            .SingleAsync(cancellationToken);
        return Map(encounter, grant.PatientProfile.FullName, doctorName);
    }

    public async Task<IReadOnlyList<ClinicalEncounterResponse>?> GetForPatientAsync(
        Guid patientUserId,
        CancellationToken cancellationToken = default)
    {
        var profileId = await dbContext.PatientProfiles.AsNoTracking()
            .Where(item => item.UserId == patientUserId)
            .Select(item => (Guid?)item.Id)
            .SingleOrDefaultAsync(cancellationToken);
        return profileId is null
            ? null
            : await HistoryAsync(profileId.Value, cancellationToken);
    }

    private async Task<EmergencyAccessGrant?> ActiveGrantAsync(
        Guid doctorUserId,
        Guid grantId,
        CancellationToken cancellationToken)
    {
        var grant = await dbContext.EmergencyAccessGrants
            .Include(item => item.PatientProfile)
            .SingleOrDefaultAsync(
                item => item.Id == grantId &&
                        item.DoctorUserId == doctorUserId &&
                        item.RevokedAtUtc == null,
                cancellationToken);
        return grant is not null && grant.ExpiresAtUtc > timeProvider.GetUtcNow()
            ? grant
            : null;
    }

    private async Task<IReadOnlyList<ClinicalEncounterResponse>> HistoryAsync(
        Guid profileId,
        CancellationToken cancellationToken)
    {
        // Sort DateTimeOffset values after materialization so the same code
        // works with SQL Server and the SQLite integration-test database.
        var encounters = await dbContext.ClinicalEncounters.AsNoTracking()
            .Where(item => item.PatientProfileId == profileId)
            .Include(item => item.PatientProfile)
            .Include(item => item.Observation)
            .Include(item => item.Prescriptions)
            .AsSplitQuery()
            .ToListAsync(cancellationToken);
        encounters = encounters
            .OrderByDescending(item => item.OccurredAtUtc)
            .Take(100)
            .ToList();
        var doctorIds = encounters.Select(item => item.DoctorUserId).Distinct().ToArray();
        var names = await dbContext.Users.AsNoTracking()
            .Where(item => doctorIds.Contains(item.Id))
            .ToDictionaryAsync(item => item.Id, item => item.DisplayName, cancellationToken);
        return encounters.Select(item => Map(
            item,
            item.PatientProfile.FullName,
            names.GetValueOrDefault(item.DoctorUserId, "Unknown doctor"))).ToArray();
    }

    private static ClinicalEncounterResponse Map(
        ClinicalEncounter item,
        string patientName,
        string doctorName) => new(
            item.Id,
            item.PatientProfileId,
            patientName,
            item.DoctorUserId,
            doctorName,
            item.EmergencyAccessGrantId,
            item.ChiefComplaint,
            item.ClinicalNotes,
            item.Disposition,
            item.OccurredAtUtc,
            item.CreatedAtUtc,
            item.Observation is null ? null : new ClinicalObservationResponse(
                item.Observation.Id,
                item.Observation.TemperatureCelsius,
                item.Observation.HeartRateBpm,
                item.Observation.SystolicBloodPressure,
                item.Observation.DiastolicBloodPressure,
                item.Observation.OxygenSaturationPercent,
                item.Observation.RespiratoryRatePerMinute),
            item.Prescriptions.Select(prescription => new PrescriptionResponse(
                prescription.Id,
                prescription.MedicationName,
                prescription.Dosage,
                prescription.Frequency,
                prescription.Duration,
                prescription.Instructions)).ToArray());

    private static bool HasValues(ClinicalObservationInput value) =>
        value.TemperatureCelsius is not null || value.HeartRateBpm is not null ||
        value.SystolicBloodPressure is not null || value.DiastolicBloodPressure is not null ||
        value.OxygenSaturationPercent is not null || value.RespiratoryRatePerMinute is not null;

    private static string? Clean(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();
}
