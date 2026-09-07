using EmergencySystem.Domain.Administration;
using EmergencySystem.Infrastructure.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace EmergencySystem.Infrastructure.Persistence;

internal sealed class AccountAdministrationEventConfiguration
    : IEntityTypeConfiguration<AccountAdministrationEvent>
{
    public void Configure(EntityTypeBuilder<AccountAdministrationEvent> builder)
    {
        builder.ToTable("AccountAdministrationEvents");
        builder.HasKey(item => item.Id);
        builder.Property(item => item.Action).HasConversion<string>().HasMaxLength(20);
        builder.Property(item => item.OccurredAtUtc).HasPrecision(0);
        builder.HasIndex(item => item.OccurredAtUtc);
        builder.HasIndex(item => item.TargetUserId);

        builder.HasOne<ApplicationUser>()
            .WithMany()
            .HasForeignKey(item => item.AdministratorUserId)
            .OnDelete(DeleteBehavior.Restrict);
        builder.HasOne<ApplicationUser>()
            .WithMany()
            .HasForeignKey(item => item.TargetUserId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
