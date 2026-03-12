using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace LawyerSys.Infrastructure.Data.Migrations.Identity
{
    /// <inheritdoc />
    public partial class AddTenantSubscriptionBilling : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ContactEmail",
                table: "Tenants",
                type: "character varying(256)",
                maxLength: 256,
                nullable: false,
                defaultValue: "");

            migrationBuilder.CreateTable(
                name: "SubscriptionPackages",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Name = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    NameAr = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    Description = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: false),
                    DescriptionAr = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: false),
                    OfficeSize = table.Column<int>(type: "integer", nullable: false),
                    BillingCycle = table.Column<int>(type: "integer", nullable: false),
                    Price = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    Currency = table.Column<string>(type: "character varying(12)", maxLength: 12, nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    DisplayOrder = table.Column<int>(type: "integer", nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SubscriptionPackages", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "TenantSubscriptions",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    TenantId = table.Column<int>(type: "integer", nullable: false),
                    SubscriptionPackageId = table.Column<int>(type: "integer", nullable: false),
                    Status = table.Column<int>(type: "integer", nullable: false),
                    StartDateUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    EndDateUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    NextBillingDateUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TenantSubscriptions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TenantSubscriptions_SubscriptionPackages_SubscriptionPackag~",
                        column: x => x.SubscriptionPackageId,
                        principalTable: "SubscriptionPackages",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_TenantSubscriptions_Tenants_TenantId",
                        column: x => x.TenantId,
                        principalTable: "Tenants",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "TenantBillingTransactions",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    TenantId = table.Column<int>(type: "integer", nullable: false),
                    TenantSubscriptionId = table.Column<int>(type: "integer", nullable: false),
                    SubscriptionPackageId = table.Column<int>(type: "integer", nullable: false),
                    Status = table.Column<int>(type: "integer", nullable: false),
                    BillingCycle = table.Column<int>(type: "integer", nullable: false),
                    Amount = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    Currency = table.Column<string>(type: "character varying(12)", maxLength: 12, nullable: false),
                    PeriodStartUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    PeriodEndUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    DueDateUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    PaidAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    Reference = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: false),
                    Notes = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Reminder7DaysSentAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    Reminder3DaysSentAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    Reminder1DaySentAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ExpiryNoticeSentAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TenantBillingTransactions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TenantBillingTransactions_SubscriptionPackages_Subscription~",
                        column: x => x.SubscriptionPackageId,
                        principalTable: "SubscriptionPackages",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_TenantBillingTransactions_TenantSubscriptions_TenantSubscri~",
                        column: x => x.TenantSubscriptionId,
                        principalTable: "TenantSubscriptions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_TenantBillingTransactions_Tenants_TenantId",
                        column: x => x.TenantId,
                        principalTable: "Tenants",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_SubscriptionPackages_IsActive_DisplayOrder",
                table: "SubscriptionPackages",
                columns: new[] { "IsActive", "DisplayOrder" });

            migrationBuilder.CreateIndex(
                name: "IX_SubscriptionPackages_OfficeSize_BillingCycle",
                table: "SubscriptionPackages",
                columns: new[] { "OfficeSize", "BillingCycle" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_TenantBillingTransactions_Status_DueDateUtc",
                table: "TenantBillingTransactions",
                columns: new[] { "Status", "DueDateUtc" });

            migrationBuilder.CreateIndex(
                name: "IX_TenantBillingTransactions_SubscriptionPackageId",
                table: "TenantBillingTransactions",
                column: "SubscriptionPackageId");

            migrationBuilder.CreateIndex(
                name: "IX_TenantBillingTransactions_TenantId",
                table: "TenantBillingTransactions",
                column: "TenantId");

            migrationBuilder.CreateIndex(
                name: "IX_TenantBillingTransactions_TenantSubscriptionId",
                table: "TenantBillingTransactions",
                column: "TenantSubscriptionId");

            migrationBuilder.CreateIndex(
                name: "IX_TenantSubscriptions_SubscriptionPackageId",
                table: "TenantSubscriptions",
                column: "SubscriptionPackageId");

            migrationBuilder.CreateIndex(
                name: "IX_TenantSubscriptions_TenantId",
                table: "TenantSubscriptions",
                column: "TenantId");

            migrationBuilder.CreateIndex(
                name: "IX_TenantSubscriptions_TenantId_Status",
                table: "TenantSubscriptions",
                columns: new[] { "TenantId", "Status" });

            migrationBuilder.Sql(@"
UPDATE ""Tenants"" AS t
SET ""ContactEmail"" = COALESCE(NULLIF(BTRIM(t.""ContactEmail""), ''), (
    SELECT u.""Email""
    FROM ""AspNetUsers"" AS u
    WHERE u.""TenantId"" = t.""Id"" AND u.""Email"" IS NOT NULL AND BTRIM(u.""Email"") <> ''
    ORDER BY u.""Id""
    LIMIT 1
), '')
WHERE COALESCE(BTRIM(t.""ContactEmail""), '') = '';
");

            migrationBuilder.Sql(@"
INSERT INTO ""SubscriptionPackages"" (
    ""Id"",
    ""Name"",
    ""NameAr"",
    ""Description"",
    ""DescriptionAr"",
    ""OfficeSize"",
    ""BillingCycle"",
    ""Price"",
    ""Currency"",
    ""IsActive"",
    ""DisplayOrder"",
    ""CreatedAtUtc"",
    ""UpdatedAtUtc"")
VALUES
    (1, 'Small Office Monthly', 'مكتب صغير شهري', 'Monthly package for small legal offices.', 'باقة شهرية للمكاتب القانونية الصغيرة.', 1, 1, 99.00, 'SAR', TRUE, 1, NOW(), NOW()),
    (2, 'Small Office Annual', 'مكتب صغير سنوي', 'Annual package for small legal offices.', 'باقة سنوية للمكاتب القانونية الصغيرة.', 1, 2, 999.00, 'SAR', TRUE, 2, NOW(), NOW()),
    (3, 'Medium Office Monthly', 'مكتب متوسط شهري', 'Monthly package for medium legal offices.', 'باقة شهرية للمكاتب القانونية المتوسطة.', 2, 1, 199.00, 'SAR', TRUE, 3, NOW(), NOW()),
    (4, 'Medium Office Annual', 'مكتب متوسط سنوي', 'Annual package for medium legal offices.', 'باقة سنوية للمكاتب القانونية المتوسطة.', 2, 2, 1999.00, 'SAR', TRUE, 4, NOW(), NOW());

SELECT setval(
    pg_get_serial_sequence('""SubscriptionPackages""', 'Id'),
    COALESCE((SELECT MAX(""Id"") FROM ""SubscriptionPackages""), 1),
    TRUE
);
");

            migrationBuilder.Sql(@"
INSERT INTO ""TenantSubscriptions"" (
    ""TenantId"",
    ""SubscriptionPackageId"",
    ""Status"",
    ""StartDateUtc"",
    ""EndDateUtc"",
    ""NextBillingDateUtc"",
    ""CreatedAtUtc"",
    ""UpdatedAtUtc"")
SELECT
    t.""Id"",
    1,
    CASE WHEN t.""IsActive"" THEN 2 ELSE 1 END,
    NOW(),
    NOW() + INTERVAL '1 month',
    NOW() + INTERVAL '1 month',
    NOW(),
    NOW()
FROM ""Tenants"" AS t
LEFT JOIN ""TenantSubscriptions"" AS s ON s.""TenantId"" = t.""Id""
WHERE s.""Id"" IS NULL;
");

            migrationBuilder.Sql(@"
INSERT INTO ""TenantBillingTransactions"" (
    ""TenantId"",
    ""TenantSubscriptionId"",
    ""SubscriptionPackageId"",
    ""Status"",
    ""BillingCycle"",
    ""Amount"",
    ""Currency"",
    ""PeriodStartUtc"",
    ""PeriodEndUtc"",
    ""DueDateUtc"",
    ""PaidAtUtc"",
    ""Reference"",
    ""Notes"",
    ""CreatedAtUtc"",
    ""UpdatedAtUtc"")
SELECT
    s.""TenantId"",
    s.""Id"",
    s.""SubscriptionPackageId"",
    2,
    1,
    99.00,
    'SAR',
    s.""StartDateUtc"",
    s.""EndDateUtc"",
    s.""StartDateUtc"",
    s.""StartDateUtc"",
    'BACKFILL',
    'Backfilled current subscription period',
    NOW(),
    NOW()
FROM ""TenantSubscriptions"" AS s
LEFT JOIN ""TenantBillingTransactions"" AS t ON t.""TenantSubscriptionId"" = s.""Id""
WHERE t.""Id"" IS NULL;
");

            migrationBuilder.Sql(@"
INSERT INTO ""TenantBillingTransactions"" (
    ""TenantId"",
    ""TenantSubscriptionId"",
    ""SubscriptionPackageId"",
    ""Status"",
    ""BillingCycle"",
    ""Amount"",
    ""Currency"",
    ""PeriodStartUtc"",
    ""PeriodEndUtc"",
    ""DueDateUtc"",
    ""Reference"",
    ""Notes"",
    ""CreatedAtUtc"",
    ""UpdatedAtUtc"")
SELECT
    s.""TenantId"",
    s.""Id"",
    s.""SubscriptionPackageId"",
    1,
    1,
    99.00,
    'SAR',
    s.""EndDateUtc"",
    s.""EndDateUtc"" + INTERVAL '1 month',
    s.""EndDateUtc"",
    '',
    'Backfilled upcoming renewal',
    NOW(),
    NOW()
FROM ""TenantSubscriptions"" AS s
WHERE NOT EXISTS (
    SELECT 1
    FROM ""TenantBillingTransactions"" AS t
    WHERE t.""TenantSubscriptionId"" = s.""Id"" AND t.""Status"" = 1 AND t.""PeriodStartUtc"" >= s.""EndDateUtc""
);
");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "TenantBillingTransactions");

            migrationBuilder.DropTable(
                name: "TenantSubscriptions");

            migrationBuilder.DropTable(
                name: "SubscriptionPackages");

            migrationBuilder.DropColumn(
                name: "ContactEmail",
                table: "Tenants");
        }
    }
}
