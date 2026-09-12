using EmergencySystem.Domain.Patients;

namespace EmergencySystem.Application.Profiles;

public sealed record UpdateEmergencyProfileRequest
{
    public string? FullName { get; init; }

    public DateOnly? DateOfBirth { get; init; }

    public BloodGroup? BloodGroup { get; init; }

    public string? PrimaryPhysicianName { get; init; }

    public string? PrimaryPhysicianPhone { get; init; }

    public string? InsuranceProvider { get; init; }

    public string? InsurancePolicyNumber { get; init; }

    public OrganDonorStatus OrganDonorStatus { get; init; } = OrganDonorStatus.Unknown;

    public string? FirstResponderNotes { get; init; }

    public IReadOnlyList<AllergyInput>? Allergies { get; init; }

    public IReadOnlyList<MedicalConditionInput>? MedicalConditions { get; init; }

    public IReadOnlyList<MedicationInput>? Medications { get; init; }

    public IReadOnlyList<EmergencyContactInput>? EmergencyContacts { get; init; }
}

public sealed class AllergyInput
{
    public string? Name { get; init; }

    public string? Reaction { get; init; }

    public AllergySeverity? Severity { get; init; }
}

public sealed class MedicalConditionInput
{
    public string? Name { get; init; }

    public string? Notes { get; init; }
}

public sealed class MedicationInput
{
    public string? Name { get; init; }

    public string? Dosage { get; init; }

    public string? Frequency { get; init; }
}

public sealed class EmergencyContactInput
{
    public string? Name { get; init; }

    public string? Relationship { get; init; }

    public string? PhoneNumber { get; init; }

    public bool IsPrimary { get; init; }
}

public sealed record AllergyResponse(
    Guid Id,
    string Name,
    string? Reaction,
    AllergySeverity Severity);

public sealed record MedicalConditionResponse(
    Guid Id,
    string Name,
    string? Notes);

public sealed record MedicationResponse(
    Guid Id,
    string Name,
    string? Dosage,
    string? Frequency);

public sealed record EmergencyContactResponse(
    Guid Id,
    string Name,
    string Relationship,
    string PhoneNumber,
    bool IsPrimary);

public sealed record EmergencyProfileResponse(
    Guid Id,
    string FullName,
    DateOnly DateOfBirth,
    BloodGroup BloodGroup,
    string? PrimaryPhysicianName,
    string? PrimaryPhysicianPhone,
    string? InsuranceProvider,
    string? InsurancePolicyNumber,
    OrganDonorStatus OrganDonorStatus,
    string? FirstResponderNotes,
    IReadOnlyList<AllergyResponse> Allergies,
    IReadOnlyList<MedicalConditionResponse> MedicalConditions,
    IReadOnlyList<MedicationResponse> Medications,
    IReadOnlyList<EmergencyContactResponse> EmergencyContacts,
    DateTimeOffset UpdatedAtUtc);

public sealed record EmergencyProfileDocument(
    EmergencyProfileResponse Profile,
    Guid Version);

public sealed record EmergencyProfileWriteResult(
    EmergencyProfileDocument Document,
    bool Created);

public readonly record struct ProfileWritePrecondition(
    bool CreateOnly,
    Guid? ExpectedVersion)
{
    public static ProfileWritePrecondition Create() => new(true, null);

    public static ProfileWritePrecondition Update(Guid expectedVersion) =>
        new(false, expectedVersion);
}
