using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace EmergencySystem.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddBreakGlassAccess : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "AccessType",
                table: "EmergencyAccessGrants",
                type: "nvarchar(20)",
                maxLength: 20,
                nullable: false,
                // All grants created before this migration were patient-consented.
                defaultValue: "Consented");

            migrationBuilder.AddColumn<string>(
                name: "EmergencyReason",
                table: "EmergencyAccessGrants",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "AccessType",
                table: "EmergencyAccessGrants");

            migrationBuilder.DropColumn(
                name: "EmergencyReason",
                table: "EmergencyAccessGrants");
        }
    }
}
