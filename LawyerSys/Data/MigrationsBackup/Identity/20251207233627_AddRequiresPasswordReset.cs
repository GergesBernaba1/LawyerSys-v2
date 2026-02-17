using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LawyerSys.Data.Migrations.Identity
{
    /// <inheritdoc />
    public partial class AddRequiresPasswordReset : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "RequiresPasswordReset",
                table: "AspNetUsers",
                type: "bit",
                nullable: false,
                defaultValue: false);

            // Copy existing Users into AspNetUsers and mark them as requiring password reset
            migrationBuilder.Sql(@"
                INSERT INTO AspNetUsers (Id, UserName, NormalizedUserName, Email, NormalizedEmail, EmailConfirmed, PasswordHash, SecurityStamp, ConcurrencyStamp, RequiresPasswordReset, LockoutEnabled, AccessFailedCount)
                SELECT NEWID(), User_Name, UPPER(User_Name), User_Name + '@local', UPPER(User_Name + '@local'), 0, NULL, NEWID(), NEWID(), 1, 0, 0
                FROM Users
                WHERE User_Name IS NOT NULL
            ");

        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // Remove seed entries we created (best effort: looks for emails ending with @local)
            migrationBuilder.Sql("DELETE FROM AspNetUsers WHERE RequiresPasswordReset = 1 AND Email LIKE '%@local'");

            migrationBuilder.DropColumn(
                name: "RequiresPasswordReset",
                table: "AspNetUsers");

        }
    }
}
