using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LawyerSys.Infrastructure.Data.Migrations.Identity
{
    /// <inheritdoc />
    public partial class SeedAdminProfileAndPhone : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
DO $$
DECLARE
    admin_user_id text;
    admin_role_id text;
BEGIN
    INSERT INTO "AspNetRoles" ("Id", "Name", "NormalizedName", "ConcurrencyStamp")
    SELECT '9f1f6f8b-8a9e-4dce-b06c-a6d9f08f1001', 'Admin', 'ADMIN', 'fa2eac17-5c17-4cb6-99b1-a6f9c6d45001'
    WHERE NOT EXISTS (SELECT 1 FROM "AspNetRoles" WHERE "NormalizedName" = 'ADMIN');

    INSERT INTO "AspNetRoles" ("Id", "Name", "NormalizedName", "ConcurrencyStamp")
    SELECT '9f1f6f8b-8a9e-4dce-b06c-a6d9f08f1002', 'Employee', 'EMPLOYEE', 'fa2eac17-5c17-4cb6-99b1-a6f9c6d45002'
    WHERE NOT EXISTS (SELECT 1 FROM "AspNetRoles" WHERE "NormalizedName" = 'EMPLOYEE');

    INSERT INTO "AspNetRoles" ("Id", "Name", "NormalizedName", "ConcurrencyStamp")
    SELECT '9f1f6f8b-8a9e-4dce-b06c-a6d9f08f1003', 'Customer', 'CUSTOMER', 'fa2eac17-5c17-4cb6-99b1-a6f9c6d45003'
    WHERE NOT EXISTS (SELECT 1 FROM "AspNetRoles" WHERE "NormalizedName" = 'CUSTOMER');

    SELECT "Id" INTO admin_role_id
    FROM "AspNetRoles"
    WHERE "NormalizedName" = 'ADMIN'
    LIMIT 1;

    SELECT "Id" INTO admin_user_id
    FROM "AspNetUsers"
    WHERE "NormalizedEmail" = 'GERGESBERNABA2@GMAIL.COM'
    LIMIT 1;

    IF admin_user_id IS NULL THEN
        admin_user_id := '78c2e30f-d77a-42dc-89e8-126e5ecb4001';
        INSERT INTO "AspNetUsers" (
            "Id",
            "FullName",
            "RequiresPasswordReset",
            "UserName",
            "NormalizedUserName",
            "Email",
            "NormalizedEmail",
            "EmailConfirmed",
            "PasswordHash",
            "SecurityStamp",
            "ConcurrencyStamp",
            "PhoneNumber",
            "PhoneNumberConfirmed",
            "TwoFactorEnabled",
            "LockoutEnabled",
            "AccessFailedCount"
        )
        VALUES (
            admin_user_id,
            'Gerges Bernaba',
            FALSE,
            'gergesbernaba2@gmail.com',
            'GERGESBERNABA2@GMAIL.COM',
            'gergesbernaba2@gmail.com',
            'GERGESBERNABA2@GMAIL.COM',
            TRUE,
            'AQAAAAIAAYagAAAAEKSC4NYZ/tPXt0tDA0RPldC9W5FW/M1/fnWEtHEQQgBL+g6gMV8GBy82euwfgxzZiw==',
            '3b18d203-a44a-4518-af3c-2d22dcca5001',
            '3b18d203-a44a-4518-af3c-2d22dcca5002',
            '01284612434',
            TRUE,
            FALSE,
            TRUE,
            0
        );
    ELSE
        UPDATE "AspNetUsers"
        SET
            "FullName" = 'Gerges Bernaba',
            "PhoneNumber" = '01284612434',
            "PhoneNumberConfirmed" = TRUE,
            "UserName" = 'gergesbernaba2@gmail.com',
            "NormalizedUserName" = 'GERGESBERNABA2@GMAIL.COM',
            "Email" = 'gergesbernaba2@gmail.com',
            "NormalizedEmail" = 'GERGESBERNABA2@GMAIL.COM',
            "EmailConfirmed" = TRUE,
            "PasswordHash" = 'AQAAAAIAAYagAAAAEKSC4NYZ/tPXt0tDA0RPldC9W5FW/M1/fnWEtHEQQgBL+g6gMV8GBy82euwfgxzZiw==',
            "RequiresPasswordReset" = FALSE
        WHERE "Id" = admin_user_id;
    END IF;

    IF admin_role_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM "AspNetUserRoles"
        WHERE "UserId" = admin_user_id
          AND "RoleId" = admin_role_id
    ) THEN
        INSERT INTO "AspNetUserRoles" ("UserId", "RoleId")
        VALUES (admin_user_id, admin_role_id);
    END IF;
END
$$;
""");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
DELETE FROM "AspNetUserRoles"
WHERE "UserId" IN (
    SELECT "Id" FROM "AspNetUsers" WHERE "NormalizedEmail" = 'GERGESBERNABA2@GMAIL.COM'
);

DELETE FROM "AspNetUsers"
WHERE "NormalizedEmail" = 'GERGESBERNABA2@GMAIL.COM';
""");
        }
    }
}
