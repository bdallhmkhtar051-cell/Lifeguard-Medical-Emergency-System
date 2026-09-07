namespace EmergencySystem.Domain.Identity;

public static class RoleNames
{
    public const string Patient = "Patient";
    public const string Doctor = "Doctor";
    public const string Administrator = "Administrator";

    public static readonly string[] All = [Patient, Doctor, Administrator];
}
