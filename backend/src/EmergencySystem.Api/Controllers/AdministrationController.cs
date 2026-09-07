using EmergencySystem.Api.Security;
using EmergencySystem.Application.Administration;
using EmergencySystem.Application.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace EmergencySystem.Api.Controllers;

[ApiController]
[Route("api/v1/admin")]
[Authorize(Policy = AuthorizationPolicyNames.AdministratorOnly)]
[ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
public sealed class AdministrationController(IAdministrationService administrationService)
    : ControllerBase
{
    [HttpGet("users")]
    public async Task<ActionResult<IReadOnlyList<AdminUserSummary>>> GetUsers(
        CancellationToken cancellationToken) =>
        Ok(await administrationService.GetUsersAsync(cancellationToken));

    [HttpPut("users/{userId:guid}/status")]
    public async Task<ActionResult<AdminUserSummary>> UpdateStatus(
        Guid userId,
        UpdateUserStatusRequest request,
        CancellationToken cancellationToken)
    {
        if (!User.TryGetUserId(out var administratorUserId)) return Unauthorized();

        var result = await administrationService.UpdateUserStatusAsync(
            administratorUserId,
            userId,
            request.IsActive,
            cancellationToken);
        return result.Outcome switch
        {
            UpdateUserStatusOutcome.Updated => Ok(result.User),
            UpdateUserStatusOutcome.NotFound => NotFound(),
            UpdateUserStatusOutcome.SelfDeactivationDenied => Problem(
                statusCode: StatusCodes.Status409Conflict,
                title: "Self-deactivation is not allowed",
                detail: "Use another administrator account to deactivate this account."),
            _ => throw new InvalidOperationException("Unknown status update outcome."),
        };
    }

    [HttpGet("account-audit")]
    public async Task<ActionResult<IReadOnlyList<AccountAdministrationAuditResponse>>> GetAudit(
        CancellationToken cancellationToken) =>
        Ok(await administrationService.GetAccountAuditAsync(cancellationToken));

    [HttpGet("access-audit")]
    public async Task<ActionResult<IReadOnlyList<SystemAccessAuditResponse>>> GetAccessAudit(
        CancellationToken cancellationToken) =>
        Ok(await administrationService.GetAccessAuditAsync(cancellationToken));
}
