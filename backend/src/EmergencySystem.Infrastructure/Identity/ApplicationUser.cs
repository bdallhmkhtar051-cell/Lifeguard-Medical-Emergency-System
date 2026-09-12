using Microsoft.AspNetCore.Identity;

namespace EmergencySystem.Infrastructure.Identity;

public sealed class ApplicationUser : IdentityUser<Guid>
{
    public string DisplayName { get; set; } = string.Empty;

    public bool IsActive { get; set; } = true;

    public DateTimeOffset CreatedAtUtc { get; set; }

    public string? ProfessionalTitle { get; set; }
    public string? HospitalName { get; set; }
    public string? Department { get; set; }
    public string? LicenseNumber { get; set; }
}
