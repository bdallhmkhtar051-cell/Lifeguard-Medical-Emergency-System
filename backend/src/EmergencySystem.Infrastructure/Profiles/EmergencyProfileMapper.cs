using EmergencySystem.Application.Profiles;
using EmergencySystem.Domain.Patients;

namespace EmergencySystem.Infrastructure.Profiles;

internal static class EmergencyProfileMapper
{
    public static EmergencyProfileDocument Map(PatientProfile profile) =>
        new(
            new EmergencyProfileResponse(
                profile.Id,
                profile.FullName,
                profile.DateOfBirth,
                profile.BloodGroup,
                profile.PrimaryPhysicianName,
                profile.PrimaryPhysicianPhone,
                profile.InsuranceProvider,
                profile.InsurancePolicyNumber,
                profile.OrganDonorStatus,
                profile.FirstResponderNotes,
                profile.Allergies.OrderBy(item => item.Name).ThenBy(item => item.Id)
                    .Select(item => new AllergyResponse(item.Id, item.Name, item.Reaction, item.Severity)).ToArray(),
                profile.MedicalConditions.OrderBy(item => item.Name).ThenBy(item => item.Id)
                    .Select(item => new MedicalConditionResponse(item.Id, item.Name, item.Notes)).ToArray(),
                profile.Medications.OrderBy(item => item.Name).ThenBy(item => item.Id)
                    .Select(item => new MedicationResponse(item.Id, item.Name, item.Dosage, item.Frequency)).ToArray(),
                profile.EmergencyContacts.OrderByDescending(item => item.IsPrimary).ThenBy(item => item.Name).ThenBy(item => item.Id)
                    .Select(item => new EmergencyContactResponse(item.Id, item.Name, item.Relationship, item.PhoneNumber, item.IsPrimary)).ToArray(),
                profile.UpdatedAtUtc),
            profile.Version);
}
