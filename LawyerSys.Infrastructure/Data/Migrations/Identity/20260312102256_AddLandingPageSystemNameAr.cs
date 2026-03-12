using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LawyerSys.Infrastructure.Data.Migrations.Identity
{
    /// <inheritdoc />
    public partial class AddLandingPageSystemNameAr : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "SystemNameAr",
                table: "LandingPageSettings",
                type: "character varying(150)",
                maxLength: 150,
                nullable: false,
                defaultValue: "");

            migrationBuilder.Sql("""
                UPDATE "LandingPageSettings"
                SET "SystemNameAr" = CASE
                    WHEN BTRIM(COALESCE("SystemNameAr", '')) = '' THEN 'قضايا'
                    ELSE "SystemNameAr"
                END;
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "SystemNameAr",
                table: "LandingPageSettings");
        }
    }
}
