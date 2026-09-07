using EmergencySystem.Application.Profiles;
using EmergencySystem.Domain.Access;

namespace EmergencySystem.Application.Access;

public sealed record GrantEmergencyAccessRequest(string? DoctorEmail, int DurationMinutes);

public sealed record BreakGlassAccessRequest(Guid PatientProfileId, string? Reason);

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
