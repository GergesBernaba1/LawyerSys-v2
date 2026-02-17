using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LawyerSys.Infrastructure.Data.Migrations.Identity
{
    /// <inheritdoc />
    public partial class SeedIdentityRolesAndAdmin : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
DO $$
DECLARE
    admin_user_id text;
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

    SELECT "Id"
    INTO admin_user_id
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
            "PhoneNumberConfirmed",
            "TwoFactorEnabled",
            "LockoutEnabled",
            "AccessFailedCount"
        )
        VALUES (
            admin_user_id,
            'System Administrator',
            FALSE,
            'gergesbernaba2@gmail.com',
            'GERGESBERNABA2@GMAIL.COM',
            'gergesbernaba2@gmail.com',
            'GERGESBERNABA2@GMAIL.COM',
            TRUE,
            'AQAAAAIAAYagAAAAEKSC4NYZ/tPXt0tDA0RPldC9W5FW/M1/fnWEtHEQQgBL+g6gMV8GBy82euwfgxzZiw==',
            'f590efbe-6d89-4ddb-9618-5dbc7d7d5001',
            'f590efbe-6d89-4ddb-9618-5dbc7d7d5002',
            FALSE,
            FALSE,
            TRUE,
            0
        );
    ELSE
        UPDATE "AspNetUsers"
        SET
            "UserName" = 'gergesbernaba2@gmail.com',
            "NormalizedUserName" = 'GERGESBERNABA2@GMAIL.COM',
            "Email" = 'gergesbernaba2@gmail.com',
            "NormalizedEmail" = 'GERGESBERNABA2@GMAIL.COM',
            "EmailConfirmed" = TRUE,
            "PasswordHash" = 'AQAAAAIAAYagAAAAEKSC4NYZ/tPXt0tDA0RPldC9W5FW/M1/fnWEtHEQQgBL+g6gMV8GBy82euwfgxzZiw==',
            "RequiresPasswordReset" = FALSE
        WHERE "Id" = admin_user_id;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM "AspNetUserRoles"
        WHERE "UserId" = admin_user_id
          AND "RoleId" = '9f1f6f8b-8a9e-4dce-b06c-a6d9f08f1001'
    ) THEN
        INSERT INTO "AspNetUserRoles" ("UserId", "RoleId")
        VALUES (admin_user_id, '9f1f6f8b-8a9e-4dce-b06c-a6d9f08f1001');
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
WHERE "RoleId" IN (
    '9f1f6f8b-8a9e-4dce-b06c-a6d9f08f1001',
    '9f1f6f8b-8a9e-4dce-b06c-a6d9f08f1002',
    '9f1f6f8b-8a9e-4dce-b06c-a6d9f08f1003'
);

DELETE FROM "AspNetUsers"
WHERE "NormalizedEmail" = 'GERGESBERNABA2@GMAIL.COM';

DELETE FROM "AspNetRoles"
WHERE "Id" IN (
    '9f1f6f8b-8a9e-4dce-b06c-a6d9f08f1001',
    '9f1f6f8b-8a9e-4dce-b06c-a6d9f08f1002',
    '9f1f6f8b-8a9e-4dce-b06c-a6d9f08f1003'
);
""");
        }
    }
}
