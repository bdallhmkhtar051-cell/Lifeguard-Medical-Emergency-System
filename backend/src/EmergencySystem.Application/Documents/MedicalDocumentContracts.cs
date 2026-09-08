namespace EmergencySystem.Application.Documents;

public sealed record MedicalDocumentResponse(
    Guid Id,
    string FileName,
    string ContentType,
    string Category,
    string? Description,
    long SizeBytes,
    DateTimeOffset UploadedAtUtc);

public sealed record MedicalDocumentFile(
    string FileName,
    string ContentType,
    byte[] Content);

public interface IMedicalDocumentService
{
    Task<IReadOnlyList<MedicalDocumentResponse>?> GetForPatientAsync(
        Guid patientUserId, CancellationToken cancellationToken = default);
    Task<MedicalDocumentResponse?> UploadAsync(
        Guid patientUserId, string fileName, string contentType, long length,
        Stream content, string? category, string? description,
        CancellationToken cancellationToken = default);
    Task<MedicalDocumentFile?> DownloadForPatientAsync(
        Guid patientUserId, Guid documentId,
        CancellationToken cancellationToken = default);
    Task<bool> DeleteForPatientAsync(
        Guid patientUserId, Guid documentId,
        CancellationToken cancellationToken = default);
    Task<IReadOnlyList<MedicalDocumentResponse>?> GetForDoctorAsync(
        Guid doctorUserId, Guid grantId,
        CancellationToken cancellationToken = default);
    Task<MedicalDocumentFile?> DownloadForDoctorAsync(
        Guid doctorUserId, Guid grantId, Guid documentId,
        CancellationToken cancellationToken = default);
}
