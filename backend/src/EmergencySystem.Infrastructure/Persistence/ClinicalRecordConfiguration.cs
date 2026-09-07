using EmergencySystem.Domain.Clinical;
using EmergencySystem.Infrastructure.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace EmergencySystem.Infrastructure.Persistence;

internal sealed class ClinicalEncounterConfiguration
    : IEntityTypeConfiguration<ClinicalEncounter>
{
    public void Configure(EntityTypeBuilder<ClinicalEncounter> builder)
    {
        builder.ToTable("ClinicalEncounters");
        builder.HasKey(item => item.Id);
        builder.Property(item => item.ChiefComplaint).HasMaxLength(200).IsRequired();
        builder.Property(item => item.ClinicalNotes).HasMaxLength(2000).IsRequired();
        builder.Property(item => item.Disposition).HasMaxLength(200);
        builder.Property(item => item.OccurredAtUtc).HasPrecision(0);
        builder.Property(item => item.CreatedAtUtc).HasPrecision(0);
        builder.HasIndex(item => new { item.PatientProfileId, item.OccurredAtUtc });
        builder.HasIndex(item => item.DoctorUserId);

        builder.HasOne(item => item.PatientProfile)
            .WithMany(profile => profile.ClinicalEncounters)
            .HasForeignKey(item => item.PatientProfileId)
            .OnDelete(DeleteBehavior.Cascade);
        builder.HasOne<ApplicationUser>()
            .WithMany()
            .HasForeignKey(item => item.DoctorUserId)
            .OnDelete(DeleteBehavior.Restrict);
        builder.HasOne(item => item.EmergencyAccessGrant)
            .WithMany(grant => grant.ClinicalEncounters)
            .HasForeignKey(item => item.EmergencyAccessGrantId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}

internal sealed class ClinicalObservationConfiguration
    : IEntityTypeConfiguration<ClinicalObservation>
{
    public void Configure(EntityTypeBuilder<ClinicalObservation> builder)
    {
        builder.ToTable("ClinicalObservations");
        builder.HasKey(item => item.Id);
        builder.Property(item => item.TemperatureCelsius).HasPrecision(4, 1);
        builder.HasIndex(item => item.ClinicalEncounterId).IsUnique();
        builder.HasOne(item => item.ClinicalEncounter)
            .WithOne(encounter => encounter.Observation)
            .HasForeignKey<ClinicalObservation>(item => item.ClinicalEncounterId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

internal sealed class PrescriptionConfiguration
    : IEntityTypeConfiguration<Prescription>
{
    public void Configure(EntityTypeBuilder<Prescription> builder)
    {
        builder.ToTable("Prescriptions");
        builder.HasKey(item => item.Id);
        builder.Property(item => item.MedicationName).HasMaxLength(100).IsRequired();
        builder.Property(item => item.Dosage).HasMaxLength(100).IsRequired();
        builder.Property(item => item.Frequency).HasMaxLength(100).IsRequired();
        builder.Property(item => item.Duration).HasMaxLength(100).IsRequired();
        builder.Property(item => item.Instructions).HasMaxLength(500);
        builder.HasIndex(item => item.ClinicalEncounterId);
        builder.HasOne(item => item.ClinicalEncounter)
            .WithMany(encounter => encounter.Prescriptions)
            .HasForeignKey(item => item.ClinicalEncounterId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
