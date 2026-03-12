using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace LawyerSys.Infrastructure.Data.Migrations.Identity
{
    /// <inheritdoc />
    public partial class AddDemoRequestsAndGroupedPackageFeatures : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Feature1",
                table: "SubscriptionPackages",
                type: "character varying(300)",
                maxLength: 300,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "Feature1Ar",
                table: "SubscriptionPackages",
                type: "character varying(300)",
                maxLength: 300,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "Feature2",
                table: "SubscriptionPackages",
                type: "character varying(300)",
                maxLength: 300,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "Feature2Ar",
                table: "SubscriptionPackages",
                type: "character varying(300)",
                maxLength: 300,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "Feature3",
                table: "SubscriptionPackages",
                type: "character varying(300)",
                maxLength: 300,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "Feature3Ar",
                table: "SubscriptionPackages",
                type: "character varying(300)",
                maxLength: 300,
                nullable: false,
                defaultValue: "");

            migrationBuilder.CreateTable(
                name: "DemoRequests",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    FullName = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Email = table.Column<string>(type: "character varying(256)", maxLength: 256, nullable: false),
                    PhoneNumber = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    OfficeName = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Notes = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: false),
                    Status = table.Column<int>(type: "integer", nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ReviewedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ReviewedByUserId = table.Column<string>(type: "character varying(450)", maxLength: 450, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DemoRequests", x => x.Id);
                    table.ForeignKey(
                        name: "FK_DemoRequests_AspNetUsers_ReviewedByUserId",
                        column: x => x.ReviewedByUserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.Sql("""
                UPDATE "SubscriptionPackages"
                SET
                    "Name" = 'Small Office',
                    "NameAr" = 'المكتب الصغير',
                    "Description" = 'Essential operating package for small law offices.',
                    "DescriptionAr" = 'باقة تشغيل أساسية للمكاتب القانونية الصغيرة.',
                    "Feature1" = 'Case and customer management',
                    "Feature1Ar" = 'إدارة القضايا والعملاء',
                    "Feature2" = 'Courts, hearings, and documents',
                    "Feature2Ar" = 'المحاكم والجلسات والمستندات',
                    "Feature3" = 'Billing, notifications, and reporting',
                    "Feature3Ar" = 'الفوترة والإشعارات والتقارير'
                WHERE "OfficeSize" = 1;

                UPDATE "SubscriptionPackages"
                SET
                    "Name" = 'Medium Office',
                    "NameAr" = 'المكتب المتوسط',
                    "Description" = 'Expanded package for growing legal offices with broader coordination needs.',
                    "DescriptionAr" = 'باقة موسعة للمكاتب القانونية المتنامية ذات احتياج أكبر للتنسيق.',
                    "Feature1" = 'Everything in Small Office',
                    "Feature1Ar" = 'كل ما في باقة المكتب الصغير',
                    "Feature2" = 'Higher operational capacity across teams',
                    "Feature2Ar" = 'سعة تشغيلية أكبر عبر فرق العمل',
                    "Feature3" = 'Better control for billing and office growth',
                    "Feature3Ar" = 'تحكم أفضل في الفوترة ونمو المكتب'
                WHERE "OfficeSize" = 2;
                """);

            migrationBuilder.CreateIndex(
                name: "IX_DemoRequests_ReviewedByUserId",
                table: "DemoRequests",
                column: "ReviewedByUserId");

            migrationBuilder.CreateIndex(
                name: "IX_DemoRequests_Status_CreatedAtUtc",
                table: "DemoRequests",
                columns: new[] { "Status", "CreatedAtUtc" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "DemoRequests");

            migrationBuilder.DropColumn(
                name: "Feature1",
                table: "SubscriptionPackages");

            migrationBuilder.DropColumn(
                name: "Feature1Ar",
                table: "SubscriptionPackages");

            migrationBuilder.DropColumn(
                name: "Feature2",
                table: "SubscriptionPackages");

            migrationBuilder.DropColumn(
                name: "Feature2Ar",
                table: "SubscriptionPackages");

            migrationBuilder.DropColumn(
                name: "Feature3",
                table: "SubscriptionPackages");

            migrationBuilder.DropColumn(
                name: "Feature3Ar",
                table: "SubscriptionPackages");
        }
    }
}
