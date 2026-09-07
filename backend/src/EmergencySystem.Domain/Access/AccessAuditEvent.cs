namespace EmergencySystem.Domain.Access;

public sealed class AccessAuditEvent
{
    public Guid Id { get; set; }
    public Guid EmergencyAccessGrantId { get; set; }
    public EmergencyAccessGrant EmergencyAccessGrant { get; set; } = null!;
    public Guid ActorUserId { get; set; }
    public AccessAuditAction Action { get; set; }
    public DateTimeOffset OccurredAtUtc { get; set; }
}
