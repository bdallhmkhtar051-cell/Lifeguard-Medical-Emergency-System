using EmergencySystem.Domain.Patients;

namespace EmergencySystem.Domain.Documents;

public sealed class MedicalDocument
{
    public Guid Id { get; set; }
    public Guid PatientProfileId { get; set; }
    public Guid UploadedByUserId { get; set; }
    public string FileName { get; set; } = string.Empty;
    public string ContentType { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public string? Description { get; set; }
    public long SizeBytes { get; set; }
    public byte[] Content { get; set; } = [];
    public DateTimeOffset UploadedAtUtc { get; set; }
    public DateTimeOffset? DeletedAtUtc { get; set; }
    public PatientProfile PatientProfile { get; set; } = null!;
}
