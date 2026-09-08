using EmergencySystem.Application.Common;
using EmergencySystem.Application.Documents;
using EmergencySystem.Domain.Access;
using EmergencySystem.Domain.Documents;
using EmergencySystem.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace EmergencySystem.Infrastructure.Documents;

internal sealed class MedicalDocumentService(
    ApplicationDbContext dbContext,
    TimeProvider timeProvider) : IMedicalDocumentService
{
    private const int MaximumBytes = 5 * 1024 * 1024;
    private const int MaximumDocuments = 25;

    public async Task<IReadOnlyList<MedicalDocumentResponse>?> GetForPatientAsync(
        Guid patientUserId, CancellationToken cancellationToken = default)
    {
        var profileId = await PatientProfileIdAsync(patientUserId, cancellationToken);
        return profileId is null ? null : await ListAsync(profileId.Value, cancellationToken);
    }

    public async Task<MedicalDocumentResponse?> UploadAsync(
        Guid patientUserId, string fileName, string contentType, long length,
        Stream content, string? category, string? description,
        CancellationToken cancellationToken = default)
    {
        var errors = Validate(fileName, contentType, length, category, description);
        if (errors.Count > 0) throw new RequestValidationException(errors);
        var profileId = await PatientProfileIdAsync(patientUserId, cancellationToken);
        if (profileId is null) return null;

        var count = await dbContext.MedicalDocuments.CountAsync(
            item => item.PatientProfileId == profileId && item.DeletedAtUtc == null,
            cancellationToken);
        if (count >= MaximumDocuments)
            throw new RequestValidationException(new Dictionary<string, string[]>
            {
                ["file"] = [$"A patient may keep up to {MaximumDocuments} active documents."],
            });

        await using var buffer = new MemoryStream();
        await content.CopyToAsync(buffer, cancellationToken);
        var bytes = buffer.ToArray();
        if (bytes.Length != length || !HasValidSignature(contentType, bytes))
            throw new RequestValidationException(new Dictionary<string, string[]>
            {
                ["file"] = ["The file content does not match an allowed PDF, JPEG, or PNG document."],
            });

        var document = new MedicalDocument
        {
            Id = Guid.NewGuid(),
            PatientProfileId = profileId.Value,
            UploadedByUserId = patientUserId,
            FileName = Path.GetFileName(fileName).Trim(),
            ContentType = contentType.ToLowerInvariant(),
            Category = Clean(category) ?? "Other",
            Description = Clean(description),
            SizeBytes = bytes.LongLength,
            Content = bytes,
            UploadedAtUtc = timeProvider.GetUtcNow(),
        };
        dbContext.MedicalDocuments.Add(document);
        await dbContext.SaveChangesAsync(cancellationToken);
        return Map(document);
    }

    public async Task<MedicalDocumentFile?> DownloadForPatientAsync(
        Guid patientUserId, Guid documentId,
        CancellationToken cancellationToken = default)
    {
        var profileId = await PatientProfileIdAsync(patientUserId, cancellationToken);
        return profileId is null
            ? null
            : await FileAsync(profileId.Value, documentId, cancellationToken);
    }

    public async Task<bool> DeleteForPatientAsync(
        Guid patientUserId, Guid documentId,
        CancellationToken cancellationToken = default)
    {
        var profileId = await PatientProfileIdAsync(patientUserId, cancellationToken);
        if (profileId is null) return false;
        var document = await dbContext.MedicalDocuments.SingleOrDefaultAsync(
            item => item.Id == documentId &&
                    item.PatientProfileId == profileId &&
                    item.DeletedAtUtc == null,
            cancellationToken);
        if (document is null) return false;
        document.DeletedAtUtc = timeProvider.GetUtcNow();
        document.Content = [];
        await dbContext.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<IReadOnlyList<MedicalDocumentResponse>?> GetForDoctorAsync(
        Guid doctorUserId, Guid grantId,
        CancellationToken cancellationToken = default)
    {
        var profileId = await ActiveGrantProfileIdAsync(
            doctorUserId, grantId, cancellationToken);
        return profileId is null ? null : await ListAsync(profileId.Value, cancellationToken);
    }

    public async Task<MedicalDocumentFile?> DownloadForDoctorAsync(
        Guid doctorUserId, Guid grantId, Guid documentId,
        CancellationToken cancellationToken = default)
    {
        var profileId = await ActiveGrantProfileIdAsync(
            doctorUserId, grantId, cancellationToken);
        if (profileId is null) return null;
        var file = await FileAsync(profileId.Value, documentId, cancellationToken);
        if (file is null) return null;
        dbContext.AccessAuditEvents.Add(new AccessAuditEvent
        {
            Id = Guid.NewGuid(),
            EmergencyAccessGrantId = grantId,
            ActorUserId = doctorUserId,
            Action = AccessAuditAction.MedicalDocumentDownloaded,
            OccurredAtUtc = timeProvider.GetUtcNow(),
        });
        await dbContext.SaveChangesAsync(cancellationToken);
        return file;
    }

    private Task<Guid?> PatientProfileIdAsync(
        Guid userId, CancellationToken cancellationToken) =>
        dbContext.PatientProfiles.AsNoTracking()
            .Where(item => item.UserId == userId)
            .Select(item => (Guid?)item.Id)
            .SingleOrDefaultAsync(cancellationToken);

    private async Task<Guid?> ActiveGrantProfileIdAsync(
        Guid doctorUserId, Guid grantId, CancellationToken cancellationToken)
    {
        // Compare DateTimeOffset after materialization for SQL Server/SQLite parity.
        var grant = await dbContext.EmergencyAccessGrants.AsNoTracking()
            .Where(item => item.Id == grantId &&
                           item.DoctorUserId == doctorUserId &&
                           item.RevokedAtUtc == null)
            .SingleOrDefaultAsync(cancellationToken);
        return grant is not null && grant.ExpiresAtUtc > timeProvider.GetUtcNow()
            ? grant.PatientProfileId
            : null;
    }

    private async Task<IReadOnlyList<MedicalDocumentResponse>> ListAsync(
        Guid profileId, CancellationToken cancellationToken)
    {
        var items = await dbContext.MedicalDocuments.AsNoTracking()
            .Where(item => item.PatientProfileId == profileId && item.DeletedAtUtc == null)
            .ToListAsync(cancellationToken);
        return items.OrderByDescending(item => item.UploadedAtUtc).Select(Map).ToArray();
    }

    private async Task<MedicalDocumentFile?> FileAsync(
        Guid profileId, Guid documentId, CancellationToken cancellationToken) =>
        await dbContext.MedicalDocuments.AsNoTracking()
            .Where(item => item.Id == documentId &&
                           item.PatientProfileId == profileId &&
                           item.DeletedAtUtc == null)
            .Select(item => new MedicalDocumentFile(
                item.FileName, item.ContentType, item.Content))
            .SingleOrDefaultAsync(cancellationToken);

    private static Dictionary<string, string[]> Validate(
        string fileName, string contentType, long length,
        string? category, string? description)
    {
        var errors = new Dictionary<string, string[]>();
        var safeName = Path.GetFileName(fileName);
        var extension = Path.GetExtension(safeName).ToLowerInvariant();
        if (string.IsNullOrWhiteSpace(safeName) || safeName.Length > 200)
            errors["file"] = ["Choose a file with a name of at most 200 characters."];
        if (length is <= 0 or > MaximumBytes)
            errors["file"] = ["The document must be between 1 byte and 5 MB."];
        var expectedContentType = extension switch
        {
            ".pdf" => "application/pdf",
            ".jpg" or ".jpeg" => "image/jpeg",
            ".png" => "image/png",
            _ => null,
        };
        if (expectedContentType is null ||
            !string.Equals(expectedContentType, contentType, StringComparison.OrdinalIgnoreCase))
            errors["file"] = ["Only PDF, JPEG, and PNG documents are allowed."];
        if (category?.Trim().Length > 50)
            errors["category"] = ["Category must be at most 50 characters."];
        if (description?.Trim().Length > 500)
            errors["description"] = ["Description must be at most 500 characters."];
        return errors;
    }

    private static bool HasValidSignature(string contentType, byte[] content) =>
        contentType.ToLowerInvariant() switch
        {
            "application/pdf" => content.AsSpan().StartsWith("%PDF"u8),
            "image/png" => content.AsSpan().StartsWith(
                new byte[] { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A }),
            "image/jpeg" => content.AsSpan().StartsWith(
                new byte[] { 0xFF, 0xD8, 0xFF }),
            _ => false,
        };

    private static MedicalDocumentResponse Map(MedicalDocument item) => new(
        item.Id, item.FileName, item.ContentType, item.Category,
        item.Description, item.SizeBytes, item.UploadedAtUtc);

    private static string? Clean(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();

}
