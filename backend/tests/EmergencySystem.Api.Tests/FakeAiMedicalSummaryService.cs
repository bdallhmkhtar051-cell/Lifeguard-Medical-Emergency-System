using EmergencySystem.Application.Access;
using EmergencySystem.Application.Ai;
using EmergencySystem.Application.Clinical;

namespace EmergencySystem.Api.Tests;

internal sealed class FakeAiMedicalSummaryService : IAiMedicalSummaryService
{
    public Task<AiMedicalSummaryResponse> GenerateAsync(
        DoctorEmergencySnapshotResponse snapshot,
        IReadOnlyList<ClinicalEncounterResponse> clinicalHistory,
        CancellationToken cancellationToken = default) =>
        Task.FromResult(new AiMedicalSummaryResponse(
            $"Verified summary for {snapshot.Profile.FullName}.",
            new DateTimeOffset(2026, 9, 8, 10, 0, 0, TimeSpan.Zero),
            "test-model",
            "AI-generated summary. Verify every detail in the medical record. Not a diagnosis or treatment recommendation."));
}
