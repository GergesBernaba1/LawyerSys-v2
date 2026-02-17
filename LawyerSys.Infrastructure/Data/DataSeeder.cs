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

        var adminEmail = "gergesbernaba2@gmail.com";
        var adminUser = await userManager.FindByEmailAsync(adminEmail);
        if (adminUser is null)
        {
            var configuration = services.GetRequiredService<Microsoft.Extensions.Configuration.IConfiguration>();
            var adminPassword = configuration.GetValue<string>("AdminSeed:Password") ?? "Admin@1234";
            var requireReset = adminPassword == "Admin@1234";

            adminUser = new ApplicationUser
            {
                UserName = adminEmail,
                Email = adminEmail,
                EmailConfirmed = true,
                RequiresPasswordReset = requireReset
            };

            var result = await userManager.CreateAsync(adminUser, adminPassword);
            if (result.Succeeded)
            {
                await userManager.AddToRoleAsync(adminUser, "Admin");
                Log.Information("Admin user created successfully. defaultPassword={DefaultPassword}", requireReset);
                if (requireReset)
                {
                    Log.Warning("Admin account seeded with default password - change immediately.");
                }
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
            Log.Information("Admin user already exists.");
        }
    }
}
