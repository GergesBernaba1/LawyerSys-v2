using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LawyerSys.Infrastructure.Data.Migrations.Identity
{
    [DbContext(typeof(ApplicationDbContext))]
    [Migration("20260311183500_SeedAdditionalCountryCities")]
    public class SeedAdditionalCountryCities : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
INSERT INTO "Cities" ("Id", "CountryId", "Name") VALUES
    (30, 2, 'Riyadh'),
    (31, 2, 'Jeddah'),
    (32, 2, 'Dammam'),
    (33, 3, 'Dubai'),
    (34, 3, 'Abu Dhabi'),
    (35, 3, 'Sharjah'),
    (36, 4, 'Kuwait City'),
    (37, 4, 'Hawalli'),
    (38, 4, 'Al Ahmadi'),
    (39, 5, 'Doha'),
    (40, 5, 'Al Rayyan'),
    (41, 5, 'Al Wakrah'),
    (42, 6, 'Manama'),
    (43, 6, 'Riffa'),
    (44, 6, 'Muharraq'),
    (45, 7, 'Muscat'),
    (46, 7, 'Salalah'),
    (47, 7, 'Sohar'),
    (48, 8, 'Amman'),
    (49, 8, 'Zarqa'),
    (50, 8, 'Irbid')
ON CONFLICT ("Id") DO NOTHING;

SELECT setval(
    pg_get_serial_sequence('"Cities"', 'Id'),
    COALESCE((SELECT MAX("Id") FROM "Cities"), 1),
    true);
""");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
DELETE FROM "Cities"
WHERE "Id" BETWEEN 30 AND 50;

SELECT setval(
    pg_get_serial_sequence('"Cities"', 'Id'),
    COALESCE((SELECT MAX("Id") FROM "Cities"), 1),
    true);
""");
        }
    }
}
