namespace EmergencySystem.Application.Administration;

public interface IAdministrationService
{
    Task<IReadOnlyList<AdminUserSummary>> GetUsersAsync(
        CancellationToken cancellationToken = default);

    Task<UpdateUserStatusResult> UpdateUserStatusAsync(
        Guid administratorUserId,
        Guid targetUserId,
        bool isActive,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<AccountAdministrationAuditResponse>> GetAccountAuditAsync(
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<SystemAccessAuditResponse>> GetAccessAuditAsync(
        CancellationToken cancellationToken = default);
}
