namespace EmergencySystem.Application.Clinical;

public interface IClinicalRecordService
{
    Task<IReadOnlyList<ClinicalEncounterResponse>?> GetForDoctorAsync(
        Guid doctorUserId,
        Guid grantId,
        CancellationToken cancellationToken = default);

    Task<ClinicalEncounterResponse?> CreateAsync(
        Guid doctorUserId,
        Guid grantId,
        CreateClinicalEncounterRequest request,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<ClinicalEncounterResponse>?> GetForPatientAsync(
        Guid patientUserId,
        CancellationToken cancellationToken = default);
}
