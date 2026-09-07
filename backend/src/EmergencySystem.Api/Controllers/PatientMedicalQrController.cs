using EmergencySystem.Api.Security;
using EmergencySystem.Application.Access;
using EmergencySystem.Application.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace EmergencySystem.Api.Controllers;

[ApiController]
[Route("api/v1/patients/me/medical-qr")]
[Authorize(Policy = AuthorizationPolicyNames.PatientOnly)]
[ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
public sealed class PatientMedicalQrController(IEmergencyAccessService accessService)
    : ControllerBase
{
    [HttpPost]
    public async Task<ActionResult<MedicalQrIssueResponse>> Issue(
        CancellationToken cancellationToken)
    {
        if (!User.TryGetUserId(out var patientId)) return Unauthorized();
        var result = await accessService.IssueMedicalQrAsync(
            patientId, cancellationToken);
        return result is null ? NotFound() : Ok(result);
    }

    [HttpPost("revoke")]
    public async Task<IActionResult> Revoke(CancellationToken cancellationToken)
    {
        if (!User.TryGetUserId(out var patientId)) return Unauthorized();
        return await accessService.RevokeMedicalQrAsync(patientId, cancellationToken)
            ? NoContent()
            : NotFound();
    }
}
