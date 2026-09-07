using EmergencySystem.Application.Clinical;

namespace EmergencySystem.Application.Tests;

public sealed class ClinicalRecordValidatorTests
{
    private static readonly DateTimeOffset Now =
        new(2026, 9, 5, 12, 0, 0, TimeSpan.Zero);

    [Fact]
    public void Valid_encounter_has_no_errors()
    {
        var request = ValidRequest();

        var errors = ClinicalRecordValidator.Validate(request, Now);

        Assert.Empty(errors);
    }

    [Fact]
    public void Impossible_vitals_and_incomplete_prescription_are_rejected()
    {
        var request = ValidRequest() with
        {
            Observation = new ClinicalObservationInput(52, 300, 70, 90, 20, 2),
            Prescriptions = [new PrescriptionInput("", "", "", "", null)],
        };

        var errors = ClinicalRecordValidator.Validate(request, Now);

        Assert.Contains("observation.temperatureCelsius", errors.Keys);
        Assert.Contains("observation.systolicBloodPressure", errors.Keys);
        Assert.Contains("observation.oxygenSaturationPercent", errors.Keys);
        Assert.Contains("prescriptions[0].medicationName", errors.Keys);
    }

    private static CreateClinicalEncounterRequest ValidRequest() => new(
        "Shortness of breath",
        "Patient assessed and stabilized in the emergency unit.",
        "Discharged with follow-up",
        Now,
        new ClinicalObservationInput(37.2m, 92, 125, 78, 97, 19),
        [new PrescriptionInput("Salbutamol", "100 mcg", "As needed", "7 days", null)]);
}
