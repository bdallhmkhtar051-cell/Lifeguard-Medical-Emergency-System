namespace EmergencySystem.Domain.Patients;

public sealed class EmergencyContact
{
    public Guid Id { get; set; }

    public Guid PatientProfileId { get; set; }

    public PatientProfile PatientProfile { get; set; } = null!;

    public string Name { get; set; } = string.Empty;

    public string Relationship { get; set; } = string.Empty;

    public string PhoneNumber { get; set; } = string.Empty;

    public bool IsPrimary { get; set; }
}
