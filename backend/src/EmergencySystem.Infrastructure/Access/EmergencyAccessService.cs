using EmergencySystem.Application.Access;
using EmergencySystem.Application.Common;
using EmergencySystem.Domain.Access;
using EmergencySystem.Domain.Identity;
using EmergencySystem.Infrastructure.Identity;
using EmergencySystem.Infrastructure.Persistence;
using EmergencySystem.Infrastructure.Profiles;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace EmergencySystem.Infrastructure.Access;

internal sealed class EmergencyAccessService(
    ApplicationDbContext dbContext,
    UserManager<ApplicationUser> userManager,
    TimeProvider timeProvider) : IEmergencyAccessService
{
    private const int BreakGlassDurationMinutes = 15;

    public async Task<PatientAccessDashboardResponse?> GetPatientDashboardAsync(
        Guid patientUserId,
        CancellationToken cancellationToken = default)
    {
        var profileId = await dbContext.PatientProfiles
            .Where(item => item.UserId == patientUserId)
            .Select(item => (Guid?)item.Id)
            .SingleOrDefaultAsync(cancellationToken);
        if (profileId is null) return null;

        var grants = await dbContext.EmergencyAccessGrants.AsNoTracking()
            .Where(item => item.PatientProfileId == profileId)
            .ToListAsync(cancellationToken);
        var audits = await dbContext.AccessAuditEvents.AsNoTracking()
            .Where(item => item.EmergencyAccessGrant.PatientProfileId == profileId)
            .ToListAsync(cancellationToken);
        grants = grants.OrderByDescending(item => item.GrantedAtUtc).ToList();
        audits = audits.OrderByDescending(item => item.OccurredAtUtc).Take(100).ToList();
        var doctors = (await userManager.GetUsersInRoleAsync(RoleNames.Doctor))
            .Where(item => item.IsActive && !string.IsNullOrWhiteSpace(item.Email))
            .OrderBy(item => item.DisplayName)
            .ToArray();
        var doctorsById = doctors.ToDictionary(item => item.Id);
        var users = await UserNamesAsync(
            grants.Select(item => item.DoctorUserId)
                .Concat(audits.Select(item => item.ActorUserId)),
            cancellationToken);
        var now = timeProvider.GetUtcNow();

        return new PatientAccessDashboardResponse(
            doctors.Select(item => new DoctorOptionResponse(
                item.Id, item.DisplayName, item.Email!)).ToArray(),
            grants.Select(item => MapGrant(
                item,
                users.GetValueOrDefault(item.DoctorUserId, "Unknown doctor"),
                doctorsById.GetValueOrDefault(item.DoctorUserId)?.Email ?? string.Empty,
                now)).ToArray(),
            audits.Select(item => new AccessAuditResponse(
                item.Id,
                item.EmergencyAccessGrantId,
                users.GetValueOrDefault(item.ActorUserId, "Unknown user"),
                item.Action,
                item.OccurredAtUtc)).ToArray());
    }

    public async Task<EmergencyAccessGrantResponse?> GrantAsync(
        Guid patientUserId,
        GrantEmergencyAccessRequest request,
        CancellationToken cancellationToken = default)
    {
        var email = request.DoctorEmail?.Trim();
        var errors = new Dictionary<string, string[]>();
        if (string.IsNullOrWhiteSpace(email))
            errors["doctorEmail"] = ["Select a doctor."];
        if (request.DurationMinutes is < 15 or > 1440)
            errors["durationMinutes"] = ["Duration must be between 15 minutes and 24 hours."];
        if (errors.Count > 0) throw new RequestValidationException(errors);

        var doctor = await userManager.FindByEmailAsync(email!);
        if (doctor is null || !doctor.IsActive ||
            !await userManager.IsInRoleAsync(doctor, RoleNames.Doctor))
            throw new RequestValidationException(
                new Dictionary<string, string[]> { ["doctorEmail"] = ["Select an active doctor."] });

        var profileId = await dbContext.PatientProfiles
            .Where(item => item.UserId == patientUserId)
            .Select(item => (Guid?)item.Id)
            .SingleOrDefaultAsync(cancellationToken);
        if (profileId is null) return null;

        var now = timeProvider.GetUtcNow();
        var existingGrants = await dbContext.EmergencyAccessGrants.AsNoTracking()
            .Where(
            item => item.PatientProfileId == profileId &&
                    item.DoctorUserId == doctor.Id &&
                    item.RevokedAtUtc == null)
            .ToListAsync(cancellationToken);
        var alreadyActive = existingGrants.Any(item => item.ExpiresAtUtc > now);
        if (alreadyActive)
            throw new RequestValidationException(
                new Dictionary<string, string[]> { ["doctorEmail"] = ["This doctor already has active access."] });

        var grant = new EmergencyAccessGrant
        {
            Id = Guid.NewGuid(),
            PatientProfileId = profileId.Value,
            DoctorUserId = doctor.Id,
            AccessType = EmergencyAccessType.Consented,
            GrantedAtUtc = now,
            ExpiresAtUtc = now.AddMinutes(request.DurationMinutes),
        };
        grant.AuditEvents.Add(NewAudit(grant.Id, patientUserId, AccessAuditAction.Granted, now));
        dbContext.EmergencyAccessGrants.Add(grant);
        await dbContext.SaveChangesAsync(cancellationToken);
        return MapGrant(grant, doctor.DisplayName, doctor.Email!, now);
    }

    public async Task<bool> RevokeAsync(
        Guid patientUserId,
        Guid grantId,
        CancellationToken cancellationToken = default)
    {
        var grant = await dbContext.EmergencyAccessGrants
            .Include(item => item.PatientProfile)
            .SingleOrDefaultAsync(item => item.Id == grantId, cancellationToken);
        if (grant is null || grant.PatientProfile.UserId != patientUserId) return false;

        var now = timeProvider.GetUtcNow();
        if (grant.RevokedAtUtc is null && grant.ExpiresAtUtc > now)
        {
            grant.RevokedAtUtc = now;
            dbContext.AccessAuditEvents.Add(
                NewAudit(grant.Id, patientUserId, AccessAuditAction.Revoked, now));
            await dbContext.SaveChangesAsync(cancellationToken);
        }
        return true;
    }

    public async Task<IReadOnlyList<DoctorAccessResponse>> GetDoctorAccessAsync(
        Guid doctorUserId,
        CancellationToken cancellationToken = default)
    {
        var now = timeProvider.GetUtcNow();
        var grants = await dbContext.EmergencyAccessGrants.AsNoTracking()
            .Where(item => item.DoctorUserId == doctorUserId &&
                           item.RevokedAtUtc == null)
            .Include(item => item.PatientProfile)
            .ToListAsync(cancellationToken);
        return grants.Where(item => item.ExpiresAtUtc > now)
            .OrderBy(item => item.ExpiresAtUtc)
            .Select(item => new DoctorAccessResponse(
                item.Id,
                item.PatientProfileId,
                item.PatientProfile.FullName,
                item.AccessType,
                item.EmergencyReason,
                item.ExpiresAtUtc))
            .ToArray();
    }

    public async Task<IReadOnlyList<DoctorPatientDirectoryResponse>> GetDoctorDirectoryAsync(
        CancellationToken cancellationToken = default) =>
        await dbContext.PatientProfiles.AsNoTracking()
            .OrderBy(item => item.FullName)
            .Select(item => new DoctorPatientDirectoryResponse(item.Id, item.FullName))
            .ToArrayAsync(cancellationToken);

    public async Task<DoctorAccessResponse?> BreakGlassAsync(
        Guid doctorUserId,
        BreakGlassAccessRequest request,
        CancellationToken cancellationToken = default)
    {
        var reason = request.Reason?.Trim();
        var errors = new Dictionary<string, string[]>();
        if (request.PatientProfileId == Guid.Empty)
            errors["patientProfileId"] = ["Select a patient."];
        if (string.IsNullOrWhiteSpace(reason) || reason.Length < 20)
            errors["reason"] = ["Enter a specific emergency reason of at least 20 characters."];
        else if (reason.Length > 500)
            errors["reason"] = ["The emergency reason cannot exceed 500 characters."];
        if (errors.Count > 0) throw new RequestValidationException(errors);

        var patient = await dbContext.PatientProfiles
            .SingleOrDefaultAsync(
                item => item.Id == request.PatientProfileId,
                cancellationToken);
        if (patient is null) return null;

        var now = timeProvider.GetUtcNow();
        // Load the small candidate set before comparing DateTimeOffset. This
        // remains portable across SQL Server and the SQLite integration tests.
        var candidateGrants = await dbContext.EmergencyAccessGrants.AsNoTracking()
            .Where(
                item => item.PatientProfileId == patient.Id &&
                        item.DoctorUserId == doctorUserId &&
                        item.RevokedAtUtc == null)
            .ToListAsync(cancellationToken);
        var alreadyActive = candidateGrants.Any(item => item.ExpiresAtUtc > now);
        if (alreadyActive)
            throw new RequestValidationException(
                new Dictionary<string, string[]>
                {
                    ["patientProfileId"] = ["You already have active access to this patient."],
                });

        var grant = new EmergencyAccessGrant
        {
            Id = Guid.NewGuid(),
            PatientProfileId = patient.Id,
            DoctorUserId = doctorUserId,
            AccessType = EmergencyAccessType.BreakGlass,
            EmergencyReason = reason,
            GrantedAtUtc = now,
            ExpiresAtUtc = now.AddMinutes(BreakGlassDurationMinutes),
        };
        grant.AuditEvents.Add(
            NewAudit(
                grant.Id,
                doctorUserId,
                AccessAuditAction.BreakGlassActivated,
                now));
        dbContext.EmergencyAccessGrants.Add(grant);
        await dbContext.SaveChangesAsync(cancellationToken);

        return new DoctorAccessResponse(
            grant.Id,
            patient.Id,
            patient.FullName,
            grant.AccessType,
            grant.EmergencyReason,
            grant.ExpiresAtUtc);
    }

    public async Task<DoctorEmergencySnapshotResponse?> GetDoctorSnapshotAsync(
        Guid doctorUserId,
        Guid grantId,
        CancellationToken cancellationToken = default)
    {
        var now = timeProvider.GetUtcNow();
        var grant = await dbContext.EmergencyAccessGrants
            .Include(item => item.PatientProfile).ThenInclude(item => item.Allergies)
            .Include(item => item.PatientProfile).ThenInclude(item => item.MedicalConditions)
            .Include(item => item.PatientProfile).ThenInclude(item => item.Medications)
            .Include(item => item.PatientProfile).ThenInclude(item => item.EmergencyContacts)
            .AsSplitQuery()
            .SingleOrDefaultAsync(
                item => item.Id == grantId && item.DoctorUserId == doctorUserId &&
                        item.RevokedAtUtc == null,
                cancellationToken);
        if (grant is null || grant.ExpiresAtUtc <= now) return null;

        dbContext.AccessAuditEvents.Add(
            NewAudit(grant.Id, doctorUserId, AccessAuditAction.Viewed, now));
        await dbContext.SaveChangesAsync(cancellationToken);
        return new DoctorEmergencySnapshotResponse(
            grant.Id,
            grant.ExpiresAtUtc,
            grant.AccessType,
            grant.EmergencyReason,
            EmergencyProfileMapper.Map(grant.PatientProfile).Profile);
    }

    private async Task<Dictionary<Guid, string>> UserNamesAsync(
        IEnumerable<Guid> ids,
        CancellationToken cancellationToken) =>
        await dbContext.Users.Where(item => ids.Distinct().Contains(item.Id))
            .ToDictionaryAsync(item => item.Id, item => item.DisplayName, cancellationToken);

    private static EmergencyAccessGrantResponse MapGrant(
        EmergencyAccessGrant grant,
        string doctorName,
        string doctorEmail,
        DateTimeOffset now) => new(
            grant.Id,
            grant.DoctorUserId,
            doctorName,
            doctorEmail,
            grant.AccessType,
            grant.EmergencyReason,
            grant.GrantedAtUtc,
            grant.ExpiresAtUtc,
            grant.RevokedAtUtc,
            grant.RevokedAtUtc is null && grant.ExpiresAtUtc > now);

    private static AccessAuditEvent NewAudit(
        Guid grantId,
        Guid actorId,
        AccessAuditAction action,
        DateTimeOffset now) => new()
        {
            Id = Guid.NewGuid(),
            EmergencyAccessGrantId = grantId,
            ActorUserId = actorId,
            Action = action,
            OccurredAtUtc = now,
        };
}
