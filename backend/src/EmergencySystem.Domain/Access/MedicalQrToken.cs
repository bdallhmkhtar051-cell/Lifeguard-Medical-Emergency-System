using EmergencySystem.Domain.Patients;

namespace EmergencySystem.Domain.Access;

/// <summary>
/// A short-lived, one-use patient invitation. Only its SHA-256 hash is stored;
/// the raw value exists only in the QR returned to the patient.
/// </summary>
public sealed class MedicalQrToken
{
    public Guid Id { get; set; }
    public Guid PatientProfileId { get; set; }
    public PatientProfile PatientProfile { get; set; } = null!;
    public string TokenHash { get; set; } = string.Empty;
    public DateTimeOffset CreatedAtUtc { get; set; }
    public DateTimeOffset ExpiresAtUtc { get; set; }
    public DateTimeOffset? RedeemedAtUtc { get; set; }
    public DateTimeOffset? RevokedAtUtc { get; set; }
    public Guid? RedeemedByDoctorUserId { get; set; }
    public Guid? EmergencyAccessGrantId { get; set; }
    public EmergencyAccessGrant? EmergencyAccessGrant { get; set; }
    public Guid Version { get; set; }
}
