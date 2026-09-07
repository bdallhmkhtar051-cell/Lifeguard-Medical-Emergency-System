using EmergencySystem.Api.RateLimiting;
using EmergencySystem.Api.Security;
using EmergencySystem.Application.Access;
using EmergencySystem.Application.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace EmergencySystem.Api.Controllers;

[ApiController]
[Route("api/v1/doctors/emergency-access/medical-qr")]
[Authorize(Policy = AuthorizationPolicyNames.DoctorOnly)]
[ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
public sealed class DoctorMedicalQrController(IEmergencyAccessService accessService)
    : ControllerBase
{
    [HttpPost("redeem")]
    [EnableRateLimiting(RateLimitPolicyNames.MedicalQr)]
    public async Task<ActionResult<DoctorAccessResponse>> Redeem(
        RedeemMedicalQrRequest request,
        CancellationToken cancellationToken)
    {
        if (!User.TryGetUserId(out var doctorId)) return Unauthorized();
        var result = await accessService.RedeemMedicalQrAsync(
            doctorId, request, cancellationToken);
        return result is null ? NotFound() : Ok(result);
    }
}
