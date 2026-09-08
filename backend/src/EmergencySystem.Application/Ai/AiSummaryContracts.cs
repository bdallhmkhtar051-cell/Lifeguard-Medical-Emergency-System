using EmergencySystem.Application.Access;
using EmergencySystem.Application.Clinical;

namespace EmergencySystem.Application.Ai;

public sealed record AiMedicalSummaryResponse(
    string Summary,
    DateTimeOffset GeneratedAtUtc,
    string Model,
    string Disclaimer);

public interface IAiMedicalSummaryService
{
    Task<AiMedicalSummaryResponse> GenerateAsync(
        DoctorEmergencySnapshotResponse snapshot,
        IReadOnlyList<ClinicalEncounterResponse> clinicalHistory,
        CancellationToken cancellationToken = default);
}
