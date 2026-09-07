using EmergencySystem.Api.Security;
using EmergencySystem.Application.Clinical;
using EmergencySystem.Application.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace EmergencySystem.Api.Controllers;

[ApiController]
[Route("api/v1/patients/me/clinical-records")]
[Authorize(Policy = AuthorizationPolicyNames.PatientOnly)]
[ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
public sealed class PatientClinicalRecordsController(IClinicalRecordService service)
    : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<ClinicalEncounterResponse>>> Get(
        CancellationToken cancellationToken)
    {
        if (!User.TryGetUserId(out var patientId)) return Unauthorized();
        var records = await service.GetForPatientAsync(patientId, cancellationToken);
        return records is null ? NotFound() : Ok(records);
    }
}
