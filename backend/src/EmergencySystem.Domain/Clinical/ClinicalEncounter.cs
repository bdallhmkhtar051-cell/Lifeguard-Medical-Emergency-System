using EmergencySystem.Domain.Access;
using EmergencySystem.Domain.Patients;

namespace EmergencySystem.Domain.Clinical;

/// <summary>
/// A clinical note created by a doctor while an emergency-access grant is active.
/// The grant link preserves why the doctor was allowed to create the record.
/// </summary>
public sealed class ClinicalEncounter
{
    public Guid Id { get; set; }
    public Guid PatientProfileId { get; set; }
    public PatientProfile PatientProfile { get; set; } = null!;
    public Guid DoctorUserId { get; set; }
    public Guid EmergencyAccessGrantId { get; set; }
    public EmergencyAccessGrant EmergencyAccessGrant { get; set; } = null!;
    public string ChiefComplaint { get; set; } = string.Empty;
    public string ClinicalNotes { get; set; } = string.Empty;
    public string? Disposition { get; set; }
    public DateTimeOffset OccurredAtUtc { get; set; }
    public DateTimeOffset CreatedAtUtc { get; set; }
    public ClinicalObservation? Observation { get; set; }
    public ICollection<Prescription> Prescriptions { get; set; } = [];
}
