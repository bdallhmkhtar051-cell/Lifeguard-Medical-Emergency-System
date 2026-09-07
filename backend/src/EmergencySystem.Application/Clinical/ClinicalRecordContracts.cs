namespace EmergencySystem.Application.Clinical;

public sealed record CreateClinicalEncounterRequest(
    string? ChiefComplaint,
    string? ClinicalNotes,
    string? Disposition,
    DateTimeOffset? OccurredAtUtc,
    ClinicalObservationInput? Observation,
    IReadOnlyList<PrescriptionInput>? Prescriptions);

public sealed record ClinicalObservationInput(
    decimal? TemperatureCelsius,
    int? HeartRateBpm,
    int? SystolicBloodPressure,
    int? DiastolicBloodPressure,
    int? OxygenSaturationPercent,
    int? RespiratoryRatePerMinute);

public sealed record PrescriptionInput(
    string? MedicationName,
    string? Dosage,
    string? Frequency,
    string? Duration,
    string? Instructions);

public sealed record ClinicalEncounterResponse(
    Guid Id,
    Guid PatientProfileId,
    string PatientName,
    Guid DoctorUserId,
    string DoctorName,
    Guid EmergencyAccessGrantId,
    string ChiefComplaint,
    string ClinicalNotes,
    string? Disposition,
    DateTimeOffset OccurredAtUtc,
    DateTimeOffset CreatedAtUtc,
    ClinicalObservationResponse? Observation,
    IReadOnlyList<PrescriptionResponse> Prescriptions);

public sealed record ClinicalObservationResponse(
    Guid Id,
    decimal? TemperatureCelsius,
    int? HeartRateBpm,
    int? SystolicBloodPressure,
    int? DiastolicBloodPressure,
    int? OxygenSaturationPercent,
    int? RespiratoryRatePerMinute);

public sealed record PrescriptionResponse(
    Guid Id,
    string MedicationName,
    string Dosage,
    string Frequency,
    string Duration,
    string? Instructions);
