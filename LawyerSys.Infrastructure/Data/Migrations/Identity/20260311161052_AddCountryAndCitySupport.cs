using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace LawyerSys.Infrastructure.Data.Migrations.Identity
{
    /// <inheritdoc />
    public partial class AddCountryAndCitySupport : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "CountryId",
                table: "AspNetUsers",
                type: "integer",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "Countries",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Name = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Countries", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Cities",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Name = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    CountryId = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Cities", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Cities_Countries_CountryId",
                        column: x => x.CountryId,
                        principalTable: "Countries",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.InsertData(
                table: "Countries",
                columns: new[] { "Id", "Name" },
                values: new object[,]
                {
                    { 1, "Egypt" },
                    { 2, "Saudi Arabia" },
                    { 3, "United Arab Emirates" },
                    { 4, "Kuwait" },
                    { 5, "Qatar" },
                    { 6, "Bahrain" },
                    { 7, "Oman" },
                    { 8, "Jordan" }
                });

            migrationBuilder.InsertData(
                table: "Cities",
                columns: new[] { "Id", "CountryId", "Name" },
                values: new object[,]
                {
                    { 1, 1, "Cairo" },
                    { 2, 1, "Alexandria" },
                    { 3, 1, "Giza" },
                    { 4, 1, "Shubra El Kheima" },
                    { 5, 1, "Port Said" },
                    { 6, 1, "Suez" },
                    { 7, 1, "Luxor" },
                    { 8, 1, "Mansoura" },
                    { 9, 1, "Tanta" },
                    { 10, 1, "Asyut" },
                    { 11, 1, "Ismailia" },
                    { 12, 1, "Faiyum" },
                    { 13, 1, "Zagazig" },
                    { 14, 1, "Aswan" },
                    { 15, 1, "Damietta" },
                    { 16, 1, "Minya" },
                    { 17, 1, "Damanhur" },
                    { 18, 1, "Beni Suef" },
                    { 19, 1, "Arish" },
                    { 20, 1, "Sohag" },
                    { 21, 1, "Hurghada" },
                    { 22, 1, "Qena" },
                    { 23, 1, "Kafr El Sheikh" },
                    { 24, 1, "Mallawi" },
                    { 25, 1, "10th of Ramadan" },
                    { 26, 1, "El Mahalla El Kubra" },
                    { 27, 1, "Banha" },
                    { 28, 1, "Shebin El Kom" },
                    { 29, 1, "Minuf" }
                });

            migrationBuilder.CreateIndex(
                name: "IX_AspNetUsers_CountryId",
                table: "AspNetUsers",
                column: "CountryId");

            migrationBuilder.CreateIndex(
                name: "IX_Cities_CountryId_Name",
                table: "Cities",
                columns: new[] { "CountryId", "Name" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Countries_Name",
                table: "Countries",
                column: "Name",
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_AspNetUsers_Countries_CountryId",
                table: "AspNetUsers",
                column: "CountryId",
                principalTable: "Countries",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.Sql("""
SELECT setval(
    pg_get_serial_sequence('"Countries"', 'Id'),
    COALESCE((SELECT MAX("Id") FROM "Countries"), 1),
    true);

SELECT setval(
    pg_get_serial_sequence('"Cities"', 'Id'),
    COALESCE((SELECT MAX("Id") FROM "Cities"), 1),
    true);
""");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_AspNetUsers_Countries_CountryId",
                table: "AspNetUsers");

            migrationBuilder.DropTable(
                name: "Cities");

            migrationBuilder.DropTable(
                name: "Countries");

            migrationBuilder.DropIndex(
                name: "IX_AspNetUsers_CountryId",
                table: "AspNetUsers");

            migrationBuilder.DropColumn(
                name: "CountryId",
                table: "AspNetUsers");
        }
    }
}
