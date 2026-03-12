using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace LawyerSys.Infrastructure.Data.Migrations.Identity
{
    /// <inheritdoc />
    public partial class AddLandingPageSettings : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "LandingPageSettings",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    SystemName = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: false),
                    Tagline = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    TaglineAr = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    HeroTitle = table.Column<string>(type: "character varying(250)", maxLength: 250, nullable: false),
                    HeroTitleAr = table.Column<string>(type: "character varying(250)", maxLength: 250, nullable: false),
                    HeroSubtitle = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: false),
                    HeroSubtitleAr = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: false),
                    PrimaryButtonText = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    PrimaryButtonTextAr = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    PrimaryButtonUrl = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: false),
                    SecondaryButtonText = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    SecondaryButtonTextAr = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    SecondaryButtonUrl = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: false),
                    AboutTitle = table.Column<string>(type: "character varying(180)", maxLength: 180, nullable: false),
                    AboutTitleAr = table.Column<string>(type: "character varying(180)", maxLength: 180, nullable: false),
                    AboutDescription = table.Column<string>(type: "character varying(3000)", maxLength: 3000, nullable: false),
                    AboutDescriptionAr = table.Column<string>(type: "character varying(3000)", maxLength: 3000, nullable: false),
                    Feature1Title = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: false),
                    Feature1TitleAr = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: false),
                    Feature1Description = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: false),
                    Feature1DescriptionAr = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: false),
                    Feature2Title = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: false),
                    Feature2TitleAr = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: false),
                    Feature2Description = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: false),
                    Feature2DescriptionAr = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: false),
                    Feature3Title = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: false),
                    Feature3TitleAr = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: false),
                    Feature3Description = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: false),
                    Feature3DescriptionAr = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: false),
                    ContactEmail = table.Column<string>(type: "character varying(256)", maxLength: 256, nullable: false),
                    ContactPhone = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LandingPageSettings", x => x.Id);
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "LandingPageSettings");
        }
    }
}
