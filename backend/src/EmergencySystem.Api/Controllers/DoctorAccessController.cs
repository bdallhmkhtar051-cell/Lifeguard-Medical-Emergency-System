using EmergencySystem.Api.Security;
using EmergencySystem.Api.RateLimiting;
using EmergencySystem.Application.Access;
using EmergencySystem.Application.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace EmergencySystem.Api.Controllers;

[ApiController]
[Route("api/v1/doctors/emergency-access")]
[Authorize(Policy = AuthorizationPolicyNames.DoctorOnly)]
[ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
public sealed class DoctorAccessController(IEmergencyAccessService accessService)
    : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<DoctorAccessResponse>>> Get(
        CancellationToken cancellationToken)
    {
        if (!User.TryGetUserId(out var userId)) return Unauthorized();
        return Ok(await accessService.GetDoctorAccessAsync(userId, cancellationToken));
    }

    [HttpGet("directory")]
    public async Task<ActionResult<IReadOnlyList<DoctorPatientDirectoryResponse>>> Directory(
        CancellationToken cancellationToken) =>
        Ok(await accessService.GetDoctorDirectoryAsync(cancellationToken));

    [HttpPost("break-glass")]
    [EnableRateLimiting(RateLimitPolicyNames.EmergencyOverride)]
    public async Task<ActionResult<DoctorAccessResponse>> BreakGlass(
        BreakGlassAccessRequest request,
        CancellationToken cancellationToken)
    {
        if (!User.TryGetUserId(out var userId)) return Unauthorized();
        var access = await accessService.BreakGlassAsync(
            userId, request, cancellationToken);
        return access is null ? NotFound() : Ok(access);
    }

    [HttpGet("{grantId:guid}/snapshot")]
    public async Task<ActionResult<DoctorEmergencySnapshotResponse>> Snapshot(
        Guid grantId,
        CancellationToken cancellationToken)
    {
        if (!User.TryGetUserId(out var userId)) return Unauthorized();
        var snapshot = await accessService.GetDoctorSnapshotAsync(
            userId, grantId, cancellationToken);
        return snapshot is null ? NotFound() : Ok(snapshot);
    }
}
