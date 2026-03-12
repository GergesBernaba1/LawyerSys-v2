using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LawyerSys.Infrastructure.Data.Migrations.Identity
{
    /// <inheritdoc />
    public partial class BackfillLandingPageLocalizedDefaults : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                UPDATE "LandingPageSettings"
                SET
                    "Tagline" = CASE
                        WHEN BTRIM(COALESCE("Tagline", '')) = '' THEN 'Legal operations, intake, collaboration, and client communication in one platform.'
                        ELSE "Tagline"
                    END,
                    "TaglineAr" = CASE
                        WHEN BTRIM(COALESCE("TaglineAr", '')) = '' THEN 'إدارة العمل القانوني والاستقبال والتعاون والتواصل مع العميل في منصة واحدة.'
                        ELSE "TaglineAr"
                    END,
                    "HeroTitle" = CASE
                        WHEN BTRIM(COALESCE("HeroTitle", '')) = '' THEN 'Run your legal practice with clarity, speed, and control.'
                        ELSE "HeroTitle"
                    END,
                    "HeroTitleAr" = CASE
                        WHEN BTRIM(COALESCE("HeroTitleAr", '')) = '' THEN 'أدر مكتبك القانوني بوضوح وسرعة وتحكم كامل.'
                        ELSE "HeroTitleAr"
                    END,
                    "HeroSubtitle" = CASE
                        WHEN BTRIM(COALESCE("HeroSubtitle", '')) = '' THEN 'Qadaya gives law firms one command center for cases, hearings, customers, billing, signatures, and administration.'
                        ELSE "HeroSubtitle"
                    END,
                    "HeroSubtitleAr" = CASE
                        WHEN BTRIM(COALESCE("HeroSubtitleAr", '')) = '' THEN 'تمنحك قضايا مركز قيادة واحداً لإدارة القضايا والجلسات والعملاء والفواتير والتوقيعات والإدارة.'
                        ELSE "HeroSubtitleAr"
                    END,
                    "PrimaryButtonText" = CASE
                        WHEN BTRIM(COALESCE("PrimaryButtonText", '')) = '' THEN 'Start with Qadaya'
                        ELSE "PrimaryButtonText"
                    END,
                    "PrimaryButtonTextAr" = CASE
                        WHEN BTRIM(COALESCE("PrimaryButtonTextAr", '')) = '' THEN 'ابدأ مع قضايا'
                        ELSE "PrimaryButtonTextAr"
                    END,
                    "PrimaryButtonUrl" = CASE
                        WHEN BTRIM(COALESCE("PrimaryButtonUrl", '')) = '' THEN '/register'
                        ELSE "PrimaryButtonUrl"
                    END,
                    "SecondaryButtonText" = CASE
                        WHEN BTRIM(COALESCE("SecondaryButtonText", '')) = '' THEN 'Sign in'
                        ELSE "SecondaryButtonText"
                    END,
                    "SecondaryButtonTextAr" = CASE
                        WHEN BTRIM(COALESCE("SecondaryButtonTextAr", '')) = '' THEN 'تسجيل الدخول'
                        ELSE "SecondaryButtonTextAr"
                    END,
                    "SecondaryButtonUrl" = CASE
                        WHEN BTRIM(COALESCE("SecondaryButtonUrl", '')) = '' THEN '/login'
                        ELSE "SecondaryButtonUrl"
                    END,
                    "AboutTitle" = CASE
                        WHEN BTRIM(COALESCE("AboutTitle", '')) = '' THEN 'Built for modern legal teams'
                        ELSE "AboutTitle"
                    END,
                    "AboutTitleAr" = CASE
                        WHEN BTRIM(COALESCE("AboutTitleAr", '')) = '' THEN 'مبني لفرق العمل القانونية الحديثة'
                        ELSE "AboutTitleAr"
                    END,
                    "AboutDescription" = CASE
                        WHEN BTRIM(COALESCE("AboutDescription", '')) = '' THEN 'From the first intake conversation to the final hearing, Qadaya helps your team coordinate work, reduce follow-up gaps, and keep every case visible.'
                        ELSE "AboutDescription"
                    END,
                    "AboutDescriptionAr" = CASE
                        WHEN BTRIM(COALESCE("AboutDescriptionAr", '')) = '' THEN 'من أول تواصل مع العميل وحتى آخر جلسة، تساعد قضايا فريقك على تنسيق العمل وتقليل فجوات المتابعة والحفاظ على وضوح كل قضية.'
                        ELSE "AboutDescriptionAr"
                    END,
                    "Feature1Title" = CASE
                        WHEN BTRIM(COALESCE("Feature1Title", '')) = '' THEN 'Structured case operations'
                        ELSE "Feature1Title"
                    END,
                    "Feature1TitleAr" = CASE
                        WHEN BTRIM(COALESCE("Feature1TitleAr", '')) = '' THEN 'تشغيل منظم للقضايا'
                        ELSE "Feature1TitleAr"
                    END,
                    "Feature1Description" = CASE
                        WHEN BTRIM(COALESCE("Feature1Description", '')) = '' THEN 'Track cases, documents, hearings, and financial activity from a single operational view.'
                        ELSE "Feature1Description"
                    END,
                    "Feature1DescriptionAr" = CASE
                        WHEN BTRIM(COALESCE("Feature1DescriptionAr", '')) = '' THEN 'تابع القضايا والمستندات والجلسات والحركة المالية من واجهة تشغيل واحدة.'
                        ELSE "Feature1DescriptionAr"
                    END,
                    "Feature2Title" = CASE
                        WHEN BTRIM(COALESCE("Feature2Title", '')) = '' THEN 'Team and client coordination'
                        ELSE "Feature2Title"
                    END,
                    "Feature2TitleAr" = CASE
                        WHEN BTRIM(COALESCE("Feature2TitleAr", '')) = '' THEN 'تنسيق الفريق والعملاء'
                        ELSE "Feature2TitleAr"
                    END,
                    "Feature2Description" = CASE
                        WHEN BTRIM(COALESCE("Feature2Description", '')) = '' THEN 'Connect lawyers, staff, and customers with notifications, assignments, and shared status visibility.'
                        ELSE "Feature2Description"
                    END,
                    "Feature2DescriptionAr" = CASE
                        WHEN BTRIM(COALESCE("Feature2DescriptionAr", '')) = '' THEN 'اربط المحامين والموظفين والعملاء عبر الإشعارات والإسناد ووضوح الحالة للجميع.'
                        ELSE "Feature2DescriptionAr"
                    END,
                    "Feature3Title" = CASE
                        WHEN BTRIM(COALESCE("Feature3Title", '')) = '' THEN 'Administration with control'
                        ELSE "Feature3Title"
                    END,
                    "Feature3TitleAr" = CASE
                        WHEN BTRIM(COALESCE("Feature3TitleAr", '')) = '' THEN 'إدارة مع تحكم كامل'
                        ELSE "Feature3TitleAr"
                    END,
                    "Feature3Description" = CASE
                        WHEN BTRIM(COALESCE("Feature3Description", '')) = '' THEN 'Manage tenants, permissions, locations, and platform setup from one super admin workspace.'
                        ELSE "Feature3Description"
                    END,
                    "Feature3DescriptionAr" = CASE
                        WHEN BTRIM(COALESCE("Feature3DescriptionAr", '')) = '' THEN 'أدر الجهات والصلاحيات والمواقع وإعدادات المنصة من مساحة واحدة للسوبر أدمن.'
                        ELSE "Feature3DescriptionAr"
                    END,
                    "ContactEmail" = CASE
                        WHEN BTRIM(COALESCE("ContactEmail", '')) = '' THEN 'support@qadaya.app'
                        ELSE "ContactEmail"
                    END,
                    "ContactPhone" = CASE
                        WHEN BTRIM(COALESCE("ContactPhone", '')) = '' THEN '01018206558'
                        ELSE "ContactPhone"
                    END,
                    "UpdatedAtUtc" = NOW()
                WHERE EXISTS (SELECT 1 FROM "LandingPageSettings");
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // No-op. This migration only backfills empty landing-page fields.
        }
    }
}
