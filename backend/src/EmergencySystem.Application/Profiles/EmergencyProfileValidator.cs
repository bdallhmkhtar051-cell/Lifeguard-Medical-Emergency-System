using System.Text.RegularExpressions;
using EmergencySystem.Domain.Patients;

namespace EmergencySystem.Application.Profiles;

public static class EmergencyProfileValidator
{
    private const int MaximumClinicalItems = 20;
    private const int MaximumContacts = 5;

    public static IReadOnlyDictionary<string, string[]> Validate(
        UpdateEmergencyProfileRequest request,
        DateOnly today)
    {
        var errors = new Dictionary<string, List<string>>(StringComparer.Ordinal);

        ValidateRequiredText(errors, "fullName", request.FullName, 2, 100);

        if (request.DateOfBirth is null)
        {
            Add(errors, "dateOfBirth", "Date of birth is required.");
        }
        else if (request.DateOfBirth > today)
        {
            Add(errors, "dateOfBirth", "Date of birth cannot be in the future.");
        }
        else if (request.DateOfBirth < today.AddYears(-120))
        {
            Add(errors, "dateOfBirth", "Date of birth must be within the last 120 years.");
        }

        if (request.BloodGroup is null ||
            !Enum.IsDefined(request.BloodGroup.Value))
        {
            Add(errors, "bloodGroup", "A valid blood group is required.");
        }

        ValidateOptionalText(errors, "primaryPhysicianName", request.PrimaryPhysicianName, 100);
        ValidateOptionalPhoneNumber(
            errors,
            "primaryPhysicianPhone",
            request.PrimaryPhysicianPhone);
        ValidateOptionalText(errors, "insuranceProvider", request.InsuranceProvider, 100);
        ValidateOptionalText(
            errors,
            "insurancePolicyNumber",
            request.InsurancePolicyNumber,
            100);
        ValidateOptionalText(errors, "firstResponderNotes", request.FirstResponderNotes, 1000);

        if (!Enum.IsDefined(request.OrganDonorStatus))
        {
            Add(errors, "organDonorStatus", "A valid organ donor status is required.");
        }

        ValidateAllergies(errors, request.Allergies);
        ValidateMedicalConditions(errors, request.MedicalConditions);
        ValidateMedications(errors, request.Medications);
        ValidateContacts(errors, request.EmergencyContacts);

        return errors.ToDictionary(
            item => item.Key,
            item => item.Value.ToArray(),
            StringComparer.Ordinal);
    }

    private static void ValidateAllergies(
        Dictionary<string, List<string>> errors,
        IReadOnlyList<AllergyInput>? allergies)
    {
        if (!ValidateCollection(errors, "allergies", allergies, MaximumClinicalItems))
        {
            return;
        }

        for (var index = 0; index < allergies!.Count; index++)
        {
            var allergy = allergies[index];
            ValidateRequiredText(errors, $"allergies[{index}].name", allergy.Name, 1, 100);
            ValidateOptionalText(errors, $"allergies[{index}].reaction", allergy.Reaction, 500);

            if (allergy.Severity is null || !Enum.IsDefined(allergy.Severity.Value))
            {
                Add(errors, $"allergies[{index}].severity", "A valid severity is required.");
            }
        }
    }

    private static void ValidateMedicalConditions(
        Dictionary<string, List<string>> errors,
        IReadOnlyList<MedicalConditionInput>? conditions)
    {
        if (!ValidateCollection(errors, "medicalConditions", conditions, MaximumClinicalItems))
        {
            return;
        }

        for (var index = 0; index < conditions!.Count; index++)
        {
            var condition = conditions[index];
            ValidateRequiredText(
                errors,
                $"medicalConditions[{index}].name",
                condition.Name,
                1,
                100);
            ValidateOptionalText(
                errors,
                $"medicalConditions[{index}].notes",
                condition.Notes,
                500);
        }
    }

