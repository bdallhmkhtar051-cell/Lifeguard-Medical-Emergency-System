namespace EmergencySystem.Application.Security;

public static class AuthorizationPolicyNames
{
    public const string PatientOnly = "PatientOnly";
    public const string DoctorOnly = "DoctorOnly";
    public const string AdministratorOnly = "AdministratorOnly";
}
