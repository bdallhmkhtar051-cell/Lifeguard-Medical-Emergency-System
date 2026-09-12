using EmergencySystem.Domain.Patients;
using EmergencySystem.Infrastructure.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace EmergencySystem.Infrastructure.Persistence;

internal sealed class PatientProfileConfiguration
    : IEntityTypeConfiguration<PatientProfile>
{
    public void Configure(EntityTypeBuilder<PatientProfile> builder)
    {
        builder.ToTable("PatientProfiles");
        builder.HasKey(profile => profile.Id);
        builder.Property(profile => profile.FullName).HasMaxLength(100).IsRequired();
        builder.Property(profile => profile.DateOfBirth).HasColumnType("date");
        builder.Property(profile => profile.BloodGroup)
            .HasConversion<string>()
            .HasMaxLength(20);
        builder.Property(profile => profile.PrimaryPhysicianName).HasMaxLength(100);
        builder.Property(profile => profile.PrimaryPhysicianPhone).HasMaxLength(16);
        builder.Property(profile => profile.InsuranceProvider).HasMaxLength(100);
        builder.Property(profile => profile.InsurancePolicyNumber).HasMaxLength(100);
        builder.Property(profile => profile.OrganDonorStatus)
            .HasConversion<string>()
            .HasMaxLength(20);
        builder.Property(profile => profile.FirstResponderNotes).HasMaxLength(1000);
        builder.Property(profile => profile.UpdatedAtUtc).HasPrecision(0);
        builder.Property(profile => profile.Version).IsConcurrencyToken();
        builder.HasIndex(profile => profile.UserId).IsUnique();

        builder.HasOne<ApplicationUser>()
            .WithOne()
            .HasForeignKey<PatientProfile>(profile => profile.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasMany(profile => profile.Allergies)
            .WithOne(allergy => allergy.PatientProfile)
            .HasForeignKey(allergy => allergy.PatientProfileId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(profile => profile.MedicalConditions)
            .WithOne(condition => condition.PatientProfile)
            .HasForeignKey(condition => condition.PatientProfileId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(profile => profile.Medications)
            .WithOne(medication => medication.PatientProfile)
            .HasForeignKey(medication => medication.PatientProfileId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(profile => profile.EmergencyContacts)
            .WithOne(contact => contact.PatientProfile)
            .HasForeignKey(contact => contact.PatientProfileId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

internal sealed class AllergyConfiguration : IEntityTypeConfiguration<Allergy>
{
    public void Configure(EntityTypeBuilder<Allergy> builder)
    {
        builder.ToTable("Allergies");
        builder.HasKey(allergy => allergy.Id);
        builder.Property(allergy => allergy.Name).HasMaxLength(100).IsRequired();
        builder.Property(allergy => allergy.Reaction).HasMaxLength(500);
        builder.Property(allergy => allergy.Severity)
            .HasConversion<string>()
            .HasMaxLength(20);
        builder.HasIndex(allergy => allergy.PatientProfileId);
    }
}

internal sealed class MedicalConditionConfiguration
    : IEntityTypeConfiguration<MedicalCondition>
{
    public void Configure(EntityTypeBuilder<MedicalCondition> builder)
    {
        builder.ToTable("MedicalConditions");
        builder.HasKey(condition => condition.Id);
        builder.Property(condition => condition.Name).HasMaxLength(100).IsRequired();
        builder.Property(condition => condition.Notes).HasMaxLength(500);
        builder.HasIndex(condition => condition.PatientProfileId);
    }
}

internal sealed class MedicationConfiguration : IEntityTypeConfiguration<Medication>
{
    public void Configure(EntityTypeBuilder<Medication> builder)
    {
        builder.ToTable("Medications");
        builder.HasKey(medication => medication.Id);
        builder.Property(medication => medication.Name).HasMaxLength(100).IsRequired();
        builder.Property(medication => medication.Dosage).HasMaxLength(100);
        builder.Property(medication => medication.Frequency).HasMaxLength(100);
        builder.HasIndex(medication => medication.PatientProfileId);
    }
}

internal sealed class EmergencyContactConfiguration
    : IEntityTypeConfiguration<EmergencyContact>
{
    public void Configure(EntityTypeBuilder<EmergencyContact> builder)
    {
        builder.ToTable("EmergencyContacts");
        builder.HasKey(contact => contact.Id);
        builder.Property(contact => contact.Name).HasMaxLength(100).IsRequired();
        builder.Property(contact => contact.Relationship).HasMaxLength(50).IsRequired();
        builder.Property(contact => contact.PhoneNumber).HasMaxLength(16).IsRequired();
        builder.HasIndex(contact => contact.PatientProfileId);
    }
}

internal sealed class ApplicationUserConfiguration
    : IEntityTypeConfiguration<ApplicationUser>
{
    public void Configure(EntityTypeBuilder<ApplicationUser> builder)
    {
        builder.Property(user => user.DisplayName).HasMaxLength(100).IsRequired();
        builder.Property(user => user.CreatedAtUtc).HasPrecision(0);
        builder.Property(user => user.ProfessionalTitle).HasMaxLength(100);
        builder.Property(user => user.HospitalName).HasMaxLength(150);
        builder.Property(user => user.Department).HasMaxLength(100);
        builder.Property(user => user.LicenseNumber).HasMaxLength(80);
        builder.HasIndex(user => user.IsActive);
    }
}
