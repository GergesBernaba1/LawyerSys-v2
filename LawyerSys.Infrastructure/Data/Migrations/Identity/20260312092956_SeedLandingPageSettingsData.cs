using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LawyerSys.Infrastructure.Data.Migrations.Identity
{
    /// <inheritdoc />
    public partial class SeedLandingPageSettingsData : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                INSERT INTO "LandingPageSettings" (
                    "SystemName",
                    "Tagline",
                    "TaglineAr",
                    "HeroTitle",
                    "HeroTitleAr",
                    "HeroSubtitle",
                    "HeroSubtitleAr",
                    "PrimaryButtonText",
                    "PrimaryButtonTextAr",
                    "PrimaryButtonUrl",
                    "SecondaryButtonText",
                    "SecondaryButtonTextAr",
                    "SecondaryButtonUrl",
                    "AboutTitle",
                    "AboutTitleAr",
                    "AboutDescription",
                    "AboutDescriptionAr",
                    "Feature1Title",
                    "Feature1TitleAr",
                    "Feature1Description",
                    "Feature1DescriptionAr",
                    "Feature2Title",
                    "Feature2TitleAr",
                    "Feature2Description",
                    "Feature2DescriptionAr",
                    "Feature3Title",
                    "Feature3TitleAr",
                    "Feature3Description",
                    "Feature3DescriptionAr",
                    "ContactEmail",
                    "ContactPhone",
                    "UpdatedAtUtc"
                )
                SELECT
                    'Qadaya',
                    'Legal operations, intake, collaboration, and client communication in one platform.',
                    'إدارة العمل القانوني والاستقبال والتعاون والتواصل مع العميل في منصة واحدة.',
                    'Run your legal practice with clarity, speed, and control.',
                    'أدر مكتبك القانوني بوضوح وسرعة وتحكم كامل.',
                    'Qadaya gives law firms one command center for cases, hearings, customers, billing, signatures, and administration.',
                    'تمنحك قضايا مركز قيادة واحداً لإدارة القضايا والجلسات والعملاء والفواتير والتوقيعات والإدارة.',
                    'Start with Qadaya',
                    'ابدأ مع قضايا',
                    '/register',
                    'Sign in',
                    'تسجيل الدخول',
                    '/login',
                    'Built for modern legal teams',
                    'مبني لفرق العمل القانونية الحديثة',
                    'From the first intake conversation to the final hearing, Qadaya helps your team coordinate work, reduce follow-up gaps, and keep every case visible.',
                    'من أول تواصل مع العميل وحتى آخر جلسة، تساعد قضايا فريقك على تنسيق العمل وتقليل فجوات المتابعة والحفاظ على وضوح كل قضية.',
                    'Structured case operations',
                    'تشغيل منظم للقضايا',
                    'Track cases, documents, hearings, and financial activity from a single operational view.',
                    'تابع القضايا والمستندات والجلسات والحركة المالية من واجهة تشغيل واحدة.',
                    'Team and client coordination',
                    'تنسيق الفريق والعملاء',
                    'Connect lawyers, staff, and customers with notifications, assignments, and shared status visibility.',
                    'اربط المحامين والموظفين والعملاء عبر الإشعارات والإسناد ووضوح الحالة للجميع.',
                    'Administration with control',
                    'إدارة مع تحكم كامل',
                    'Manage tenants, permissions, locations, and platform setup from one super admin workspace.',
                    'أدر الجهات والصلاحيات والمواقع وإعدادات المنصة من مساحة واحدة للسوبر أدمن.',
                    'support@qadaya.app',
                    '01018206558',
                    NOW()
                WHERE NOT EXISTS (SELECT 1 FROM "LandingPageSettings");
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                DELETE FROM "LandingPageSettings"
                WHERE "SystemName" = 'Qadaya'
                  AND "PrimaryButtonUrl" = '/register'
                  AND "SecondaryButtonUrl" = '/login';
                """);
        }
    }
}
