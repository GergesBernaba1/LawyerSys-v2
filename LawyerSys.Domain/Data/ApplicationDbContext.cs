using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

public class ApplicationDbContext : IdentityDbContext<ApplicationUser>
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options)
    {
    }

    public DbSet<Country> Countries => Set<Country>();
    public DbSet<City> Cities => Set<City>();
    public DbSet<Tenant> Tenants => Set<Tenant>();
    public DbSet<Notification> Notifications => Set<Notification>();
    public DbSet<LandingPageSettings> LandingPageSettings => Set<LandingPageSettings>();
    public DbSet<SubscriptionPackage> SubscriptionPackages => Set<SubscriptionPackage>();
    public DbSet<TenantSubscription> TenantSubscriptions => Set<TenantSubscription>();
    public DbSet<TenantBillingTransaction> TenantBillingTransactions => Set<TenantBillingTransaction>();
    public DbSet<DemoRequest> DemoRequests => Set<DemoRequest>();
    public DbSet<UserNotificationPreference> UserNotificationPreferences => Set<UserNotificationPreference>();
    public DbSet<UserPushToken> UserPushTokens => Set<UserPushToken>();
    public DbSet<CompetitorCapability> CompetitorCapabilities => Set<CompetitorCapability>();
    public DbSet<CoverageAssessment> CoverageAssessments => Set<CoverageAssessment>();
    public DbSet<RoadmapItem> RoadmapItems => Set<RoadmapItem>();
    public DbSet<OutcomeMetric> OutcomeMetrics => Set<OutcomeMetric>();
    public DbSet<RoadmapChangeLog> RoadmapChangeLogs => Set<RoadmapChangeLog>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<ApplicationUser>(entity =>
        {
            entity.HasOne(user => user.Tenant)
                .WithMany(tenant => tenant.Users)
                .HasForeignKey(user => user.TenantId)
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(user => user.Country)
                .WithMany(country => country.Users)
                .HasForeignKey(user => user.CountryId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<Country>(entity =>
        {
            entity.ToTable("Countries");
            entity.Property(country => country.Name)
                .HasMaxLength(100);
            entity.Property(country => country.NameAr)
                .HasMaxLength(100);
            entity.HasIndex(country => country.Name)
                .IsUnique();
        });

        modelBuilder.Entity<City>(entity =>
        {
            entity.ToTable("Cities");
            entity.Property(city => city.Name)
                .HasMaxLength(100);
            entity.Property(city => city.NameAr)
                .HasMaxLength(100);
            entity.Property(city => city.CreatedByUserId)
                .HasMaxLength(450);
            entity.HasIndex(city => new { city.CountryId, city.Name })
                .IsUnique();
            entity.HasIndex(city => city.TenantId);
            entity.HasIndex(city => city.CreatedByUserId);
            entity.HasOne(city => city.Country)
                .WithMany(country => country.Cities)
                .HasForeignKey(city => city.CountryId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(city => city.Tenant)
                .WithMany()
                .HasForeignKey(city => city.TenantId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<Tenant>(entity =>
        {
            entity.ToTable("Tenants");
            entity.Property(tenant => tenant.Name)
                .HasMaxLength(200);
            entity.Property(tenant => tenant.PhoneNumber)
                .HasMaxLength(32);
            entity.Property(tenant => tenant.ContactEmail)
                .HasMaxLength(256);
            entity.Property(tenant => tenant.CreatedAtUtc);
            entity.HasIndex(tenant => tenant.IsActive);
            entity.HasOne(tenant => tenant.Country)
                .WithMany(country => country.Tenants)
                .HasForeignKey(tenant => tenant.CountryId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<SubscriptionPackage>(entity =>
        {
            entity.ToTable("SubscriptionPackages");
            entity.Property(package => package.Name).HasMaxLength(120);
            entity.Property(package => package.NameAr).HasMaxLength(120);
            entity.Property(package => package.Description).HasMaxLength(1000);
            entity.Property(package => package.DescriptionAr).HasMaxLength(1000);
            entity.Property(package => package.Feature1).HasMaxLength(300);
            entity.Property(package => package.Feature1Ar).HasMaxLength(300);
            entity.Property(package => package.Feature2).HasMaxLength(300);
            entity.Property(package => package.Feature2Ar).HasMaxLength(300);
            entity.Property(package => package.Feature3).HasMaxLength(300);
            entity.Property(package => package.Feature3Ar).HasMaxLength(300);
            entity.Property(package => package.Currency).HasMaxLength(12);
            entity.Property(package => package.Price).HasColumnType("numeric(18,2)");
            entity.HasIndex(package => new { package.OfficeSize, package.BillingCycle }).IsUnique();
            entity.HasIndex(package => new { package.IsActive, package.DisplayOrder });
        });

        modelBuilder.Entity<TenantSubscription>(entity =>
        {
            entity.ToTable("TenantSubscriptions");
            entity.HasIndex(subscription => subscription.TenantId);
            entity.HasIndex(subscription => subscription.SubscriptionPackageId);
            entity.HasIndex(subscription => new { subscription.TenantId, subscription.Status });
            entity.HasOne(subscription => subscription.Tenant)
                .WithMany(tenant => tenant.Subscriptions)
                .HasForeignKey(subscription => subscription.TenantId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(subscription => subscription.SubscriptionPackage)
                .WithMany(package => package.TenantSubscriptions)
                .HasForeignKey(subscription => subscription.SubscriptionPackageId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<TenantBillingTransaction>(entity =>
        {
            entity.ToTable("TenantBillingTransactions");
            entity.Property(transaction => transaction.Currency).HasMaxLength(12);
            entity.Property(transaction => transaction.Amount).HasColumnType("numeric(18,2)");
            entity.Property(transaction => transaction.Reference).HasMaxLength(128);
            entity.Property(transaction => transaction.Notes).HasMaxLength(2000);
            entity.HasIndex(transaction => transaction.TenantId);
            entity.HasIndex(transaction => transaction.TenantSubscriptionId);
            entity.HasIndex(transaction => transaction.SubscriptionPackageId);
            entity.HasIndex(transaction => new { transaction.Status, transaction.DueDateUtc });
            entity.HasOne(transaction => transaction.Tenant)
                .WithMany(tenant => tenant.BillingTransactions)
                .HasForeignKey(transaction => transaction.TenantId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(transaction => transaction.TenantSubscription)
                .WithMany(subscription => subscription.BillingTransactions)
                .HasForeignKey(transaction => transaction.TenantSubscriptionId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(transaction => transaction.SubscriptionPackage)
                .WithMany(package => package.BillingTransactions)
                .HasForeignKey(transaction => transaction.SubscriptionPackageId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<DemoRequest>(entity =>
        {
            entity.ToTable("DemoRequests");
            entity.Property(request => request.FullName).HasMaxLength(200);
            entity.Property(request => request.Email).HasMaxLength(256);
            entity.Property(request => request.PhoneNumber).HasMaxLength(64);
            entity.Property(request => request.OfficeName).HasMaxLength(200);
            entity.Property(request => request.Notes).HasMaxLength(2000);
            entity.Property(request => request.ReviewedByUserId).HasMaxLength(450);
            entity.HasIndex(request => new { request.Status, request.CreatedAtUtc });
            entity.HasOne(request => request.ReviewedByUser)
                .WithMany()
                .HasForeignKey(request => request.ReviewedByUserId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        modelBuilder.Entity<UserNotificationPreference>(entity =>
        {
            entity.ToTable("UserNotificationPreferences");
            entity.Property(preference => preference.UserId).HasMaxLength(450);
            entity.Property(preference => preference.PreferredLanguage).HasMaxLength(12);
            entity.HasIndex(preference => preference.UserId).IsUnique();
        });

        modelBuilder.Entity<UserPushToken>(entity =>
        {
            entity.ToTable("UserPushTokens");
            entity.Property(token => token.UserId).HasMaxLength(450).IsRequired();
            entity.Property(token => token.Token).HasMaxLength(512).IsRequired();
            entity.Property(token => token.Platform).HasMaxLength(50);
            entity.HasIndex(token => new { token.UserId, token.Token }).IsUnique();
            entity.HasOne(token => token.User)
                .WithMany(user => user.PushTokens)
                .HasForeignKey(token => token.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<LandingPageSettings>(entity =>
        {
            entity.ToTable("LandingPageSettings");
            entity.Property(settings => settings.SystemName).HasMaxLength(150);
            entity.Property(settings => settings.SystemNameAr).HasMaxLength(150);
            entity.Property(settings => settings.Tagline).HasMaxLength(200);
            entity.Property(settings => settings.TaglineAr).HasMaxLength(200);
            entity.Property(settings => settings.HeroTitle).HasMaxLength(250);
            entity.Property(settings => settings.HeroTitleAr).HasMaxLength(250);
            entity.Property(settings => settings.HeroSubtitle).HasMaxLength(2000);
            entity.Property(settings => settings.HeroSubtitleAr).HasMaxLength(2000);
            entity.Property(settings => settings.PrimaryButtonText).HasMaxLength(120);
            entity.Property(settings => settings.PrimaryButtonTextAr).HasMaxLength(120);
            entity.Property(settings => settings.PrimaryButtonUrl).HasMaxLength(300);
            entity.Property(settings => settings.SecondaryButtonText).HasMaxLength(120);
            entity.Property(settings => settings.SecondaryButtonTextAr).HasMaxLength(120);
            entity.Property(settings => settings.SecondaryButtonUrl).HasMaxLength(300);
            entity.Property(settings => settings.AboutTitle).HasMaxLength(180);
            entity.Property(settings => settings.AboutTitleAr).HasMaxLength(180);
            entity.Property(settings => settings.AboutDescription).HasMaxLength(3000);
            entity.Property(settings => settings.AboutDescriptionAr).HasMaxLength(3000);
            entity.Property(settings => settings.AboutPageTitle).HasMaxLength(180);
            entity.Property(settings => settings.AboutPageTitleAr).HasMaxLength(180);
            entity.Property(settings => settings.AboutPageSubtitle).HasMaxLength(500);
            entity.Property(settings => settings.AboutPageSubtitleAr).HasMaxLength(500);
            entity.Property(settings => settings.AboutPageDescription).HasMaxLength(4000);
            entity.Property(settings => settings.AboutPageDescriptionAr).HasMaxLength(4000);
            entity.Property(settings => settings.AboutPageMissionTitle).HasMaxLength(180);
            entity.Property(settings => settings.AboutPageMissionTitleAr).HasMaxLength(180);
            entity.Property(settings => settings.AboutPageMissionDescription).HasMaxLength(2000);
            entity.Property(settings => settings.AboutPageMissionDescriptionAr).HasMaxLength(2000);
            entity.Property(settings => settings.AboutPageVisionTitle).HasMaxLength(180);
            entity.Property(settings => settings.AboutPageVisionTitleAr).HasMaxLength(180);
            entity.Property(settings => settings.AboutPageVisionDescription).HasMaxLength(2000);
            entity.Property(settings => settings.AboutPageVisionDescriptionAr).HasMaxLength(2000);
            entity.Property(settings => settings.Feature1Title).HasMaxLength(150);
            entity.Property(settings => settings.Feature1TitleAr).HasMaxLength(150);
            entity.Property(settings => settings.Feature1Description).HasMaxLength(1000);
            entity.Property(settings => settings.Feature1DescriptionAr).HasMaxLength(1000);
            entity.Property(settings => settings.Feature2Title).HasMaxLength(150);
            entity.Property(settings => settings.Feature2TitleAr).HasMaxLength(150);
            entity.Property(settings => settings.Feature2Description).HasMaxLength(1000);
            entity.Property(settings => settings.Feature2DescriptionAr).HasMaxLength(1000);
            entity.Property(settings => settings.Feature3Title).HasMaxLength(150);
            entity.Property(settings => settings.Feature3TitleAr).HasMaxLength(150);
            entity.Property(settings => settings.Feature3Description).HasMaxLength(1000);
            entity.Property(settings => settings.Feature3DescriptionAr).HasMaxLength(1000);
            entity.Property(settings => settings.ContactPageTitle).HasMaxLength(180);
            entity.Property(settings => settings.ContactPageTitleAr).HasMaxLength(180);
            entity.Property(settings => settings.ContactPageSubtitle).HasMaxLength(500);
            entity.Property(settings => settings.ContactPageSubtitleAr).HasMaxLength(500);
            entity.Property(settings => settings.ContactPageDescription).HasMaxLength(3000);
            entity.Property(settings => settings.ContactPageDescriptionAr).HasMaxLength(3000);
            entity.Property(settings => settings.ContactAddress).HasMaxLength(500);
            entity.Property(settings => settings.ContactAddressAr).HasMaxLength(500);
            entity.Property(settings => settings.ContactWorkingHours).HasMaxLength(300);
            entity.Property(settings => settings.ContactWorkingHoursAr).HasMaxLength(300);
            entity.Property(settings => settings.ContactEmail).HasMaxLength(256);
            entity.Property(settings => settings.ContactPhone).HasMaxLength(64);
        });

        modelBuilder.Entity<Notification>(entity =>
        {
            entity.ToTable("Notifications");
            entity.Property(notification => notification.RecipientUserId)
                .HasMaxLength(450);
            entity.Property(notification => notification.SenderUserId)
                .HasMaxLength(450);
            entity.Property(notification => notification.Type)
                .HasMaxLength(100);
            entity.Property(notification => notification.Title)
                .HasMaxLength(250);
            entity.Property(notification => notification.TitleAr)
                .HasMaxLength(250);
            entity.Property(notification => notification.Message)
                .HasMaxLength(2000);
            entity.Property(notification => notification.MessageAr)
                .HasMaxLength(2000);
            entity.Property(notification => notification.Route)
                .HasMaxLength(300);
            entity.Property(notification => notification.RelatedEntityType)
                .HasMaxLength(100);
            entity.Property(notification => notification.RelatedEntityId)
                .HasMaxLength(100);
            entity.HasIndex(notification => notification.RecipientUserId);
            entity.HasIndex(notification => new { notification.RecipientUserId, notification.IsRead, notification.CreatedAtUtc });
            entity.HasIndex(notification => notification.TenantId);
            entity.HasIndex(notification => notification.CreatedAtUtc);
            entity.HasOne(notification => notification.RecipientUser)
                .WithMany()
                .HasForeignKey(notification => notification.RecipientUserId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(notification => notification.SenderUser)
                .WithMany()
                .HasForeignKey(notification => notification.SenderUserId)
                .OnDelete(DeleteBehavior.SetNull);
            entity.HasOne(notification => notification.Tenant)
                .WithMany()
                .HasForeignKey(notification => notification.TenantId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        modelBuilder.Entity<CompetitorCapability>(entity =>
        {
            entity.ToTable("ParityCompetitorCapabilities");
            entity.HasKey(x => x.CapabilityId);
            entity.Property(x => x.Category).HasMaxLength(64);
            entity.Property(x => x.Title).HasMaxLength(200);
            entity.Property(x => x.EvidenceSourceUrl).HasMaxLength(500);
            entity.HasIndex(x => new { x.TenantId, x.Category });
        });

        modelBuilder.Entity<CoverageAssessment>(entity =>
        {
            entity.ToTable("ParityCoverageAssessments");
            entity.HasKey(x => x.AssessmentId);
            entity.Property(x => x.CoverageStatus).HasMaxLength(32);
            entity.HasOne(x => x.Capability)
                .WithMany(x => x.Assessments)
                .HasForeignKey(x => x.CapabilityId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<RoadmapItem>(entity =>
        {
            entity.ToTable("ParityRoadmapItems");
            entity.HasKey(x => x.RoadmapItemId);
            entity.Property(x => x.ItemType).HasMaxLength(32);
            entity.Property(x => x.PriorityTier).HasMaxLength(8);
            entity.Property(x => x.ScopeLabel).HasMaxLength(32);
            entity.Property(x => x.LifecycleState).HasMaxLength(32);
            entity.HasIndex(x => new { x.TenantId, x.PriorityTier, x.LifecycleState });
        });

        modelBuilder.Entity<OutcomeMetric>(entity =>
        {
            entity.ToTable("ParityOutcomeMetrics");
            entity.HasKey(x => x.MetricId);
            entity.Property(x => x.MetricName).HasMaxLength(150);
            entity.Property(x => x.MeasurementStatus).HasMaxLength(32);
            entity.HasOne(x => x.RoadmapItem)
                .WithMany(x => x.OutcomeMetrics)
                .HasForeignKey(x => x.RoadmapItemId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<RoadmapChangeLog>(entity =>
        {
            entity.ToTable("ParityRoadmapChangeLogs");
            entity.HasKey(x => x.ChangeLogId);
            entity.Property(x => x.ChangedByRole).HasMaxLength(64);
            entity.Property(x => x.ChangeType).HasMaxLength(64);
            entity.Property(x => x.ChangeSummary).HasMaxLength(1000);
            entity.HasOne(x => x.RoadmapItem)
                .WithMany(x => x.ChangeLogs)
                .HasForeignKey(x => x.RoadmapItemId)
                .OnDelete(DeleteBehavior.Cascade);
        });
    }
}
