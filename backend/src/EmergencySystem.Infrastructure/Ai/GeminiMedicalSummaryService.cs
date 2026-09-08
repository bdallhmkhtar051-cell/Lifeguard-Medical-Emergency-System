using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using EmergencySystem.Application.Access;
using EmergencySystem.Application.Ai;
using EmergencySystem.Application.Clinical;
using EmergencySystem.Application.Common;
using EmergencySystem.Infrastructure.Configuration;
using Microsoft.Extensions.Options;

namespace EmergencySystem.Infrastructure.Ai;

internal sealed class GeminiMedicalSummaryService(
    HttpClient httpClient,
    IOptions<GeminiOptions> options,
    TimeProvider timeProvider) : IAiMedicalSummaryService
{
    public const string Disclaimer =
        "AI-generated summary. Verify every detail in the medical record. Not a diagnosis or treatment recommendation.";

    private readonly GeminiOptions _options = options.Value;

    public async Task<AiMedicalSummaryResponse> GenerateAsync(
        DoctorEmergencySnapshotResponse snapshot,
        IReadOnlyList<ClinicalEncounterResponse> clinicalHistory,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(_options.ApiKey))
            throw new AiServiceUnavailableException(
                "The AI summary service has not been configured.");

        using var request = new HttpRequestMessage(
            HttpMethod.Post,
            $"v1beta/models/{Uri.EscapeDataString(_options.Model)}:generateContent");
        request.Headers.Add("x-goog-api-key", _options.ApiKey);
        request.Content = JsonContent.Create(new
        {
            systemInstruction = new
            {
                parts = new[] { new { text = SystemInstruction } },
            },
            contents = new[]
            {
                new
                {
                    role = "user",
                    parts = new[] { new { text = BuildRecord(snapshot, clinicalHistory) } },
                },
            },
            generationConfig = new
            {
                maxOutputTokens = 1200,
                responseMimeType = "text/plain",
                thinkingConfig = new { thinkingLevel = "low" },
            },
        });

        try
        {
            using var response = await httpClient.SendAsync(request, cancellationToken);
            if (!response.IsSuccessStatusCode)
                throw new AiServiceUnavailableException(
                    "The AI provider could not generate a summary. Try again later.");

            using var document = await JsonDocument.ParseAsync(
                await response.Content.ReadAsStreamAsync(cancellationToken),
                cancellationToken: cancellationToken);
            var text = ExtractAnswer(document.RootElement);
            if (string.IsNullOrWhiteSpace(text))
                throw new AiServiceUnavailableException(
                    "The AI provider returned an empty summary.");

            return new(CleanFormatting(text), timeProvider.GetUtcNow(), _options.Model, Disclaimer);
        }
        catch (AiServiceUnavailableException) { throw; }
        catch (Exception exception) when (
            exception is HttpRequestException or TaskCanceledException or JsonException)
        {
            throw new AiServiceUnavailableException(
                "The AI summary service is temporarily unavailable.");
        }
    }

    private const string SystemInstruction =
        "Create a clear emergency medical handover for a clinician using only the " +
        "verified record supplied by the application. Do not infer missing facts, " +
        "diagnose, recommend treatment, or change any value. Use plain text only: " +
        "no Markdown, asterisks, hash signs, tables, or decorative characters. " +
        "Use these headings in this exact order: PATIENT OVERVIEW, CRITICAL ALERTS, " +
        "CURRENT CONDITIONS, CURRENT MEDICATIONS, EMERGENCY CONTACT, RECENT CLINICAL " +
        "HISTORY. Under each heading, write short complete sentences that are easy " +
        "to understand during an emergency. Avoid repetition. Say 'Not recorded' " +
        "when a section has no supplied information. Keep the response under 350 words.";

    private static string? ExtractAnswer(JsonElement root)
    {
        var parts = root.GetProperty("candidates")[0]
            .GetProperty("content")
            .GetProperty("parts");
        var answer = new StringBuilder();
        foreach (var part in parts.EnumerateArray())
        {
            if (part.TryGetProperty("thought", out var thought) &&
                thought.ValueKind == JsonValueKind.True)
                continue;
            if (part.TryGetProperty("text", out var text) &&
                !string.IsNullOrWhiteSpace(text.GetString()))
                answer.AppendLine(text.GetString());
        }
        return answer.ToString().Trim();
    }

    private static string CleanFormatting(string text) => text
        .Replace("**", string.Empty, StringComparison.Ordinal)
        .Replace("*", string.Empty, StringComparison.Ordinal)
        .Replace("`", string.Empty, StringComparison.Ordinal)
        .Replace("###", string.Empty, StringComparison.Ordinal)
        .Trim();

    private static string BuildRecord(
        DoctorEmergencySnapshotResponse snapshot,
        IReadOnlyList<ClinicalEncounterResponse> history)
    {
        var profile = snapshot.Profile;
        var text = new StringBuilder()
            .AppendLine($"Patient: {profile.FullName}")
            .AppendLine($"Date of birth: {profile.DateOfBirth:yyyy-MM-dd}")
            .AppendLine($"Blood group: {profile.BloodGroup}")
            .AppendLine("Allergies: " + string.Join("; ", profile.Allergies.Select(
                item => $"{item.Name} ({item.Severity}, {item.Reaction})")))
            .AppendLine("Conditions: " + string.Join("; ", profile.MedicalConditions.Select(
                item => $"{item.Name} ({item.Notes})")))
            .AppendLine("Medications: " + string.Join("; ", profile.Medications.Select(
                item => $"{item.Name}, {item.Dosage}, {item.Frequency}")))
            .AppendLine("Emergency contacts: " + string.Join("; ", profile.EmergencyContacts.Select(
                item => $"{item.Name}, {item.Relationship}, {item.PhoneNumber}")));

        foreach (var encounter in history.Take(5))
            text.AppendLine(
                $"Encounter {encounter.OccurredAtUtc:yyyy-MM-dd}: " +
                $"{encounter.ChiefComplaint}; {encounter.ClinicalNotes}; {encounter.Disposition}");
        return text.ToString();
    }
}
