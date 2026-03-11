using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LawyerSys.Infrastructure.Data.Migrations.Identity
{
    /// <inheritdoc />
    public partial class AddCityOwnershipToLocations : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "CreatedByUserId",
                table: "Cities",
                type: "character varying(450)",
                maxLength: 450,
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "TenantId",
                table: "Cities",
                type: "integer",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Cities_CreatedByUserId",
                table: "Cities",
                column: "CreatedByUserId");

            migrationBuilder.CreateIndex(
                name: "IX_Cities_TenantId",
                table: "Cities",
                column: "TenantId");

            migrationBuilder.AddForeignKey(
                name: "FK_Cities_Tenants_TenantId",
                table: "Cities",
                column: "TenantId",
                principalTable: "Tenants",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Cities_Tenants_TenantId",
                table: "Cities");

            migrationBuilder.DropIndex(
                name: "IX_Cities_CreatedByUserId",
                table: "Cities");

            migrationBuilder.DropIndex(
                name: "IX_Cities_TenantId",
                table: "Cities");

            migrationBuilder.DropColumn(
                name: "CreatedByUserId",
                table: "Cities");

            migrationBuilder.DropColumn(
                name: "TenantId",
                table: "Cities");
        }
    }
}
