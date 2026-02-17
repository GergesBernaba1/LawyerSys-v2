using LawyerSys.Data;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Serilog;

public static class DataSeeder
{
    public static async Task SeedAdminUser(IServiceProvider serviceProvider)
    {
        using var scope = serviceProvider.CreateScope();
        var services = scope.ServiceProvider;
        var configuration = services.GetRequiredService<IConfiguration>();

        var userManager = services.GetRequiredService<UserManager<ApplicationUser>>();
        var roleManager = services.GetRequiredService<RoleManager<IdentityRole>>();

        var roles = new[] { "Admin", "Employee", "Customer" };
        foreach (var role in roles)
        {
            if (!await roleManager.RoleExistsAsync(role))
            {
                await roleManager.CreateAsync(new IdentityRole(role));
            }
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
                RequiresPasswordReset = false
            };

            var result = await userManager.CreateAsync(adminUser, adminPassword);
            if (result.Succeeded)
            {
                await userManager.AddToRoleAsync(adminUser, "Admin");
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

            Log.Information("Admin user already exists.");
        }
    }
}
