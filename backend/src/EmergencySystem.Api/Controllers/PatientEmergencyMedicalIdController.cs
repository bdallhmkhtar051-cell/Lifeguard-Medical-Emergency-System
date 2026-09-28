using EmergencySystem.Api.RateLimiting;
using EmergencySystem.Api.Security;
using EmergencySystem.Application.Access;
using EmergencySystem.Application.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace EmergencySystem.Api.Controllers;

[ApiController]
[Route("api/v1/patients/me/emergency-medical-id")]
[Authorize(Policy = AuthorizationPolicyNames.PatientOnly)]
[ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
public sealed class PatientEmergencyMedicalIdController(
    IEmergencyAccessService accessService) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<EmergencyMedicalIdResponse>> Get(
        CancellationToken cancellationToken)
    {
        if (!User.TryGetUserId(out var patientId)) return Unauthorized();
        var result = await accessService.GetEmergencyMedicalIdAsync(
            patientId,
            cancellationToken);
        return result is null ? NotFound() : Ok(result);
    }

    [HttpPost("rotate")]
    [EnableRateLimiting(RateLimitPolicyNames.MedicalQr)]
    public async Task<ActionResult<EmergencyMedicalIdResponse>> Rotate(
        CancellationToken cancellationToken)
    {
        if (!User.TryGetUserId(out var patientId)) return Unauthorized();
        var result = await accessService.RotateEmergencyMedicalIdAsync(
            patientId,
            cancellationToken);
        return result is null ? NotFound() : Ok(result);
    }
}
