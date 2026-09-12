namespace EmergencySystem.Domain.Patients;

/// <summary>
/// Patient-reported donor information for emergency context. This value does
/// not replace verification against an official donor registry.
/// </summary>
public enum OrganDonorStatus
{
    Unknown,
    Donor,
    NotDonor,
}
