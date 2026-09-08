using EmergencySystem.Api.Security;
using EmergencySystem.Application.Documents;
using EmergencySystem.Application.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace EmergencySystem.Api.Controllers;

[ApiController]
[Route("api/v1/patients/me/documents")]
[Authorize(Policy = AuthorizationPolicyNames.PatientOnly)]
[ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
public sealed class PatientDocumentsController(IMedicalDocumentService service)
    : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<MedicalDocumentResponse>>> Get(
        CancellationToken cancellationToken)
    {
        if (!User.TryGetUserId(out var patientId)) return Unauthorized();
        var documents = await service.GetForPatientAsync(patientId, cancellationToken);
        return documents is null ? NotFound() : Ok(documents);
    }

    [HttpPost]
    [Consumes("multipart/form-data")]
    [RequestFormLimits(MultipartBodyLengthLimit = 6 * 1024 * 1024)]
    public async Task<ActionResult<MedicalDocumentResponse>> Upload(
        IFormFile file, [FromForm] string? category, [FromForm] string? description,
        CancellationToken cancellationToken)
    {
        if (!User.TryGetUserId(out var patientId)) return Unauthorized();
        await using var stream = file.OpenReadStream();
        var document = await service.UploadAsync(
            patientId, file.FileName, file.ContentType, file.Length, stream,
            category, description, cancellationToken);
        return document is null ? NotFound() : CreatedAtAction(
            nameof(Download), new { documentId = document.Id }, document);
    }

    [HttpGet("{documentId:guid}/content")]
    public async Task<IActionResult> Download(
        Guid documentId, CancellationToken cancellationToken)
    {
        if (!User.TryGetUserId(out var patientId)) return Unauthorized();
        var file = await service.DownloadForPatientAsync(
            patientId, documentId, cancellationToken);
        return file is null
            ? NotFound()
            : File(file.Content, file.ContentType, file.FileName);
    }

    [HttpDelete("{documentId:guid}")]
    public async Task<IActionResult> Delete(
        Guid documentId, CancellationToken cancellationToken)
    {
        if (!User.TryGetUserId(out var patientId)) return Unauthorized();
        return await service.DeleteForPatientAsync(
            patientId, documentId, cancellationToken)
            ? NoContent()
            : NotFound();
    }
}
