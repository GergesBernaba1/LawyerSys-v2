using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.DependencyInjection;
using LawyerSys.Data;

public static class DataSeeder
{
    public static async Task SeedAdminUser(IServiceProvider serviceProvider)
    {
        using var scope = serviceProvider.CreateScope();
        var services = scope.ServiceProvider;
        
        var userManager = services.GetRequiredService<UserManager<ApplicationUser>>();
        var roleManager = services.GetRequiredService<RoleManager<IdentityRole>>();
        
        // Ensure roles exist
        var roles = new[] { "Admin", "Employee", "Customer" };
        foreach (var role in roles)
        {
            if (!await roleManager.RoleExistsAsync(role))
            {
                await roleManager.CreateAsync(new IdentityRole(role));
            }
        }
        
        // Create admin user if not exists
        var adminEmail = "gergesbernaba2@gmail.com";
        var adminUser = await userManager.FindByEmailAsync(adminEmail);
        if (adminUser == null)
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
                Console.WriteLine($"Admin user created successfully. (defaultPassword={requireReset})");
                if (requireReset)
                {
                    Console.WriteLine("WARNING: Admin account seeded with default password — change immediately.");
                }
            }
            else
            {
                Console.WriteLine("Failed to create admin user:");
                foreach (var error in result.Errors)
                {
                    Console.WriteLine($"- {error.Description}");
                }
            }
        }
        else
        {
            Console.WriteLine("Admin user already exists.");
        }
    }
}