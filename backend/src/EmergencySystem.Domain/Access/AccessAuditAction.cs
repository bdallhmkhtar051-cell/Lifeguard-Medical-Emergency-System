namespace EmergencySystem.Domain.Access;

public enum AccessAuditAction
{
    Granted,
    Viewed,
    Revoked,
    BreakGlassActivated,
    QrRedeemed,
    ClinicalRecordCreated,
    MedicalDocumentDownloaded,
}
