using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace EmergencySystem.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddClinicalWorkflow : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<string>(
                name: "Action",
                table: "AccessAuditEvents",
                type: "nvarchar(30)",
                maxLength: 30,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(20)",
                oldMaxLength: 20);

            migrationBuilder.CreateTable(
                name: "ClinicalEncounters",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    PatientProfileId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    DoctorUserId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    EmergencyAccessGrantId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ChiefComplaint = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    ClinicalNotes = table.Column<string>(type: "nvarchar(2000)", maxLength: 2000, nullable: false),
                    Disposition = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: true),
                    OccurredAtUtc = table.Column<DateTimeOffset>(type: "datetimeoffset(0)", precision: 0, nullable: false),
                    CreatedAtUtc = table.Column<DateTimeOffset>(type: "datetimeoffset(0)", precision: 0, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ClinicalEncounters", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ClinicalEncounters_AspNetUsers_DoctorUserId",
                        column: x => x.DoctorUserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_ClinicalEncounters_EmergencyAccessGrants_EmergencyAccessGrantId",
                        column: x => x.EmergencyAccessGrantId,
                        principalTable: "EmergencyAccessGrants",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_ClinicalEncounters_PatientProfiles_PatientProfileId",
                        column: x => x.PatientProfileId,
                        principalTable: "PatientProfiles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ClinicalObservations",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ClinicalEncounterId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    TemperatureCelsius = table.Column<decimal>(type: "decimal(4,1)", precision: 4, scale: 1, nullable: true),
                    HeartRateBpm = table.Column<int>(type: "int", nullable: true),
                    SystolicBloodPressure = table.Column<int>(type: "int", nullable: true),
                    DiastolicBloodPressure = table.Column<int>(type: "int", nullable: true),
                    OxygenSaturationPercent = table.Column<int>(type: "int", nullable: true),
                    RespiratoryRatePerMinute = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ClinicalObservations", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ClinicalObservations_ClinicalEncounters_ClinicalEncounterId",
                        column: x => x.ClinicalEncounterId,
                        principalTable: "ClinicalEncounters",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Prescriptions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ClinicalEncounterId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    MedicationName = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Dosage = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Frequency = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Duration = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Instructions = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Prescriptions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Prescriptions_ClinicalEncounters_ClinicalEncounterId",
                        column: x => x.ClinicalEncounterId,
                        principalTable: "ClinicalEncounters",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ClinicalEncounters_DoctorUserId",
                table: "ClinicalEncounters",
                column: "DoctorUserId");

            migrationBuilder.CreateIndex(
                name: "IX_ClinicalEncounters_EmergencyAccessGrantId",
                table: "ClinicalEncounters",
                column: "EmergencyAccessGrantId");

            migrationBuilder.CreateIndex(
                name: "IX_ClinicalEncounters_PatientProfileId_OccurredAtUtc",
                table: "ClinicalEncounters",
                columns: new[] { "PatientProfileId", "OccurredAtUtc" });

            migrationBuilder.CreateIndex(
                name: "IX_ClinicalObservations_ClinicalEncounterId",
                table: "ClinicalObservations",
                column: "ClinicalEncounterId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Prescriptions_ClinicalEncounterId",
                table: "Prescriptions",
                column: "ClinicalEncounterId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ClinicalObservations");

            migrationBuilder.DropTable(
                name: "Prescriptions");

            migrationBuilder.DropTable(
                name: "ClinicalEncounters");

            migrationBuilder.AlterColumn<string>(
                name: "Action",
                table: "AccessAuditEvents",
                type: "nvarchar(20)",
                maxLength: 20,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(30)",
                oldMaxLength: 30);
        }
    }
}
