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
            entity.Property(tenant => tenant.CreatedAtUtc);
            entity.HasIndex(tenant => tenant.IsActive);
            entity.HasOne(tenant => tenant.Country)
                .WithMany(country => country.Tenants)
                .HasForeignKey(tenant => tenant.CountryId)
                .OnDelete(DeleteBehavior.Restrict);
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
    }
}
