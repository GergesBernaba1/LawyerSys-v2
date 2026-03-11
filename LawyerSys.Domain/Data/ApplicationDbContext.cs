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
    }
}
