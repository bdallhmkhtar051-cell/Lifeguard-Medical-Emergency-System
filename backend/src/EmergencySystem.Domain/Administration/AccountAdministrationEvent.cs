namespace EmergencySystem.Domain.Administration;

/// <summary>
/// Append-only evidence of an administrator changing an account's status.
/// </summary>
public sealed class AccountAdministrationEvent
{
    public Guid Id { get; set; }
    public Guid AdministratorUserId { get; set; }
    public Guid TargetUserId { get; set; }
    public AccountAdministrationAction Action { get; set; }
    public DateTimeOffset OccurredAtUtc { get; set; }
}
