using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LawyerSys.Infrastructure.Data.Migrations.Identity
{
    [DbContext(typeof(ApplicationDbContext))]
    [Migration("20260311193000_AddArabicNamesToLocations")]
    public class AddArabicNamesToLocations : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "NameAr",
                table: "Countries",
                type: "character varying(100)",
                maxLength: 100,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "NameAr",
                table: "Cities",
                type: "character varying(100)",
                maxLength: 100,
                nullable: false,
                defaultValue: "");

            migrationBuilder.Sql("""
UPDATE "Countries" SET "NameAr" = 'مصر' WHERE "Id" = 1;
UPDATE "Countries" SET "NameAr" = 'السعودية' WHERE "Id" = 2;
UPDATE "Countries" SET "NameAr" = 'الإمارات' WHERE "Id" = 3;
UPDATE "Countries" SET "NameAr" = 'الكويت' WHERE "Id" = 4;
UPDATE "Countries" SET "NameAr" = 'قطر' WHERE "Id" = 5;
UPDATE "Countries" SET "NameAr" = 'البحرين' WHERE "Id" = 6;
UPDATE "Countries" SET "NameAr" = 'عمان' WHERE "Id" = 7;
UPDATE "Countries" SET "NameAr" = 'الأردن' WHERE "Id" = 8;

UPDATE "Cities" SET "NameAr" = 'القاهرة' WHERE "Id" = 1;
UPDATE "Cities" SET "NameAr" = 'الإسكندرية' WHERE "Id" = 2;
UPDATE "Cities" SET "NameAr" = 'الجيزة' WHERE "Id" = 3;
UPDATE "Cities" SET "NameAr" = 'شبرا الخيمة' WHERE "Id" = 4;
UPDATE "Cities" SET "NameAr" = 'بورسعيد' WHERE "Id" = 5;
UPDATE "Cities" SET "NameAr" = 'السويس' WHERE "Id" = 6;
UPDATE "Cities" SET "NameAr" = 'الأقصر' WHERE "Id" = 7;
UPDATE "Cities" SET "NameAr" = 'المنصورة' WHERE "Id" = 8;
UPDATE "Cities" SET "NameAr" = 'طنطا' WHERE "Id" = 9;
UPDATE "Cities" SET "NameAr" = 'أسيوط' WHERE "Id" = 10;
UPDATE "Cities" SET "NameAr" = 'الإسماعيلية' WHERE "Id" = 11;
UPDATE "Cities" SET "NameAr" = 'الفيوم' WHERE "Id" = 12;
UPDATE "Cities" SET "NameAr" = 'الزقازيق' WHERE "Id" = 13;
UPDATE "Cities" SET "NameAr" = 'أسوان' WHERE "Id" = 14;
UPDATE "Cities" SET "NameAr" = 'دمياط' WHERE "Id" = 15;
UPDATE "Cities" SET "NameAr" = 'المنيا' WHERE "Id" = 16;
UPDATE "Cities" SET "NameAr" = 'دمنهور' WHERE "Id" = 17;
UPDATE "Cities" SET "NameAr" = 'بني سويف' WHERE "Id" = 18;
UPDATE "Cities" SET "NameAr" = 'العريش' WHERE "Id" = 19;
UPDATE "Cities" SET "NameAr" = 'سوهاج' WHERE "Id" = 20;
UPDATE "Cities" SET "NameAr" = 'الغردقة' WHERE "Id" = 21;
UPDATE "Cities" SET "NameAr" = 'قنا' WHERE "Id" = 22;
UPDATE "Cities" SET "NameAr" = 'كفر الشيخ' WHERE "Id" = 23;
UPDATE "Cities" SET "NameAr" = 'ملوي' WHERE "Id" = 24;
UPDATE "Cities" SET "NameAr" = 'العاشر من رمضان' WHERE "Id" = 25;
UPDATE "Cities" SET "NameAr" = 'المحلة الكبرى' WHERE "Id" = 26;
UPDATE "Cities" SET "NameAr" = 'بنها' WHERE "Id" = 27;
UPDATE "Cities" SET "NameAr" = 'شبين الكوم' WHERE "Id" = 28;
UPDATE "Cities" SET "NameAr" = 'منوف' WHERE "Id" = 29;
UPDATE "Cities" SET "NameAr" = 'الرياض' WHERE "Id" = 30;
UPDATE "Cities" SET "NameAr" = 'جدة' WHERE "Id" = 31;
UPDATE "Cities" SET "NameAr" = 'الدمام' WHERE "Id" = 32;
UPDATE "Cities" SET "NameAr" = 'دبي' WHERE "Id" = 33;
UPDATE "Cities" SET "NameAr" = 'أبوظبي' WHERE "Id" = 34;
UPDATE "Cities" SET "NameAr" = 'الشارقة' WHERE "Id" = 35;
UPDATE "Cities" SET "NameAr" = 'مدينة الكويت' WHERE "Id" = 36;
UPDATE "Cities" SET "NameAr" = 'حولي' WHERE "Id" = 37;
UPDATE "Cities" SET "NameAr" = 'الأحمدي' WHERE "Id" = 38;
UPDATE "Cities" SET "NameAr" = 'الدوحة' WHERE "Id" = 39;
UPDATE "Cities" SET "NameAr" = 'الريان' WHERE "Id" = 40;
UPDATE "Cities" SET "NameAr" = 'الوكرة' WHERE "Id" = 41;
UPDATE "Cities" SET "NameAr" = 'المنامة' WHERE "Id" = 42;
UPDATE "Cities" SET "NameAr" = 'الرفاع' WHERE "Id" = 43;
UPDATE "Cities" SET "NameAr" = 'المحرق' WHERE "Id" = 44;
UPDATE "Cities" SET "NameAr" = 'مسقط' WHERE "Id" = 45;
UPDATE "Cities" SET "NameAr" = 'صلالة' WHERE "Id" = 46;
UPDATE "Cities" SET "NameAr" = 'صحار' WHERE "Id" = 47;
UPDATE "Cities" SET "NameAr" = 'عمان' WHERE "Id" = 48;
UPDATE "Cities" SET "NameAr" = 'الزرقاء' WHERE "Id" = 49;
UPDATE "Cities" SET "NameAr" = 'إربد' WHERE "Id" = 50;
""");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "NameAr",
                table: "Countries");

            migrationBuilder.DropColumn(
                name: "NameAr",
                table: "Cities");
        }
    }
}
