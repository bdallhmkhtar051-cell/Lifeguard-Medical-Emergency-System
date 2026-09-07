using EmergencySystem.Domain.Access;
using EmergencySystem.Domain.Clinical;

namespace EmergencySystem.Domain.Patients;

public sealed class PatientProfile
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    public string FullName { get; set; } = string.Empty;

    public DateOnly DateOfBirth { get; set; }

    public BloodGroup BloodGroup { get; set; }

    public DateTimeOffset UpdatedAtUtc { get; set; }

    /// <summary>
    /// Application-managed optimistic concurrency token. It is regenerated for
    /// every update and exposed to clients only as an HTTP ETag.
    /// </summary>
    public Guid Version { get; set; }

    public ICollection<Allergy> Allergies { get; set; } = [];

    public ICollection<MedicalCondition> MedicalConditions { get; set; } = [];

    public ICollection<Medication> Medications { get; set; } = [];

    public ICollection<EmergencyContact> EmergencyContacts { get; set; } = [];

    public ICollection<EmergencyAccessGrant> AccessGrants { get; set; } = [];

    public ICollection<ClinicalEncounter> ClinicalEncounters { get; set; } = [];
}
