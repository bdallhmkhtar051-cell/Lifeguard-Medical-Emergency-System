using EmergencySystem.Domain.Access;
using EmergencySystem.Domain.Clinical;
using EmergencySystem.Domain.Patients;
using EmergencySystem.Infrastructure.Identity;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace EmergencySystem.Infrastructure.Persistence;

public sealed class ApplicationDbContext(
    DbContextOptions<ApplicationDbContext> options)
    : IdentityDbContext<ApplicationUser, IdentityRole<Guid>, Guid>(options)
{
    public DbSet<PatientProfile> PatientProfiles => Set<PatientProfile>();

    public DbSet<Allergy> Allergies => Set<Allergy>();

    public DbSet<MedicalCondition> MedicalConditions => Set<MedicalCondition>();

    public DbSet<Medication> Medications => Set<Medication>();

    public DbSet<EmergencyContact> EmergencyContacts => Set<EmergencyContact>();

    public DbSet<EmergencyAccessGrant> EmergencyAccessGrants => Set<EmergencyAccessGrant>();

    public DbSet<AccessAuditEvent> AccessAuditEvents => Set<AccessAuditEvent>();

    public DbSet<MedicalQrToken> MedicalQrTokens => Set<MedicalQrToken>();

    public DbSet<ClinicalEncounter> ClinicalEncounters => Set<ClinicalEncounter>();

    public DbSet<ClinicalObservation> ClinicalObservations => Set<ClinicalObservation>();

    public DbSet<Prescription> Prescriptions => Set<Prescription>();

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);
        builder.ApplyConfigurationsFromAssembly(typeof(ApplicationDbContext).Assembly);
    }
}
