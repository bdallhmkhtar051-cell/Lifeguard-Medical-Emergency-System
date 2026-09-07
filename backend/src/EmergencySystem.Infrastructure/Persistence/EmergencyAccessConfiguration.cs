using EmergencySystem.Domain.Access;
using EmergencySystem.Infrastructure.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace EmergencySystem.Infrastructure.Persistence;

internal sealed class EmergencyAccessGrantConfiguration
    : IEntityTypeConfiguration<EmergencyAccessGrant>
{
    public void Configure(EntityTypeBuilder<EmergencyAccessGrant> builder)
    {
        builder.ToTable("EmergencyAccessGrants");
        builder.HasKey(grant => grant.Id);
        builder.Property(grant => grant.AccessType)
            .HasConversion<string>()
            .HasMaxLength(20);
        builder.Property(grant => grant.EmergencyReason).HasMaxLength(500);
        builder.Property(grant => grant.GrantedAtUtc).HasPrecision(0);
        builder.Property(grant => grant.ExpiresAtUtc).HasPrecision(0);
        builder.Property(grant => grant.RevokedAtUtc).HasPrecision(0);
        builder.HasIndex(grant => new { grant.PatientProfileId, grant.DoctorUserId });
        builder.HasIndex(grant => grant.ExpiresAtUtc);

        builder.HasOne(grant => grant.PatientProfile)
            .WithMany(profile => profile.AccessGrants)
            .HasForeignKey(grant => grant.PatientProfileId)
            .OnDelete(DeleteBehavior.Cascade);
        builder.HasOne<ApplicationUser>()
            .WithMany()
            .HasForeignKey(grant => grant.DoctorUserId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}

internal sealed class AccessAuditEventConfiguration
    : IEntityTypeConfiguration<AccessAuditEvent>
{
    public void Configure(EntityTypeBuilder<AccessAuditEvent> builder)
    {
        builder.ToTable("AccessAuditEvents");
        builder.HasKey(item => item.Id);
        builder.Property(item => item.Action).HasConversion<string>().HasMaxLength(30);
        builder.Property(item => item.OccurredAtUtc).HasPrecision(0);
        builder.HasIndex(item => new { item.EmergencyAccessGrantId, item.OccurredAtUtc });

        builder.HasOne(item => item.EmergencyAccessGrant)
            .WithMany(grant => grant.AuditEvents)
            .HasForeignKey(item => item.EmergencyAccessGrantId)
            .OnDelete(DeleteBehavior.Cascade);
        builder.HasOne<ApplicationUser>()
            .WithMany()
            .HasForeignKey(item => item.ActorUserId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
