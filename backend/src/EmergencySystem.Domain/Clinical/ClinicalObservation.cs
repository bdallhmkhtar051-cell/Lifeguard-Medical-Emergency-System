namespace EmergencySystem.Domain.Clinical;

/// <summary>Structured vital signs captured during one encounter.</summary>
public sealed class ClinicalObservation
{
    public Guid Id { get; set; }
    public Guid ClinicalEncounterId { get; set; }
    public ClinicalEncounter ClinicalEncounter { get; set; } = null!;
    public decimal? TemperatureCelsius { get; set; }
    public int? HeartRateBpm { get; set; }
    public int? SystolicBloodPressure { get; set; }
    public int? DiastolicBloodPressure { get; set; }
    public int? OxygenSaturationPercent { get; set; }
    public int? RespiratoryRatePerMinute { get; set; }
}
