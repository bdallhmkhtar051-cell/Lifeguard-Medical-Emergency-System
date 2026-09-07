using EmergencySystem.Domain.Administration;
using EmergencySystem.Domain.Access;

namespace EmergencySystem.Application.Administration;

public sealed record AdminUserSummary(
    Guid Id,
    string DisplayName,
    string Email,
    IReadOnlyList<string> Roles,
    bool IsActive,
    DateTimeOffset CreatedAtUtc);

public sealed record UpdateUserStatusRequest(bool IsActive);

public enum UpdateUserStatusOutcome
{
    Updated,
    NotFound,
    SelfDeactivationDenied,
}

public sealed record UpdateUserStatusResult(
    UpdateUserStatusOutcome Outcome,
    AdminUserSummary? User = null);

public sealed record AccountAdministrationAuditResponse(
    Guid Id,
    Guid AdministratorUserId,
    string AdministratorName,
    Guid TargetUserId,
    string TargetUserName,
    AccountAdministrationAction Action,
    DateTimeOffset OccurredAtUtc);

public sealed record SystemAccessAuditResponse(
    Guid Id,
    Guid GrantId,
    string ActorName,
    string PatientName,
    AccessAuditAction Action,
    EmergencyAccessType AccessType,
    DateTimeOffset OccurredAtUtc);
