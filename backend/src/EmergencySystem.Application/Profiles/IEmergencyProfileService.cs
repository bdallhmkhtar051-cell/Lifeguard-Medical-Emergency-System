namespace EmergencySystem.Application.Profiles;

public interface IEmergencyProfileService
{
    Task<EmergencyProfileDocument?> GetAsync(
        Guid userId,
        CancellationToken cancellationToken = default);

    Task<EmergencyProfileWriteResult> PutAsync(
        Guid userId,
        UpdateEmergencyProfileRequest request,
        ProfileWritePrecondition precondition,
        CancellationToken cancellationToken = default);
}
