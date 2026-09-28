using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace EmergencySystem.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddPermanentEmergencyMedicalId : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "EmergencyMedicalId",
                table: "PatientProfiles",
                type: "uniqueidentifier",
                nullable: true);

            // Every existing patient receives a different opaque identifier.
            // NEWID is evaluated per row by SQL Server, avoiding a shared
            // default value before the unique index is created.
            migrationBuilder.Sql(
                "UPDATE PatientProfiles SET EmergencyMedicalId = NEWID() " +
                "WHERE EmergencyMedicalId IS NULL;");

            migrationBuilder.AlterColumn<Guid>(
                name: "EmergencyMedicalId",
                table: "PatientProfiles",
                type: "uniqueidentifier",
                nullable: false,
                oldClrType: typeof(Guid),
                oldType: "uniqueidentifier",
                oldNullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_PatientProfiles_EmergencyMedicalId",
                table: "PatientProfiles",
                column: "EmergencyMedicalId",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_PatientProfiles_EmergencyMedicalId",
                table: "PatientProfiles");

            migrationBuilder.DropColumn(
                name: "EmergencyMedicalId",
                table: "PatientProfiles");
        }
    }
}
