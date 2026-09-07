using EmergencySystem.Application.Administration;
using EmergencySystem.Domain.Administration;
using EmergencySystem.Infrastructure.Identity;
using EmergencySystem.Infrastructure.Persistence;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace EmergencySystem.Infrastructure.Administration;

internal sealed class AdministrationService(
    UserManager<ApplicationUser> userManager,
    ApplicationDbContext dbContext,
    TimeProvider timeProvider)
    : IAdministrationService
{
    public async Task<IReadOnlyList<AdminUserSummary>> GetUsersAsync(
        CancellationToken cancellationToken = default)
    {
        var users = await userManager.Users
            .AsNoTracking()
            .OrderBy(user => user.DisplayName)
            .ToListAsync(cancellationToken);

        var summaries = new List<AdminUserSummary>(users.Count);
        foreach (var user in users)
        {
            cancellationToken.ThrowIfCancellationRequested();
            summaries.Add(await MapUserAsync(user));
        }

        return summaries;
    }

    public async Task<UpdateUserStatusResult> UpdateUserStatusAsync(
        Guid administratorUserId,
        Guid targetUserId,
        bool isActive,
        CancellationToken cancellationToken = default)
    {
        cancellationToken.ThrowIfCancellationRequested();
        var user = await userManager.FindByIdAsync(targetUserId.ToString());
        if (user is null)
        {
            return new(UpdateUserStatusOutcome.NotFound);
        }

        // An administrator must never accidentally lock themselves out.
        if (administratorUserId == targetUserId && !isActive)
        {
            return new(UpdateUserStatusOutcome.SelfDeactivationDenied);
        }

        if (user.IsActive == isActive)
        {
            return new(UpdateUserStatusOutcome.Updated, await MapUserAsync(user));
        }

        user.IsActive = isActive;
        IdentityResult updateResult;
        if (!isActive)
        {
            // Rotating the stamp invalidates an already-issued JWT on its next API call.
            updateResult = await userManager.UpdateSecurityStampAsync(user);
        }
        else
        {
            updateResult = await userManager.UpdateAsync(user);
        }
        EnsureSucceeded(updateResult);

        dbContext.AccountAdministrationEvents.Add(new AccountAdministrationEvent
        {
            Id = Guid.NewGuid(),
            AdministratorUserId = administratorUserId,
            TargetUserId = targetUserId,
            Action = isActive
                ? AccountAdministrationAction.Activated
                : AccountAdministrationAction.Deactivated,
            OccurredAtUtc = timeProvider.GetUtcNow(),
        });
        await dbContext.SaveChangesAsync(cancellationToken);

        return new(UpdateUserStatusOutcome.Updated, await MapUserAsync(user));
    }

    public async Task<IReadOnlyList<AccountAdministrationAuditResponse>> GetAccountAuditAsync(
        CancellationToken cancellationToken = default)
    {
        var events = await (
            from audit in dbContext.AccountAdministrationEvents.AsNoTracking()
            join administrator in dbContext.Users.AsNoTracking()
                on audit.AdministratorUserId equals administrator.Id
            join target in dbContext.Users.AsNoTracking()
                on audit.TargetUserId equals target.Id
            select new AccountAdministrationAuditResponse(
                audit.Id,
                administrator.Id,
                administrator.DisplayName,
                target.Id,
                target.DisplayName,
                audit.Action,
                audit.OccurredAtUtc))
        .ToListAsync(cancellationToken);

        // Sort after materialization so this also works with the SQLite test
        // provider, which cannot order DateTimeOffset values directly.
        return events
            .OrderByDescending(item => item.OccurredAtUtc)
            .Take(100)
            .ToArray();
    }

    public async Task<IReadOnlyList<SystemAccessAuditResponse>> GetAccessAuditAsync(
        CancellationToken cancellationToken = default)
    {
        // This deliberately exposes audit metadata, not diagnoses, notes, or medication data.
        var events = await (
            from audit in dbContext.AccessAuditEvents.AsNoTracking()
            join grant in dbContext.EmergencyAccessGrants.AsNoTracking()
                on audit.EmergencyAccessGrantId equals grant.Id
            join patient in dbContext.PatientProfiles.AsNoTracking()
                on grant.PatientProfileId equals patient.Id
            join actor in dbContext.Users.AsNoTracking()
                on audit.ActorUserId equals actor.Id
            select new SystemAccessAuditResponse(
                audit.Id,
                grant.Id,
                actor.DisplayName,
                patient.FullName,
                audit.Action,
                grant.AccessType,
                audit.OccurredAtUtc))
        .ToListAsync(cancellationToken);

        return events
            .OrderByDescending(item => item.OccurredAtUtc)
            .Take(100)
            .ToArray();
    }

    private async Task<AdminUserSummary> MapUserAsync(ApplicationUser user)
    {
        var roles = (await userManager.GetRolesAsync(user))
            .Order(StringComparer.Ordinal)
            .ToArray();
        return new(
            user.Id,
            user.DisplayName,
            user.Email ?? string.Empty,
            roles,
            user.IsActive,
            user.CreatedAtUtc);
    }

    private static void EnsureSucceeded(IdentityResult result)
    {
        if (result.Succeeded) return;
        var errors = string.Join(
            "; ",
            result.Errors.Select(error => $"{error.Code}: {error.Description}"));
        throw new InvalidOperationException($"Unable to update the account. {errors}");
    }
}