    private static void ValidateMedications(
        Dictionary<string, List<string>> errors,
        IReadOnlyList<MedicationInput>? medications)
    {
        if (!ValidateCollection(errors, "medications", medications, MaximumClinicalItems))
        {
            return;
        }

        for (var index = 0; index < medications!.Count; index++)
        {
            var medication = medications[index];
            ValidateRequiredText(
                errors,
                $"medications[{index}].name",
                medication.Name,
                1,
                100);
            ValidateOptionalText(
                errors,
                $"medications[{index}].dosage",
                medication.Dosage,
                100);
            ValidateOptionalText(
                errors,
                $"medications[{index}].frequency",
                medication.Frequency,
                100);
        }
    }

    private static void ValidateContacts(
        Dictionary<string, List<string>> errors,
        IReadOnlyList<EmergencyContactInput>? contacts)
    {
        if (!ValidateCollection(errors, "emergencyContacts", contacts, MaximumContacts))
        {
            return;
        }

        if (contacts!.Count > 0 && contacts.Count(contact => contact.IsPrimary) != 1)
        {
            Add(
                errors,
                "emergencyContacts",
                "Exactly one emergency contact must be marked as primary.");
        }

        for (var index = 0; index < contacts.Count; index++)
        {
            var contact = contacts[index];
            ValidateRequiredText(
                errors,
                $"emergencyContacts[{index}].name",
                contact.Name,
                1,
                100);
            ValidateRequiredText(
                errors,
                $"emergencyContacts[{index}].relationship",
                contact.Relationship,
                1,
                50);
            ValidatePhoneNumber(
                errors,
                $"emergencyContacts[{index}].phoneNumber",
                contact.PhoneNumber);
        }
    }

    private static bool ValidateCollection<T>(
        Dictionary<string, List<string>> errors,
        string key,
        IReadOnlyList<T>? values,
        int maximum)
    {
        if (values is null)
        {
            Add(errors, key, "This collection is required.");
            return false;
        }

        if (values.Count > maximum)
        {
            Add(errors, key, $"No more than {maximum} items are allowed.");
            return false;
        }

        return true;
    }

    private static void ValidatePhoneNumber(
        Dictionary<string, List<string>> errors,
        string key,
        string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            Add(errors, key, "Phone number is required.");
            return;
        }

        if (!Regex.IsMatch(
                value,
                @"^\+[1-9]\d{6,14}$",
                RegexOptions.CultureInvariant,
                TimeSpan.FromMilliseconds(100)))
        {
            Add(errors, key, "Use international format, for example +252612345678.");
        }
    }

    private static void ValidateOptionalPhoneNumber(
        Dictionary<string, List<string>> errors,
        string key,
        string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return;
        }

        if (!Regex.IsMatch(
                value.Trim(),
                @"^\+[1-9]\d{6,14}$",
                RegexOptions.CultureInvariant,
                TimeSpan.FromMilliseconds(100)))
        {
            Add(errors, key, "Use international format, for example +252612345678.");
        }
    }

    private static void ValidateRequiredText(
        Dictionary<string, List<string>> errors,
        string key,
        string? value,
        int minimumLength,
        int maximumLength)
    {
        var trimmed = value?.Trim();
        if (string.IsNullOrEmpty(trimmed))
        {
            Add(errors, key, "This field is required.");
            return;
        }

        if (trimmed.Length < minimumLength || trimmed.Length > maximumLength)
        {
            Add(
                errors,
                key,
                $"This field must contain between {minimumLength} and {maximumLength} characters.");
        }
    }

    private static void ValidateOptionalText(
        Dictionary<string, List<string>> errors,
        string key,
        string? value,
        int maximumLength)
    {
        if (value?.Trim().Length > maximumLength)
        {
            Add(errors, key, $"This field cannot exceed {maximumLength} characters.");
        }
    }

    private static void Add(
        Dictionary<string, List<string>> errors,
        string key,
        string message)
    {
        if (!errors.TryGetValue(key, out var messages))
        {
            messages = [];
            errors[key] = messages;
        }

        messages.Add(message);
    }
}
