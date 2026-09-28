using EmergencySystem.Application.Profiles;
using EmergencySystem.Domain.Access;

namespace EmergencySystem.Application.Access;

public sealed record GrantEmergencyAccessRequest(string? DoctorEmail, int DurationMinutes);

public sealed record BreakGlassAccessRequest(Guid PatientProfileId, string? Reason);

public sealed record RedeemMedicalQrRequest(string? Token);

public sealed record ResolveEmergencyMedicalIdRequest(string? QrPayload);

public sealed record EmergencyMedicalIdResponse(
    Guid EmergencyMedicalId,
    string QrPayload);

/// <summary>
/// Minimal identity confirmation returned before break-glass authorization.
/// It deliberately contains no clinical or contact information.
/// </summary>
public sealed record EmergencyPatientIdentificationResponse(
    Guid PatientProfileId,
    string PatientName);

public sealed record MedicalQrIssueResponse(
    string Token,
    DateTimeOffset ExpiresAtUtc);

public sealed record DoctorPatientDirectoryResponse(Guid PatientProfileId, string PatientName);

public sealed record DoctorOptionResponse(Guid UserId, string DisplayName, string Email);

public sealed record EmergencyAccessGrantResponse(
    Guid Id,
    Guid DoctorUserId,
    string DoctorName,
    string DoctorEmail,
    EmergencyAccessType AccessType,
    string? EmergencyReason,
    DateTimeOffset GrantedAtUtc,
    DateTimeOffset ExpiresAtUtc,
    DateTimeOffset? RevokedAtUtc,
    bool IsActive);

public sealed record AccessAuditResponse(
    Guid Id,
    Guid GrantId,
    string ActorName,
    AccessAuditAction Action,
    DateTimeOffset OccurredAtUtc);

public sealed record PatientAccessDashboardResponse(
    IReadOnlyList<DoctorOptionResponse> Doctors,
    IReadOnlyList<EmergencyAccessGrantResponse> Grants,
    IReadOnlyList<AccessAuditResponse> AuditHistory);

public sealed record DoctorAccessResponse(
    Guid GrantId,
    Guid PatientProfileId,
    string PatientName,
    EmergencyAccessType AccessType,
    string? EmergencyReason,
    DateTimeOffset ExpiresAtUtc);

public sealed record DoctorEmergencySnapshotResponse(
    Guid GrantId,
    DateTimeOffset ExpiresAtUtc,
    EmergencyAccessType AccessType,
    string? EmergencyReason,
    EmergencyProfileResponse Profile);

/// <summary>
/// Versioned permanent QR contract. This payload identifies a patient only;
/// possession of it is never evidence of consent or authorization.
/// </summary>
public static class PermanentEmergencyQrPayload
{
    public const string Prefix = "LIFEGUARD:EMERGENCY:1:";

    public static string Create(Guid emergencyMedicalId) =>
        $"{Prefix}{emergencyMedicalId:N}";

    public static bool TryParse(string? payload, out Guid emergencyMedicalId)
    {
        emergencyMedicalId = Guid.Empty;
        var value = payload?.Trim();
        if (value is null ||
            !value.StartsWith(Prefix, StringComparison.OrdinalIgnoreCase))
        {
            return false;
        }

        var identifier = value[Prefix.Length..];
        return identifier.Length == 32 &&
               Guid.TryParseExact(identifier, "N", out emergencyMedicalId) &&
               emergencyMedicalId != Guid.Empty;
    }
}
