using EmergencySystem.Application.Common;
using EmergencySystem.Application.Profiles;
using EmergencySystem.Domain.Patients;
using EmergencySystem.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace EmergencySystem.Infrastructure.Profiles;

internal sealed class EmergencyProfileService(
    ApplicationDbContext dbContext,
    TimeProvider timeProvider)
    : IEmergencyProfileService
{
    public async Task<EmergencyProfileDocument?> GetAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var profile = await ProfileQuery(tracking: false)
            .SingleOrDefaultAsync(
                item => item.UserId == userId,
                cancellationToken);

        return profile is null ? null : EmergencyProfileMapper.Map(profile);
    }

    public async Task<EmergencyProfileWriteResult> PutAsync(
        Guid userId,
        UpdateEmergencyProfileRequest request,
        ProfileWritePrecondition precondition,
        CancellationToken cancellationToken = default)
    {
        var now = timeProvider.GetUtcNow();
        var validationErrors = EmergencyProfileValidator.Validate(
            request,
            DateOnly.FromDateTime(now.UtcDateTime));
        if (validationErrors.Count > 0)
        {
            throw new RequestValidationException(validationErrors);
        }

        await using var transaction = await dbContext.Database.BeginTransactionAsync(
            cancellationToken);
        var profile = await ProfileQuery(tracking: true)
            .SingleOrDefaultAsync(
                item => item.UserId == userId,
                cancellationToken);

        var created = profile is null;
        if (precondition.CreateOnly)
        {
            if (!created)
            {
                throw new ProfilePreconditionFailedException();
            }

            profile = new PatientProfile
            {
                Id = Guid.NewGuid(),
                UserId = userId,
            };
            dbContext.PatientProfiles.Add(profile);
        }
        else if (profile is null ||
                 precondition.ExpectedVersion is null ||
                 profile.Version != precondition.ExpectedVersion)
        {
            throw new ProfilePreconditionFailedException();
        }

        ApplyEditableFields(profile!, request, now);

        try
        {
            await dbContext.SaveChangesAsync(cancellationToken);
            await transaction.CommitAsync(cancellationToken);
        }
        catch (DbUpdateConcurrencyException exception)
        {
            throw new ProfilePreconditionFailedException(exception);
        }

        return new EmergencyProfileWriteResult(EmergencyProfileMapper.Map(profile!), created);
    }

    private IQueryable<PatientProfile> ProfileQuery(bool tracking)
    {
        var query = dbContext.PatientProfiles
            .Include(profile => profile.Allergies)
            .Include(profile => profile.MedicalConditions)
            .Include(profile => profile.Medications)
            .Include(profile => profile.EmergencyContacts)
            .AsSplitQuery();

        return tracking ? query : query.AsNoTracking();
    }

    private void ApplyEditableFields(
        PatientProfile profile,
        UpdateEmergencyProfileRequest request,
        DateTimeOffset now)
    {
        var isExistingProfile =
            dbContext.Entry(profile).State != EntityState.Added;
        if (isExistingProfile)
        {
            dbContext.Allergies.RemoveRange(profile.Allergies);
            dbContext.MedicalConditions.RemoveRange(profile.MedicalConditions);
            dbContext.Medications.RemoveRange(profile.Medications);
            dbContext.EmergencyContacts.RemoveRange(profile.EmergencyContacts);
        }

        profile.FullName = request.FullName!.Trim();
        profile.DateOfBirth = request.DateOfBirth!.Value;
        profile.BloodGroup = request.BloodGroup!.Value;
        profile.UpdatedAtUtc = now;
        profile.Version = Guid.NewGuid();
        profile.Allergies = request.Allergies!
            .Select(item => new Allergy
            {
                Id = Guid.NewGuid(),
                PatientProfileId = profile.Id,
                Name = item.Name!.Trim(),
                Reaction = NormalizeOptional(item.Reaction),
                Severity = item.Severity!.Value,
            })
            .ToList();
        profile.MedicalConditions = request.MedicalConditions!
            .Select(item => new MedicalCondition
            {
                Id = Guid.NewGuid(),
                PatientProfileId = profile.Id,
                Name = item.Name!.Trim(),
                Notes = NormalizeOptional(item.Notes),
            })
            .ToList();
        profile.Medications = request.Medications!
            .Select(item => new Medication
            {
                Id = Guid.NewGuid(),
                PatientProfileId = profile.Id,
                Name = item.Name!.Trim(),
                Dosage = NormalizeOptional(item.Dosage),
                Frequency = NormalizeOptional(item.Frequency),
            })
            .ToList();
        profile.EmergencyContacts = request.EmergencyContacts!
            .Select(item => new EmergencyContact
            {
                Id = Guid.NewGuid(),
                PatientProfileId = profile.Id,
                Name = item.Name!.Trim(),
                Relationship = item.Relationship!.Trim(),
                PhoneNumber = item.PhoneNumber!.Trim(),
                IsPrimary = item.IsPrimary,
            })
            .ToList();

        // EF correctly cascades Added state from a new profile. For an existing
        // aggregate, the replacement children have non-empty GUID keys, so we
        // explicitly mark them Added rather than allowing graph discovery to
        // interpret them as updates to rows that do not exist.
        if (isExistingProfile)
        {
            dbContext.Allergies.AddRange(profile.Allergies);
            dbContext.MedicalConditions.AddRange(profile.MedicalConditions);
            dbContext.Medications.AddRange(profile.Medications);
            dbContext.EmergencyContacts.AddRange(profile.EmergencyContacts);
        }
    }

    private static string? NormalizeOptional(string? value)
    {
        var trimmed = value?.Trim();
        return string.IsNullOrEmpty(trimmed) ? null : trimmed;
    }
}
