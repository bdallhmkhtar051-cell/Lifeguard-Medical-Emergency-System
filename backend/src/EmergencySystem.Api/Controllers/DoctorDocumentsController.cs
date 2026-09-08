using EmergencySystem.Api.Security;
using EmergencySystem.Application.Documents;
using EmergencySystem.Application.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace EmergencySystem.Api.Controllers;

[ApiController]
[Route("api/v1/doctors/emergency-access/{grantId:guid}/documents")]
[Authorize(Policy = AuthorizationPolicyNames.DoctorOnly)]
[ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
public sealed class DoctorDocumentsController(IMedicalDocumentService service)
    : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<MedicalDocumentResponse>>> Get(
        Guid grantId, CancellationToken cancellationToken)
    {
        if (!User.TryGetUserId(out var doctorId)) return Unauthorized();
        var documents = await service.GetForDoctorAsync(
            doctorId, grantId, cancellationToken);
        return documents is null ? NotFound() : Ok(documents);
    }

    [HttpGet("{documentId:guid}/content")]
    public async Task<IActionResult> Download(
        Guid grantId, Guid documentId, CancellationToken cancellationToken)
    {
        if (!User.TryGetUserId(out var doctorId)) return Unauthorized();
        var file = await service.DownloadForDoctorAsync(
            doctorId, grantId, documentId, cancellationToken);
        return file is null
            ? NotFound()
            : File(file.Content, file.ContentType, file.FileName);
    }
}
