namespace EmergencySystem.Domain.Patients;

public sealed class Allergy
{
    public Guid Id { get; set; }

    public Guid PatientProfileId { get; set; }

    public PatientProfile PatientProfile { get; set; } = null!;

    public string Name { get; set; } = string.Empty;

    public string? Reaction { get; set; }

    public AllergySeverity Severity { get; set; }
}
