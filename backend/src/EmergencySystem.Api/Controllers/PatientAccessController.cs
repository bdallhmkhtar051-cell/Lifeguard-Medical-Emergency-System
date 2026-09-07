using EmergencySystem.Api.Security;
using EmergencySystem.Application.Access;
using EmergencySystem.Application.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace EmergencySystem.Api.Controllers;

[ApiController]
[Route("api/v1/patients/me/emergency-access")]
[Authorize(Policy = AuthorizationPolicyNames.PatientOnly)]
[ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
public sealed class PatientAccessController(IEmergencyAccessService accessService)
    : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<PatientAccessDashboardResponse>> Get(
        CancellationToken cancellationToken)
    {
        if (!User.TryGetUserId(out var userId)) return Unauthorized();
        var dashboard = await accessService.GetPatientDashboardAsync(userId, cancellationToken);
        return dashboard is null ? NotFound() : Ok(dashboard);
    }

    [HttpPost]
    public async Task<ActionResult<EmergencyAccessGrantResponse>> Grant(
        GrantEmergencyAccessRequest request,
        CancellationToken cancellationToken)
    {
        if (!User.TryGetUserId(out var userId)) return Unauthorized();
        var grant = await accessService.GrantAsync(userId, request, cancellationToken);
        return grant is null ? NotFound() : Ok(grant);
    }

    [HttpPost("{grantId:guid}/revoke")]
    public async Task<IActionResult> Revoke(
        Guid grantId,
        CancellationToken cancellationToken)
    {
        if (!User.TryGetUserId(out var userId)) return Unauthorized();
        return await accessService.RevokeAsync(userId, grantId, cancellationToken)
            ? NoContent()
            : NotFound();
    }
}
