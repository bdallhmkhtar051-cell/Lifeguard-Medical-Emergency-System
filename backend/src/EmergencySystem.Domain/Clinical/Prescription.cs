namespace EmergencySystem.Domain.Clinical;

/// <summary>A medication ordered as part of a clinical encounter.</summary>
public sealed class Prescription
{
    public Guid Id { get; set; }
    public Guid ClinicalEncounterId { get; set; }
    public ClinicalEncounter ClinicalEncounter { get; set; } = null!;
    public string MedicationName { get; set; } = string.Empty;
    public string Dosage { get; set; } = string.Empty;
    public string Frequency { get; set; } = string.Empty;
    public string Duration { get; set; } = string.Empty;
    public string? Instructions { get; set; }
}
