using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LawyerSys.Infrastructure.Data.Migrations.Identity
{
    /// <inheritdoc />
    /// <remarks>
    /// Consolidates the subscription catalog to a single tier with two
    /// billing cycles, priced in EGP:
    ///   * Monthly Plan — 1,000 EGP, renews every month
    ///   * Annual Plan  — 10,500 EGP, renews once per year
    /// The historical "Small Office" / "Medium Office" tiers are no longer
    /// surfaced to customers. Medium Office rows (OfficeSize = 2) are
    /// deactivated rather than deleted to preserve FK references from
    /// TenantSubscriptions / TenantBillingTransactions.
    /// </remarks>
    [DbContext(typeof(ApplicationDbContext))]
    [Migration("20260529120000_ConsolidateSubscriptionPackagesToEgp")]
    public partial class ConsolidateSubscriptionPackagesToEgp : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                -- Monthly Plan (was "Small Office Monthly"): 1,000 EGP / month
                UPDATE "SubscriptionPackages"
                SET
                    "Name" = 'Monthly Plan',
                    "NameAr" = 'الباقة الشهرية',
                    "Description" = 'Monthly subscription billed every month.',
                    "DescriptionAr" = 'اشتراك شهري يُجدد كل شهر.',
                    "Feature1" = 'Case and customer management',
                    "Feature1Ar" = 'إدارة القضايا والعملاء',
                    "Feature2" = 'Courts, hearings, and documents',
                    "Feature2Ar" = 'المحاكم والجلسات والمستندات',
                    "Feature3" = 'Billing, notifications, and reporting',
                    "Feature3Ar" = 'الفوترة والإشعارات والتقارير',
                    "Price" = 1000.00,
                    "Currency" = 'EGP',
                    "IsActive" = TRUE,
                    "DisplayOrder" = 1,
                    "UpdatedAtUtc" = NOW()
                WHERE "OfficeSize" = 1 AND "BillingCycle" = 1;

                -- Annual Plan (was "Small Office Annual"): 10,500 EGP / year
                UPDATE "SubscriptionPackages"
                SET
                    "Name" = 'Annual Plan',
                    "NameAr" = 'الباقة السنوية',
                    "Description" = 'Annual subscription billed once per year.',
                    "DescriptionAr" = 'اشتراك سنوي يُجدد مرة واحدة كل عام.',
                    "Feature1" = 'Case and customer management',
                    "Feature1Ar" = 'إدارة القضايا والعملاء',
                    "Feature2" = 'Courts, hearings, and documents',
                    "Feature2Ar" = 'المحاكم والجلسات والمستندات',
                    "Feature3" = 'Billing, notifications, and reporting',
                    "Feature3Ar" = 'الفوترة والإشعارات والتقارير',
                    "Price" = 10500.00,
                    "Currency" = 'EGP',
                    "IsActive" = TRUE,
                    "DisplayOrder" = 2,
                    "UpdatedAtUtc" = NOW()
                WHERE "OfficeSize" = 1 AND "BillingCycle" = 2;

                -- Deactivate the Medium Office tier — rows kept for FK integrity.
                UPDATE "SubscriptionPackages"
                SET
                    "IsActive" = FALSE,
                    "UpdatedAtUtc" = NOW()
                WHERE "OfficeSize" = 2;
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                -- Restore Small Office Monthly (pre-consolidation state).
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
                    "Feature3Ar" = 'الفوترة والإشعارات والتقارير',
                    "Price" = 99.00,
                    "Currency" = 'SAR',
                    "DisplayOrder" = 1,
                    "UpdatedAtUtc" = NOW()
                WHERE "OfficeSize" = 1 AND "BillingCycle" = 1;

                UPDATE "SubscriptionPackages"
                SET
                    "Name" = 'Small Office',
                    "NameAr" = 'المكتب الصغير',
                    "Price" = 999.00,
                    "Currency" = 'SAR',
                    "DisplayOrder" = 2,
                    "UpdatedAtUtc" = NOW()
                WHERE "OfficeSize" = 1 AND "BillingCycle" = 2;

                -- Re-enable Medium Office rows.
                UPDATE "SubscriptionPackages"
                SET
                    "IsActive" = TRUE,
                    "UpdatedAtUtc" = NOW()
                WHERE "OfficeSize" = 2;
                """);
        }
    }
}
