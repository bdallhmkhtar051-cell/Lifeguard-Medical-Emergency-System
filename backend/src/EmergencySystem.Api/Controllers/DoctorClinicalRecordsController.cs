using EmergencySystem.Api.Security;
using EmergencySystem.Application.Clinical;
using EmergencySystem.Application.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace EmergencySystem.Api.Controllers;

[ApiController]
[Route("api/v1/doctors/emergency-access/{grantId:guid}/clinical-records")]
[Authorize(Policy = AuthorizationPolicyNames.DoctorOnly)]
[ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
public sealed class DoctorClinicalRecordsController(IClinicalRecordService service)
    : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<ClinicalEncounterResponse>>> Get(
        Guid grantId,
        CancellationToken cancellationToken)
    {
        if (!User.TryGetUserId(out var doctorId)) return Unauthorized();
        var records = await service.GetForDoctorAsync(
            doctorId, grantId, cancellationToken);
        return records is null ? NotFound() : Ok(records);
    }

    [HttpPost]
    public async Task<ActionResult<ClinicalEncounterResponse>> Create(
        Guid grantId,
        CreateClinicalEncounterRequest request,
        CancellationToken cancellationToken)
    {
        if (!User.TryGetUserId(out var doctorId)) return Unauthorized();
        var record = await service.CreateAsync(
            doctorId, grantId, request, cancellationToken);
        return record is null
            ? NotFound()
            : CreatedAtAction(nameof(Get), new { grantId }, record);
    }
}
