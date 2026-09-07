using EmergencySystem.Application.Profiles;
using EmergencySystem.Domain.Patients;

namespace EmergencySystem.Application.Tests;

public sealed class EmergencyProfileValidatorTests
{
    private static readonly DateOnly Today = new(2026, 7, 28);

    [Fact]
    public void Validate_accepts_a_complete_valid_profile()
    {
        var errors = EmergencyProfileValidator.Validate(ValidRequest(), Today);

        Assert.Empty(errors);
    }

    [Fact]
    public void Validate_rejects_future_birth_date_and_multiple_primary_contacts()
    {
        var request = ValidRequest() with
        {
            DateOfBirth = Today.AddDays(1),
            EmergencyContacts =
            [
                ValidContact("+252612345678", true),
                ValidContact("+252612345679", true),
            ],
        };

        var errors = EmergencyProfileValidator.Validate(request, Today);

        Assert.Contains("dateOfBirth", errors.Keys);
        Assert.Contains("emergencyContacts", errors.Keys);
    }

    [Fact]
    public void Validate_rejects_missing_collections_and_non_e164_phone()
    {
        var request = new UpdateEmergencyProfileRequest
        {
            FullName = "Demo Patient",
            DateOfBirth = new DateOnly(1997, 4, 12),
            BloodGroup = BloodGroup.OPositive,
            Allergies = null,
            MedicalConditions = null,
            Medications = null,
            EmergencyContacts =
            [
                ValidContact("0612345678", true),
            ],
        };

        var errors = EmergencyProfileValidator.Validate(request, Today);

        Assert.Contains("allergies", errors.Keys);
        Assert.Contains("medicalConditions", errors.Keys);
        Assert.Contains("medications", errors.Keys);
        Assert.Contains("emergencyContacts[0].phoneNumber", errors.Keys);
    }

    private static UpdateEmergencyProfileRequest ValidRequest() =>
        new()
        {
            FullName = "Amina Hassan",
            DateOfBirth = new DateOnly(1997, 4, 12),
            BloodGroup = BloodGroup.OPositive,
            Allergies =
            [
                new AllergyInput
                {
                    Name = "Penicillin",
                    Reaction = "Anaphylaxis",
                    Severity = AllergySeverity.Severe,
                },
            ],
            MedicalConditions =
            [
                new MedicalConditionInput
                {
                    Name = "Asthma",
                    Notes = "Carries an inhaler",
                },
            ],
            Medications =
            [
                new MedicationInput
                {
                    Name = "Salbutamol",
                    Dosage = "100 mcg",
                    Frequency = "As needed",
                },
            ],
            EmergencyContacts =
            [
                ValidContact("+252612345678", true),
            ],
        };

    private static EmergencyContactInput ValidContact(
        string phoneNumber,
        bool isPrimary) =>
        new()
        {
            Name = "Hodan Hassan",
            Relationship = "Sibling",
            PhoneNumber = phoneNumber,
            IsPrimary = isPrimary,
        };
}
