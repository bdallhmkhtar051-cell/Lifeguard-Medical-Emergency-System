using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace EmergencySystem.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddMedicalQrAccess : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "MedicalQrTokens",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    PatientProfileId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    TokenHash = table.Column<string>(type: "nvarchar(64)", maxLength: 64, nullable: false),
                    CreatedAtUtc = table.Column<DateTimeOffset>(type: "datetimeoffset(0)", precision: 0, nullable: false),
                    ExpiresAtUtc = table.Column<DateTimeOffset>(type: "datetimeoffset(0)", precision: 0, nullable: false),
                    RedeemedAtUtc = table.Column<DateTimeOffset>(type: "datetimeoffset(0)", precision: 0, nullable: true),
                    RevokedAtUtc = table.Column<DateTimeOffset>(type: "datetimeoffset(0)", precision: 0, nullable: true),
                    RedeemedByDoctorUserId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    EmergencyAccessGrantId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    Version = table.Column<Guid>(type: "uniqueidentifier", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MedicalQrTokens", x => x.Id);
                    table.ForeignKey(
                        name: "FK_MedicalQrTokens_AspNetUsers_RedeemedByDoctorUserId",
                        column: x => x.RedeemedByDoctorUserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_MedicalQrTokens_EmergencyAccessGrants_EmergencyAccessGrantId",
                        column: x => x.EmergencyAccessGrantId,
                        principalTable: "EmergencyAccessGrants",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_MedicalQrTokens_PatientProfiles_PatientProfileId",
                        column: x => x.PatientProfileId,
                        principalTable: "PatientProfiles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_MedicalQrTokens_EmergencyAccessGrantId",
                table: "MedicalQrTokens",
                column: "EmergencyAccessGrantId",
                unique: true,
                filter: "[EmergencyAccessGrantId] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_MedicalQrTokens_PatientProfileId_ExpiresAtUtc",
                table: "MedicalQrTokens",
                columns: new[] { "PatientProfileId", "ExpiresAtUtc" });

            migrationBuilder.CreateIndex(
                name: "IX_MedicalQrTokens_RedeemedByDoctorUserId",
                table: "MedicalQrTokens",
                column: "RedeemedByDoctorUserId");

            migrationBuilder.CreateIndex(
                name: "IX_MedicalQrTokens_TokenHash",
                table: "MedicalQrTokens",
                column: "TokenHash",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "MedicalQrTokens");
        }
    }
}
