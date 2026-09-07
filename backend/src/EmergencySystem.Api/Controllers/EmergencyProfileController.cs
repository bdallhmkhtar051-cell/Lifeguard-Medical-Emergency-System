using EmergencySystem.Api.Security;
using EmergencySystem.Application.Profiles;
using EmergencySystem.Application.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace EmergencySystem.Api.Controllers;

[ApiController]
[Authorize(Policy = AuthorizationPolicyNames.PatientOnly)]
[Route("api/v1/patients/me/emergency-profile")]
public sealed class EmergencyProfileController(
    IEmergencyProfileService profileService)
    : ControllerBase
{
    [HttpGet]
    [ProducesResponseType<EmergencyProfileResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status403Forbidden)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<EmergencyProfileResponse>> Get(
        CancellationToken cancellationToken)
    {
        PreventSensitiveResponseCaching();
        if (!User.TryGetUserId(out var userId))
        {
            return Problem(
                statusCode: StatusCodes.Status401Unauthorized,
                title: "Authentication required");
        }

        var document = await profileService.GetAsync(userId, cancellationToken);
        if (document is null)
        {
            return Problem(
                statusCode: StatusCodes.Status404NotFound,
                title: "Emergency profile not found");
        }

        WriteEtag(document.Version);
        return Ok(document.Profile);
    }

    [HttpPut]
    [ProducesResponseType<EmergencyProfileResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType<EmergencyProfileResponse>(StatusCodes.Status201Created)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status403Forbidden)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status412PreconditionFailed)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status428PreconditionRequired)]
    public async Task<ActionResult<EmergencyProfileResponse>> Put(
        UpdateEmergencyProfileRequest request,
        CancellationToken cancellationToken)
    {
        PreventSensitiveResponseCaching();
        if (!User.TryGetUserId(out var userId))
        {
            return Problem(
                statusCode: StatusCodes.Status401Unauthorized,
                title: "Authentication required");
        }

        var preconditionResult = ParsePrecondition();
        if (preconditionResult.Error is not null)
        {
            return preconditionResult.Error;
        }

        var result = await profileService.PutAsync(
            userId,
            request,
            preconditionResult.Value!.Value,
            cancellationToken);
        WriteEtag(result.Document.Version);

        if (result.Created)
        {
            return Created(
                "/api/v1/patients/me/emergency-profile",
                result.Document.Profile);
        }

        return Ok(result.Document.Profile);
    }

    private (ProfileWritePrecondition? Value, ActionResult? Error) ParsePrecondition()
    {
        var ifMatch = Request.Headers.IfMatch.ToString().Trim();
        var ifNoneMatch = Request.Headers.IfNoneMatch.ToString().Trim();

        if (string.IsNullOrEmpty(ifMatch) && string.IsNullOrEmpty(ifNoneMatch))
        {
            return (
                null,
                Problem(
                    statusCode: StatusCodes.Status428PreconditionRequired,
                    title: "A profile precondition is required",
                    detail: "Use If-None-Match: * to create a profile or If-Match with the current ETag to update it."));
        }

        if (string.IsNullOrEmpty(ifMatch) &&
            string.Equals(ifNoneMatch, "*", StringComparison.Ordinal))
        {
            return (ProfileWritePrecondition.Create(), null);
        }

        if (string.IsNullOrEmpty(ifNoneMatch) &&
            TryParseStrongEtag(ifMatch, out var expectedVersion))
        {
            return (ProfileWritePrecondition.Update(expectedVersion), null);
        }

        return (
            null,
            Problem(
                statusCode: StatusCodes.Status400BadRequest,
                title: "Invalid profile precondition",
                detail: "Supply exactly one strong If-Match ETag, or If-None-Match: * when creating the profile."));
    }

    private static bool TryParseStrongEtag(string value, out Guid version)
    {
        version = Guid.Empty;
        return value.Length > 2 &&
               value[0] == '"' &&
               value[^1] == '"' &&
               !value.Contains(',', StringComparison.Ordinal) &&
               Guid.TryParse(value[1..^1], out version);
    }

    private void WriteEtag(Guid version) =>
        Response.Headers.ETag = $"\"{version:D}\"";

    private void PreventSensitiveResponseCaching()
    {
        Response.Headers.CacheControl = "no-store";
        Response.Headers.Pragma = "no-cache";
    }
}
