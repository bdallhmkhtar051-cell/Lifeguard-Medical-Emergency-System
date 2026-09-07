namespace EmergencySystem.Application.Access;

public interface IEmergencyAccessService
{
    Task<PatientAccessDashboardResponse?> GetPatientDashboardAsync(
        Guid patientUserId,
        CancellationToken cancellationToken = default);

    Task<EmergencyAccessGrantResponse?> GrantAsync(
        Guid patientUserId,
        GrantEmergencyAccessRequest request,
        CancellationToken cancellationToken = default);

    Task<bool> RevokeAsync(
        Guid patientUserId,
        Guid grantId,
        CancellationToken cancellationToken = default);

    Task<MedicalQrIssueResponse?> IssueMedicalQrAsync(
        Guid patientUserId,
        CancellationToken cancellationToken = default);

    Task<bool> RevokeMedicalQrAsync(
        Guid patientUserId,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<DoctorAccessResponse>> GetDoctorAccessAsync(
        Guid doctorUserId,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<DoctorPatientDirectoryResponse>> GetDoctorDirectoryAsync(
        CancellationToken cancellationToken = default);

    Task<DoctorAccessResponse?> BreakGlassAsync(
        Guid doctorUserId,
        BreakGlassAccessRequest request,
        CancellationToken cancellationToken = default);

    Task<DoctorAccessResponse?> RedeemMedicalQrAsync(
        Guid doctorUserId,
        RedeemMedicalQrRequest request,
        CancellationToken cancellationToken = default);

    Task<DoctorEmergencySnapshotResponse?> GetDoctorSnapshotAsync(
        Guid doctorUserId,
        Guid grantId,
        CancellationToken cancellationToken = default);
}
