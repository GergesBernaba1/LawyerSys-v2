using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LawyerSys.Infrastructure.Data.Migrations.Identity
{
    /// <inheritdoc />
    public partial class AddAboutAndContactPublicPages : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "AboutPageDescription",
                table: "LandingPageSettings",
                type: "character varying(4000)",
                maxLength: 4000,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "AboutPageDescriptionAr",
                table: "LandingPageSettings",
                type: "character varying(4000)",
                maxLength: 4000,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "AboutPageMissionDescription",
                table: "LandingPageSettings",
                type: "character varying(2000)",
                maxLength: 2000,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "AboutPageMissionDescriptionAr",
                table: "LandingPageSettings",
                type: "character varying(2000)",
                maxLength: 2000,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "AboutPageMissionTitle",
                table: "LandingPageSettings",
                type: "character varying(180)",
                maxLength: 180,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "AboutPageMissionTitleAr",
                table: "LandingPageSettings",
                type: "character varying(180)",
                maxLength: 180,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "AboutPageSubtitle",
                table: "LandingPageSettings",
                type: "character varying(500)",
                maxLength: 500,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "AboutPageSubtitleAr",
                table: "LandingPageSettings",
                type: "character varying(500)",
                maxLength: 500,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "AboutPageTitle",
                table: "LandingPageSettings",
                type: "character varying(180)",
                maxLength: 180,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "AboutPageTitleAr",
                table: "LandingPageSettings",
                type: "character varying(180)",
                maxLength: 180,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "AboutPageVisionDescription",
                table: "LandingPageSettings",
                type: "character varying(2000)",
                maxLength: 2000,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "AboutPageVisionDescriptionAr",
                table: "LandingPageSettings",
                type: "character varying(2000)",
                maxLength: 2000,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "AboutPageVisionTitle",
                table: "LandingPageSettings",
                type: "character varying(180)",
                maxLength: 180,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "AboutPageVisionTitleAr",
                table: "LandingPageSettings",
                type: "character varying(180)",
                maxLength: 180,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "ContactAddress",
                table: "LandingPageSettings",
                type: "character varying(500)",
                maxLength: 500,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "ContactAddressAr",
                table: "LandingPageSettings",
                type: "character varying(500)",
                maxLength: 500,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "ContactPageDescription",
                table: "LandingPageSettings",
                type: "character varying(3000)",
                maxLength: 3000,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "ContactPageDescriptionAr",
                table: "LandingPageSettings",
                type: "character varying(3000)",
                maxLength: 3000,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "ContactPageSubtitle",
                table: "LandingPageSettings",
                type: "character varying(500)",
                maxLength: 500,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "ContactPageSubtitleAr",
                table: "LandingPageSettings",
                type: "character varying(500)",
                maxLength: 500,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "ContactPageTitle",
                table: "LandingPageSettings",
                type: "character varying(180)",
                maxLength: 180,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "ContactPageTitleAr",
                table: "LandingPageSettings",
                type: "character varying(180)",
                maxLength: 180,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "ContactWorkingHours",
                table: "LandingPageSettings",
                type: "character varying(300)",
                maxLength: 300,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "ContactWorkingHoursAr",
                table: "LandingPageSettings",
                type: "character varying(300)",
                maxLength: 300,
                nullable: false,
                defaultValue: "");

            migrationBuilder.Sql(@"
                UPDATE ""LandingPageSettings""
                SET
                    ""AboutPageTitle"" = CASE WHEN COALESCE(TRIM(""AboutPageTitle""), '') = '' THEN 'About a legal operating system built for disciplined firms' ELSE ""AboutPageTitle"" END,
                    ""AboutPageTitleAr"" = CASE WHEN COALESCE(TRIM(""AboutPageTitleAr""), '') = '' THEN 'عن منصة تشغيل قانوني مبنية للمكاتب المنضبطة' ELSE ""AboutPageTitleAr"" END,
                    ""AboutPageSubtitle"" = CASE WHEN COALESCE(TRIM(""AboutPageSubtitle""), '') = '' THEN 'We built Qadaya to give legal offices one controlled workspace for case execution, client follow-up, billing, and administration.' ELSE ""AboutPageSubtitle"" END,
                    ""AboutPageSubtitleAr"" = CASE WHEN COALESCE(TRIM(""AboutPageSubtitleAr""), '') = '' THEN 'بنينا قضايا لتمنح مكاتب المحاماة مساحة عمل موحدة لإدارة تنفيذ القضايا ومتابعة العملاء والفوترة والإدارة.' ELSE ""AboutPageSubtitleAr"" END,
                    ""AboutPageDescription"" = CASE WHEN COALESCE(TRIM(""AboutPageDescription""), '') = '' THEN 'Qadaya is designed around the real operating pressure inside law firms: fragmented updates, delayed follow-up, hidden workload, and inconsistent visibility across teams. Our goal is to replace scattered tools with one structured platform that keeps legal work clear, accountable, and easier to manage.' ELSE ""AboutPageDescription"" END,
                    ""AboutPageDescriptionAr"" = CASE WHEN COALESCE(TRIM(""AboutPageDescriptionAr""), '') = '' THEN 'صُممت قضايا حول الضغط التشغيلي الحقيقي داخل المكاتب القانونية: تحديثات متفرقة، متابعة متأخرة، عبء عمل غير واضح، وضعف الرؤية بين الفرق. هدفنا هو استبدال الأدوات المشتتة بمنصة واحدة منظمة تجعل العمل القانوني أوضح وأكثر انضباطاً وأسهل في الإدارة.' ELSE ""AboutPageDescriptionAr"" END,
                    ""AboutPageMissionTitle"" = CASE WHEN COALESCE(TRIM(""AboutPageMissionTitle""), '') = '' THEN 'Our mission' ELSE ""AboutPageMissionTitle"" END,
                    ""AboutPageMissionTitleAr"" = CASE WHEN COALESCE(TRIM(""AboutPageMissionTitleAr""), '') = '' THEN 'رسالتنا' ELSE ""AboutPageMissionTitleAr"" END,
                    ""AboutPageMissionDescription"" = CASE WHEN COALESCE(TRIM(""AboutPageMissionDescription""), '') = '' THEN 'Help legal teams run stronger operations with fewer gaps, better coordination, and clear ownership across every case and client interaction.' ELSE ""AboutPageMissionDescription"" END,
                    ""AboutPageMissionDescriptionAr"" = CASE WHEN COALESCE(TRIM(""AboutPageMissionDescriptionAr""), '') = '' THEN 'مساعدة الفرق القانونية على تشغيل أعمالها بكفاءة أعلى وفجوات أقل وتنسيق أوضح ومسؤولية محددة عبر كل قضية وكل تفاعل مع العميل.' ELSE ""AboutPageMissionDescriptionAr"" END,
                    ""AboutPageVisionTitle"" = CASE WHEN COALESCE(TRIM(""AboutPageVisionTitle""), '') = '' THEN 'Our vision' ELSE ""AboutPageVisionTitle"" END,
                    ""AboutPageVisionTitleAr"" = CASE WHEN COALESCE(TRIM(""AboutPageVisionTitleAr""), '') = '' THEN 'رؤيتنا' ELSE ""AboutPageVisionTitleAr"" END,
                    ""AboutPageVisionDescription"" = CASE WHEN COALESCE(TRIM(""AboutPageVisionDescription""), '') = '' THEN 'Become the central operational layer for modern legal offices that want scalable process control without losing professional rigor.' ELSE ""AboutPageVisionDescription"" END,
                    ""AboutPageVisionDescriptionAr"" = CASE WHEN COALESCE(TRIM(""AboutPageVisionDescriptionAr""), '') = '' THEN 'أن نكون الطبقة التشغيلية المركزية للمكاتب القانونية الحديثة التي تريد تحكماً قابلاً للتوسع دون التفريط في المهنية والانضباط.' ELSE ""AboutPageVisionDescriptionAr"" END,
                    ""ContactPageTitle"" = CASE WHEN COALESCE(TRIM(""ContactPageTitle""), '') = '' THEN 'Contact our team' ELSE ""ContactPageTitle"" END,
                    ""ContactPageTitleAr"" = CASE WHEN COALESCE(TRIM(""ContactPageTitleAr""), '') = '' THEN 'تواصل مع فريقنا' ELSE ""ContactPageTitleAr"" END,
                    ""ContactPageSubtitle"" = CASE WHEN COALESCE(TRIM(""ContactPageSubtitle""), '') = '' THEN 'Reach out for commercial questions, onboarding coordination, product guidance, or platform support.' ELSE ""ContactPageSubtitle"" END,
                    ""ContactPageSubtitleAr"" = CASE WHEN COALESCE(TRIM(""ContactPageSubtitleAr""), '') = '' THEN 'تواصل معنا للاستفسارات التجارية أو التنسيق للبدء أو الإرشاد على المنتج أو دعم المنصة.' ELSE ""ContactPageSubtitleAr"" END,
                    ""ContactPageDescription"" = CASE WHEN COALESCE(TRIM(""ContactPageDescription""), '') = '' THEN 'Use the contact details below and our team will route your request to the right owner as quickly as possible.' ELSE ""ContactPageDescription"" END,
                    ""ContactPageDescriptionAr"" = CASE WHEN COALESCE(TRIM(""ContactPageDescriptionAr""), '') = '' THEN 'استخدم بيانات التواصل التالية وسيقوم فريقنا بتوجيه طلبك إلى المسؤول المناسب بأسرع وقت ممكن.' ELSE ""ContactPageDescriptionAr"" END,
                    ""ContactAddress"" = CASE WHEN COALESCE(TRIM(""ContactAddress""), '') = '' THEN 'Riyadh, Saudi Arabia' ELSE ""ContactAddress"" END,
                    ""ContactAddressAr"" = CASE WHEN COALESCE(TRIM(""ContactAddressAr""), '') = '' THEN 'الرياض، المملكة العربية السعودية' ELSE ""ContactAddressAr"" END,
                    ""ContactWorkingHours"" = CASE WHEN COALESCE(TRIM(""ContactWorkingHours""), '') = '' THEN 'Sunday to Thursday, 9:00 AM to 6:00 PM' ELSE ""ContactWorkingHours"" END,
                    ""ContactWorkingHoursAr"" = CASE WHEN COALESCE(TRIM(""ContactWorkingHoursAr""), '') = '' THEN 'من الأحد إلى الخميس، من 9:00 صباحاً إلى 6:00 مساءً' ELSE ""ContactWorkingHoursAr"" END;
            ");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "AboutPageDescription",
                table: "LandingPageSettings");

            migrationBuilder.DropColumn(
                name: "AboutPageDescriptionAr",
                table: "LandingPageSettings");

            migrationBuilder.DropColumn(
                name: "AboutPageMissionDescription",
                table: "LandingPageSettings");

            migrationBuilder.DropColumn(
                name: "AboutPageMissionDescriptionAr",
                table: "LandingPageSettings");

            migrationBuilder.DropColumn(
                name: "AboutPageMissionTitle",
                table: "LandingPageSettings");

            migrationBuilder.DropColumn(
                name: "AboutPageMissionTitleAr",
                table: "LandingPageSettings");

            migrationBuilder.DropColumn(
                name: "AboutPageSubtitle",
                table: "LandingPageSettings");

            migrationBuilder.DropColumn(
                name: "AboutPageSubtitleAr",
                table: "LandingPageSettings");

            migrationBuilder.DropColumn(
                name: "AboutPageTitle",
                table: "LandingPageSettings");

            migrationBuilder.DropColumn(
                name: "AboutPageTitleAr",
                table: "LandingPageSettings");

            migrationBuilder.DropColumn(
                name: "AboutPageVisionDescription",
                table: "LandingPageSettings");

            migrationBuilder.DropColumn(
                name: "AboutPageVisionDescriptionAr",
                table: "LandingPageSettings");

            migrationBuilder.DropColumn(
                name: "AboutPageVisionTitle",
                table: "LandingPageSettings");

            migrationBuilder.DropColumn(
                name: "AboutPageVisionTitleAr",
                table: "LandingPageSettings");

            migrationBuilder.DropColumn(
                name: "ContactAddress",
                table: "LandingPageSettings");

            migrationBuilder.DropColumn(
                name: "ContactAddressAr",
                table: "LandingPageSettings");

            migrationBuilder.DropColumn(
                name: "ContactPageDescription",
                table: "LandingPageSettings");

            migrationBuilder.DropColumn(
                name: "ContactPageDescriptionAr",
                table: "LandingPageSettings");

            migrationBuilder.DropColumn(
                name: "ContactPageSubtitle",
                table: "LandingPageSettings");

            migrationBuilder.DropColumn(
                name: "ContactPageSubtitleAr",
                table: "LandingPageSettings");

            migrationBuilder.DropColumn(
                name: "ContactPageTitle",
                table: "LandingPageSettings");

            migrationBuilder.DropColumn(
                name: "ContactPageTitleAr",
                table: "LandingPageSettings");

            migrationBuilder.DropColumn(
                name: "ContactWorkingHours",
                table: "LandingPageSettings");

            migrationBuilder.DropColumn(
                name: "ContactWorkingHoursAr",
                table: "LandingPageSettings");
        }
    }
}
