using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace EmergencySystem.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddEmergencyAccess : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "EmergencyAccessGrants",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    PatientProfileId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    DoctorUserId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    GrantedAtUtc = table.Column<DateTimeOffset>(type: "datetimeoffset(0)", precision: 0, nullable: false),
                    ExpiresAtUtc = table.Column<DateTimeOffset>(type: "datetimeoffset(0)", precision: 0, nullable: false),
                    RevokedAtUtc = table.Column<DateTimeOffset>(type: "datetimeoffset(0)", precision: 0, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_EmergencyAccessGrants", x => x.Id);
                    table.ForeignKey(
                        name: "FK_EmergencyAccessGrants_AspNetUsers_DoctorUserId",
                        column: x => x.DoctorUserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_EmergencyAccessGrants_PatientProfiles_PatientProfileId",
                        column: x => x.PatientProfileId,
                        principalTable: "PatientProfiles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "AccessAuditEvents",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    EmergencyAccessGrantId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ActorUserId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Action = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    OccurredAtUtc = table.Column<DateTimeOffset>(type: "datetimeoffset(0)", precision: 0, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AccessAuditEvents", x => x.Id);
                    table.ForeignKey(
                        name: "FK_AccessAuditEvents_AspNetUsers_ActorUserId",
                        column: x => x.ActorUserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_AccessAuditEvents_EmergencyAccessGrants_EmergencyAccessGrantId",
                        column: x => x.EmergencyAccessGrantId,
                        principalTable: "EmergencyAccessGrants",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_AccessAuditEvents_ActorUserId",
                table: "AccessAuditEvents",
                column: "ActorUserId");

            migrationBuilder.CreateIndex(
                name: "IX_AccessAuditEvents_EmergencyAccessGrantId_OccurredAtUtc",
                table: "AccessAuditEvents",
                columns: new[] { "EmergencyAccessGrantId", "OccurredAtUtc" });

            migrationBuilder.CreateIndex(
                name: "IX_EmergencyAccessGrants_DoctorUserId",
                table: "EmergencyAccessGrants",
                column: "DoctorUserId");

            migrationBuilder.CreateIndex(
                name: "IX_EmergencyAccessGrants_ExpiresAtUtc",
                table: "EmergencyAccessGrants",
                column: "ExpiresAtUtc");

            migrationBuilder.CreateIndex(
                name: "IX_EmergencyAccessGrants_PatientProfileId_DoctorUserId",
                table: "EmergencyAccessGrants",
                columns: new[] { "PatientProfileId", "DoctorUserId" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "AccessAuditEvents");

            migrationBuilder.DropTable(
                name: "EmergencyAccessGrants");
        }
    }
}
