using EmergencySystem.Domain.Documents;
using EmergencySystem.Infrastructure.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace EmergencySystem.Infrastructure.Persistence;

internal sealed class MedicalDocumentConfiguration
    : IEntityTypeConfiguration<MedicalDocument>
{
    public void Configure(EntityTypeBuilder<MedicalDocument> builder)
    {
        builder.ToTable("MedicalDocuments");
        builder.HasKey(item => item.Id);
        builder.Property(item => item.FileName).HasMaxLength(200).IsRequired();
        builder.Property(item => item.ContentType).HasMaxLength(100).IsRequired();
        builder.Property(item => item.Category).HasMaxLength(50).IsRequired();
        builder.Property(item => item.Description).HasMaxLength(500);
        // Provider-neutral mapping: SQL Server uses varbinary(max), while the
        // integration-test SQLite provider uses BLOB.
        builder.Property(item => item.Content).IsRequired();
        builder.Property(item => item.UploadedAtUtc).HasPrecision(0);
        builder.Property(item => item.DeletedAtUtc).HasPrecision(0);
        builder.HasIndex(item => new { item.PatientProfileId, item.UploadedAtUtc });

        builder.HasOne(item => item.PatientProfile)
            .WithMany(profile => profile.MedicalDocuments)
            .HasForeignKey(item => item.PatientProfileId)
            .OnDelete(DeleteBehavior.Cascade);
        builder.HasOne<ApplicationUser>()
            .WithMany()
            .HasForeignKey(item => item.UploadedByUserId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
