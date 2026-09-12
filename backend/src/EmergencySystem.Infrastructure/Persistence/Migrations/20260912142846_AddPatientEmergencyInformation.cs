using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace EmergencySystem.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddPatientEmergencyInformation : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "FirstResponderNotes",
                table: "PatientProfiles",
                type: "nvarchar(1000)",
                maxLength: 1000,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "InsurancePolicyNumber",
                table: "PatientProfiles",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "InsuranceProvider",
                table: "PatientProfiles",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "OrganDonorStatus",
                table: "PatientProfiles",
                type: "nvarchar(20)",
                maxLength: 20,
                nullable: false,
                defaultValue: "Unknown");

            migrationBuilder.AddColumn<string>(
                name: "PrimaryPhysicianName",
                table: "PatientProfiles",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PrimaryPhysicianPhone",
                table: "PatientProfiles",
                type: "nvarchar(16)",
                maxLength: 16,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "FirstResponderNotes",
                table: "PatientProfiles");

            migrationBuilder.DropColumn(
                name: "InsurancePolicyNumber",
                table: "PatientProfiles");

            migrationBuilder.DropColumn(
                name: "InsuranceProvider",
                table: "PatientProfiles");

            migrationBuilder.DropColumn(
                name: "OrganDonorStatus",
                table: "PatientProfiles");

            migrationBuilder.DropColumn(
                name: "PrimaryPhysicianName",
                table: "PatientProfiles");

            migrationBuilder.DropColumn(
                name: "PrimaryPhysicianPhone",
                table: "PatientProfiles");
        }
    }
}
