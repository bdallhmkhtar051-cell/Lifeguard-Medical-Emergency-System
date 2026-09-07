namespace EmergencySystem.Domain.Patients;

public sealed class Medication
{
    public Guid Id { get; set; }

    public Guid PatientProfileId { get; set; }

    public PatientProfile PatientProfile { get; set; } = null!;

    public string Name { get; set; } = string.Empty;

    public string? Dosage { get; set; }

    public string? Frequency { get; set; }
}
