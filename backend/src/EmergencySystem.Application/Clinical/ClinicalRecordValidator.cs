namespace EmergencySystem.Application.Clinical;

public static class ClinicalRecordValidator
{
    private const int MaximumPrescriptions = 10;

    public static IReadOnlyDictionary<string, string[]> Validate(
        CreateClinicalEncounterRequest request,
        DateTimeOffset now)
    {
        var errors = new Dictionary<string, List<string>>(StringComparer.Ordinal);
        Required(errors, "chiefComplaint", request.ChiefComplaint, 3, 200);
        Required(errors, "clinicalNotes", request.ClinicalNotes, 3, 2000);
        Optional(errors, "disposition", request.Disposition, 200);

        if (request.OccurredAtUtc is { } occurred)
        {
            if (occurred > now.AddMinutes(5))
                Add(errors, "occurredAtUtc", "Encounter time cannot be in the future.");
            if (occurred < now.AddYears(-1))
                Add(errors, "occurredAtUtc", "Encounter time must be within the last year.");
        }

        ValidateObservation(errors, request.Observation);
        ValidatePrescriptions(errors, request.Prescriptions);
        return errors.ToDictionary(item => item.Key, item => item.Value.ToArray());
    }

    private static void ValidateObservation(
        Dictionary<string, List<string>> errors,
        ClinicalObservationInput? value)
    {
        if (value is null) return;
        Range(errors, "observation.temperatureCelsius", value.TemperatureCelsius, 25, 45);
        Range(errors, "observation.heartRateBpm", value.HeartRateBpm, 20, 250);
        Range(errors, "observation.systolicBloodPressure", value.SystolicBloodPressure, 40, 300);
        Range(errors, "observation.diastolicBloodPressure", value.DiastolicBloodPressure, 20, 200);
        Range(errors, "observation.oxygenSaturationPercent", value.OxygenSaturationPercent, 50, 100);
        Range(errors, "observation.respiratoryRatePerMinute", value.RespiratoryRatePerMinute, 4, 80);
        if (value.SystolicBloodPressure is { } systolic &&
            value.DiastolicBloodPressure is { } diastolic &&
            systolic <= diastolic)
            Add(errors, "observation.systolicBloodPressure", "Systolic pressure must be higher than diastolic pressure.");
    }

    private static void ValidatePrescriptions(
        Dictionary<string, List<string>> errors,
        IReadOnlyList<PrescriptionInput>? values)
    {
        if (values is null)
        {
            Add(errors, "prescriptions", "This collection is required.");
            return;
        }
        if (values.Count > MaximumPrescriptions)
        {
            Add(errors, "prescriptions", $"No more than {MaximumPrescriptions} prescriptions are allowed.");
            return;
        }
        for (var index = 0; index < values.Count; index++)
        {
            var item = values[index];
            Required(errors, $"prescriptions[{index}].medicationName", item.MedicationName, 1, 100);
            Required(errors, $"prescriptions[{index}].dosage", item.Dosage, 1, 100);
            Required(errors, $"prescriptions[{index}].frequency", item.Frequency, 1, 100);
            Required(errors, $"prescriptions[{index}].duration", item.Duration, 1, 100);
            Optional(errors, $"prescriptions[{index}].instructions", item.Instructions, 500);
        }
    }

    private static void Range<T>(
        Dictionary<string, List<string>> errors,
        string key,
        T? value,
        T minimum,
        T maximum) where T : struct, IComparable<T>
    {
        if (value is { } number &&
            (number.CompareTo(minimum) < 0 || number.CompareTo(maximum) > 0))
            Add(errors, key, $"Value must be between {minimum} and {maximum}.");
    }

    private static void Required(
        Dictionary<string, List<string>> errors,
        string key,
        string? value,
        int minimum,
        int maximum)
    {
        var text = value?.Trim();
        if (string.IsNullOrEmpty(text)) Add(errors, key, "This field is required.");
        else if (text.Length < minimum || text.Length > maximum)
            Add(errors, key, $"This field must contain between {minimum} and {maximum} characters.");
    }

    private static void Optional(
        Dictionary<string, List<string>> errors,
        string key,
        string? value,
        int maximum)
    {
        if (value?.Trim().Length > maximum)
            Add(errors, key, $"This field cannot exceed {maximum} characters.");
    }

    private static void Add(
        Dictionary<string, List<string>> errors,
        string key,
        string message)
    {
        if (!errors.TryGetValue(key, out var messages)) errors[key] = messages = [];
        messages.Add(message);
    }
}
