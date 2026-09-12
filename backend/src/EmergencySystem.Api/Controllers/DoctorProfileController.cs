using EmergencySystem.Api.Security;
using EmergencySystem.Application.Security;
using EmergencySystem.Infrastructure.Identity;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;

namespace EmergencySystem.Api.Controllers;

[ApiController]
[Route("api/v1/doctors/me/profile")]
[Authorize(Policy = AuthorizationPolicyNames.DoctorOnly)]
[ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
public sealed class DoctorProfileController(UserManager<ApplicationUser> users) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<DoctorProfileResponse>> Get()
    {
        if (!User.TryGetUserId(out var id)) return Unauthorized();
        var user = await users.FindByIdAsync(id.ToString());
        return user is null ? NotFound() : Ok(Map(user));
    }

    [HttpPut]
    public async Task<ActionResult<DoctorProfileResponse>> Put(UpdateDoctorProfileRequest request)
    {
        if (!User.TryGetUserId(out var id)) return Unauthorized();
        Validate(request);
        if (!ModelState.IsValid) return ValidationProblem(ModelState);
        var user = await users.FindByIdAsync(id.ToString());
        if (user is null) return NotFound();
        user.ProfessionalTitle = Clean(request.ProfessionalTitle);
        user.HospitalName = Clean(request.HospitalName);
        user.Department = Clean(request.Department);
        user.LicenseNumber = Clean(request.LicenseNumber);
        user.PhoneNumber = Clean(request.PhoneNumber);
        var result = await users.UpdateAsync(user);
        if (!result.Succeeded)
        {
            foreach (var error in result.Errors) ModelState.AddModelError(string.Empty, error.Description);
            return ValidationProblem(ModelState);
        }
        return Ok(Map(user));
    }

    private void Validate(UpdateDoctorProfileRequest request)
    {
        Check(nameof(request.ProfessionalTitle), request.ProfessionalTitle, 100);
        Check(nameof(request.HospitalName), request.HospitalName, 150);
        Check(nameof(request.Department), request.Department, 100);
        Check(nameof(request.LicenseNumber), request.LicenseNumber, 80);
        Check(nameof(request.PhoneNumber), request.PhoneNumber, 24);
    }

    private void Check(string field, string? value, int maximum)
    {
        if ((value?.Trim().Length ?? 0) > maximum)
            ModelState.AddModelError(field, $"{field} must be {maximum} characters or fewer.");
    }

    private static string? Clean(string? value) => string.IsNullOrWhiteSpace(value) ? null : value.Trim();
    private static DoctorProfileResponse Map(ApplicationUser user) => new(
        user.DisplayName, user.Email ?? string.Empty, user.ProfessionalTitle,
        user.HospitalName, user.Department, user.LicenseNumber, user.PhoneNumber,
        false);
}

public sealed record UpdateDoctorProfileRequest(
    string? ProfessionalTitle, string? HospitalName, string? Department,
    string? LicenseNumber, string? PhoneNumber);

public sealed record DoctorProfileResponse(
    string DisplayName, string Email, string? ProfessionalTitle,
    string? HospitalName, string? Department, string? LicenseNumber,
    string? PhoneNumber, bool LicenseVerified);
