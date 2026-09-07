using EmergencySystem.Domain.Patients;
using EmergencySystem.Domain.Clinical;

namespace EmergencySystem.Domain.Access;

public sealed class EmergencyAccessGrant
{
    public Guid Id { get; set; }
    public Guid PatientProfileId { get; set; }
    public PatientProfile PatientProfile { get; set; } = null!;
    public Guid DoctorUserId { get; set; }
    public EmergencyAccessType AccessType { get; set; }
    public string? EmergencyReason { get; set; }
    public DateTimeOffset GrantedAtUtc { get; set; }
    public DateTimeOffset ExpiresAtUtc { get; set; }
    public DateTimeOffset? RevokedAtUtc { get; set; }
    public ICollection<AccessAuditEvent> AuditEvents { get; set; } = [];
    public ICollection<ClinicalEncounter> ClinicalEncounters { get; set; } = [];
}
