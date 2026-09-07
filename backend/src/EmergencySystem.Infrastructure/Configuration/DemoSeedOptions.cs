namespace EmergencySystem.Infrastructure.Configuration;

public sealed class DemoSeedOptions
{
    public const string SectionName = "DemoSeed";

    public bool Enabled { get; init; }

    public DemoUserOptions Patient { get; init; } = new()
    {
        Email = "patient.demo@emergency.test",
        DisplayName = "Amina Hassan",
    };

    public DemoUserOptions Doctor { get; init; } = new()
    {
        Email = "doctor.demo@emergency.test",
        DisplayName = "Dr. Yusuf Ali",
    };

    public DemoUserOptions Administrator { get; init; } = new()
    {
        Email = "admin.demo@emergency.test",
        DisplayName = "Demo Administrator",
    };
}

public sealed class DemoUserOptions
{
    public string Email { get; init; } = string.Empty;

    public string DisplayName { get; init; } = string.Empty;

    public string Password { get; init; } = string.Empty;
}
