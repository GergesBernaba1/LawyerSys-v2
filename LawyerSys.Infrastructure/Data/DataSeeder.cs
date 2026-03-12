using LawyerSys.Data;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.EntityFrameworkCore;
using Serilog;

public static class DataSeeder
{
    private const string DefaultFirmName = "Default Firm";

    public static async Task SeedAdminUser(IServiceProvider serviceProvider)
    {
        using var scope = serviceProvider.CreateScope();
        var services = scope.ServiceProvider;
        var configuration = services.GetRequiredService<IConfiguration>();
        var applicationDbContext = services.GetRequiredService<ApplicationDbContext>();

        var userManager = services.GetRequiredService<UserManager<ApplicationUser>>();
        var roleManager = services.GetRequiredService<RoleManager<IdentityRole>>();

        var roles = new[] { "SuperAdmin", "Admin", "Employee", "Customer" };
        foreach (var role in roles)
        {
            if (!await roleManager.RoleExistsAsync(role))
            {
                await roleManager.CreateAsync(new IdentityRole(role));
            }
        }

        var defaultTenant = await applicationDbContext.Tenants.SingleOrDefaultAsync(t => t.Id == 1);
        if (defaultTenant == null)
        {
            defaultTenant = new Tenant
            {
                Id = 1,
                Name = configuration.GetValue<string>("AdminSeed:TenantName") ?? "Default Firm",
                PhoneNumber = configuration.GetValue<string>("AdminSeed:TenantPhoneNumber") ?? string.Empty,
                ContactEmail = configuration.GetValue<string>("AdminSeed:Email") ?? "gergesbernaba2@gmail.com",
                CountryId = 1,
                IsActive = true,
                CreatedAtUtc = DateTime.UtcNow
            };

            applicationDbContext.Tenants.Add(defaultTenant);
            await applicationDbContext.SaveChangesAsync();
        }

        var adminEmail = configuration.GetValue<string>("AdminSeed:Email") ?? "gergesbernaba2@gmail.com";
        var adminPassword = configuration.GetValue<string>("AdminSeed:Password") ?? "Gerges@GoGoAdmin123";
        var adminUser = await userManager.FindByEmailAsync(adminEmail);
        if (adminUser is null)
        {
            adminUser = new ApplicationUser
            {
                UserName = adminEmail,
                Email = adminEmail,
                EmailConfirmed = true,
                RequiresPasswordReset = false,
                TenantId = defaultTenant.Id,
                CountryId = defaultTenant.CountryId
            };

            var result = await userManager.CreateAsync(adminUser, adminPassword);
            if (result.Succeeded)
            {
                await userManager.AddToRoleAsync(adminUser, "Admin");
                await userManager.AddToRoleAsync(adminUser, "SuperAdmin");
                Log.Information("Admin user created successfully.");
            }
            else
            {
                Log.Error("Failed to create admin user");
                foreach (var error in result.Errors)
                {
                    Log.Error("Identity error: {ErrorDescription}", error.Description);
                }
            }
        }
        else
        {
            var shouldUpdateAdmin = false;
            if (adminUser.TenantId <= 0)
            {
                adminUser.TenantId = defaultTenant.Id;
                shouldUpdateAdmin = true;
            }

            if (adminUser.CountryId == null && defaultTenant.CountryId.HasValue)
            {
                adminUser.CountryId = defaultTenant.CountryId;
                shouldUpdateAdmin = true;
            }

            if (shouldUpdateAdmin)
            {
                var syncResult = await userManager.UpdateAsync(adminUser);
                if (!syncResult.Succeeded)
                {
                    foreach (var error in syncResult.Errors)
                    {
                        Log.Error("Failed updating seeded admin profile. {ErrorDescription}", error.Description);
                    }
                }
            }

            if (string.IsNullOrWhiteSpace(defaultTenant.ContactEmail))
            {
                defaultTenant.ContactEmail = adminEmail;
                await applicationDbContext.SaveChangesAsync();
            }

            var resetToken = await userManager.GeneratePasswordResetTokenAsync(adminUser);
            var resetResult = await userManager.ResetPasswordAsync(adminUser, resetToken, adminPassword);
            if (!resetResult.Succeeded)
            {
                foreach (var error in resetResult.Errors)
                {
                    Log.Error("Failed to set seeded admin password. {ErrorDescription}", error.Description);
                }
            }

            if (!await userManager.IsInRoleAsync(adminUser, "Admin"))
            {
                var addRoleResult = await userManager.AddToRoleAsync(adminUser, "Admin");
                if (!addRoleResult.Succeeded)
                {
                    foreach (var error in addRoleResult.Errors)
                    {
                        Log.Error("Failed adding existing admin user to role. {ErrorDescription}", error.Description);
                    }
                }
            }

            if (!await userManager.IsInRoleAsync(adminUser, "SuperAdmin"))
            {
                var addRoleResult = await userManager.AddToRoleAsync(adminUser, "SuperAdmin");
                if (!addRoleResult.Succeeded)
                {
                    foreach (var error in addRoleResult.Errors)
                    {
                        Log.Error("Failed adding existing admin user to super admin role. {ErrorDescription}", error.Description);
                    }
                }
            }

            Log.Information("Admin user already exists.");
        }

        if (string.Equals(defaultTenant.Name?.Trim(), DefaultFirmName, StringComparison.OrdinalIgnoreCase))
        {
            var seededTransactions = await applicationDbContext.TenantBillingTransactions
                .Where(transaction => transaction.TenantId == defaultTenant.Id)
                .ToListAsync();
            if (seededTransactions.Count > 0)
            {
                applicationDbContext.TenantBillingTransactions.RemoveRange(seededTransactions);
            }

            var seededSubscriptions = await applicationDbContext.TenantSubscriptions
                .Where(subscription => subscription.TenantId == defaultTenant.Id)
                .ToListAsync();
            if (seededSubscriptions.Count > 0)
            {
                applicationDbContext.TenantSubscriptions.RemoveRange(seededSubscriptions);
            }

            if (seededTransactions.Count > 0 || seededSubscriptions.Count > 0)
            {
                await applicationDbContext.SaveChangesAsync();
            }
        }
    }
}
