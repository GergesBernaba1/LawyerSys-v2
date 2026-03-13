using LawyerSys.Data.ScaffoldedModels;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using FileEntity = LawyerSys.Data.ScaffoldedModels.File;

namespace LawyerSys.Data;

public static class DemoDataSeeder
{
    private const string DemoNotificationType = "demo-seed";

    public static async Task SeedDemoData(IServiceProvider serviceProvider)
    {
        var configuration = serviceProvider.GetRequiredService<IConfiguration>();
        if (!configuration.GetValue<bool>("Seed:EnableDemoData"))
        {
            return;
        }

        var applicationDbContext = serviceProvider.GetRequiredService<ApplicationDbContext>();
        var legacyDbContext = serviceProvider.GetRequiredService<LegacyDbContext>();
        var userManager = serviceProvider.GetRequiredService<UserManager<ApplicationUser>>();
        var roleManager = serviceProvider.GetRequiredService<RoleManager<IdentityRole>>();

        await EnsureRolesAsync(roleManager);
        var countries = await EnsureCountriesAsync(applicationDbContext);
        var packages = await EnsureSubscriptionPackagesAsync(applicationDbContext);
        var demoPassword = Normalize(configuration["Seed:DemoPassword"], "DemoTenant@123");

        foreach (var demoTenant in BuildDemoTenants(countries))
        {
            await EnsureDemoTenantAsync(
                applicationDbContext,
                legacyDbContext,
                userManager,
                demoTenant,
                packages,
                demoPassword);
        }
    }

    private static DemoTenantDefinition[] BuildDemoTenants(IReadOnlyDictionary<string, Country> countries)
    {
        return
        [
            new DemoTenantDefinition(
                Slug: "atlas-monthly",
                ShortName: "Atlas",
                Name: "Atlas Litigation Hub",
                ContactEmail: "atlas.monthly@demo.local",
                PhoneNumber: "0501001001",
                Country: countries["Saudi Arabia"],
                CityName: "Atlas Demo Riyadh",
                CityNameAr: "أطلس الرياض التجريبية",
                AdminEmail: "atlas.admin@demo.local",
                AdminUserName: "atlas.admin",
                AdminPhone: "0501001002",
                EmployeeEmail: "atlas.employee@demo.local",
                EmployeeUserName: "atlas.employee",
                EmployeePhone: "0501001003",
                CustomerEmail: "atlas.customer@demo.local",
                CustomerUserName: "atlas.customer",
                CustomerPhone: "0501001004",
                IsActive: true,
                SubscriptionScenario: DemoSubscriptionScenario.ActiveMonthly,
                NotificationTitle: "Monthly tenant ready",
                NotificationTitleAr: "المستأجر الشهري جاهز",
                NotificationMessage: "Atlas Litigation Hub includes active monthly billing and full sample records.",
                NotificationMessageAr: "يتضمن مكتب أطلس اشتراكاً شهرياً نشطاً وبيانات تجريبية كاملة."),

            new DemoTenantDefinition(
                Slug: "cedar-annual",
                ShortName: "Cedar",
                Name: "Cedar Corporate Advisory",
                ContactEmail: "cedar.annual@demo.local",
                PhoneNumber: "0502002001",
                Country: countries["Egypt"],
                CityName: "Cedar Demo Cairo",
                CityNameAr: "سيدر القاهرة التجريبية",
                AdminEmail: "cedar.admin@demo.local",
                AdminUserName: "cedar.admin",
                AdminPhone: "0502002002",
                EmployeeEmail: "cedar.employee@demo.local",
                EmployeeUserName: "cedar.employee",
                EmployeePhone: "0502002003",
                CustomerEmail: "cedar.customer@demo.local",
                CustomerUserName: "cedar.customer",
                CustomerPhone: "0502002004",
                IsActive: true,
                SubscriptionScenario: DemoSubscriptionScenario.ActiveAnnual,
                NotificationTitle: "Annual tenant ready",
                NotificationTitleAr: "المستأجر السنوي جاهز",
                NotificationMessage: "Cedar Corporate Advisory includes active annual billing and full sample records.",
                NotificationMessageAr: "يتضمن مكتب سيدر اشتراكاً سنوياً نشطاً وبيانات تجريبية كاملة."),

            new DemoTenantDefinition(
                Slug: "nile-pending",
                ShortName: "Nile",
                Name: "Nile Startup Counsel",
                ContactEmail: "nile.pending@demo.local",
                PhoneNumber: "0503003001",
                Country: countries["United Arab Emirates"],
                CityName: "Nile Demo Dubai",
                CityNameAr: "النيل دبي التجريبية",
                AdminEmail: "nile.admin@demo.local",
                AdminUserName: "nile.admin",
                AdminPhone: "0503003002",
                EmployeeEmail: "nile.employee@demo.local",
                EmployeeUserName: "nile.employee",
                EmployeePhone: "0503003003",
                CustomerEmail: "nile.customer@demo.local",
                CustomerUserName: "nile.customer",
                CustomerPhone: "0503003004",
                IsActive: false,
                SubscriptionScenario: DemoSubscriptionScenario.PendingActivationMonthly,
                NotificationTitle: "Pending activation tenant ready",
                NotificationTitleAr: "المستأجر المعلق جاهز",
                NotificationMessage: "Nile Startup Counsel is inactive with a pending monthly subscription for activation testing.",
                NotificationMessageAr: "مكتب النيل غير مفعل مع اشتراك شهري معلق لاختبار التفعيل."),

            new DemoTenantDefinition(
                Slug: "horizon-expired",
                ShortName: "Horizon",
                Name: "Horizon Dispute Resolution",
                ContactEmail: "horizon.expired@demo.local",
                PhoneNumber: "0504004001",
                Country: countries["Qatar"],
                CityName: "Horizon Demo Doha",
                CityNameAr: "هورايزن الدوحة التجريبية",
                AdminEmail: "horizon.admin@demo.local",
                AdminUserName: "horizon.admin",
                AdminPhone: "0504004002",
                EmployeeEmail: "horizon.employee@demo.local",
                EmployeeUserName: "horizon.employee",
                EmployeePhone: "0504004003",
                CustomerEmail: "horizon.customer@demo.local",
                CustomerUserName: "horizon.customer",
                CustomerPhone: "0504004004",
                IsActive: true,
                SubscriptionScenario: DemoSubscriptionScenario.ExpiredAnnual,
                NotificationTitle: "Expired tenant ready",
                NotificationTitleAr: "المستأجر المنتهي جاهز",
                NotificationMessage: "Horizon Dispute Resolution includes an expired annual subscription and overdue renewal.",
                NotificationMessageAr: "يتضمن مكتب هورايزن اشتراكاً سنوياً منتهياً وتجديداً متأخراً."),
        ];
    }

    private static async Task<Dictionary<string, Country>> EnsureCountriesAsync(ApplicationDbContext applicationDbContext)
    {
        var definitions = new[]
        {
            new CountrySeedDefinition("Saudi Arabia", "المملكة العربية السعودية"),
            new CountrySeedDefinition("Egypt", "مصر"),
            new CountrySeedDefinition("United Arab Emirates", "الإمارات العربية المتحدة"),
            new CountrySeedDefinition("Qatar", "قطر"),
        };

        var countries = await applicationDbContext.Countries.ToListAsync();

        foreach (var definition in definitions)
        {
            var country = countries.FirstOrDefault(item =>
                string.Equals(item.Name, definition.Name, StringComparison.OrdinalIgnoreCase));

            if (country == null)
            {
                country = new Country
                {
                    Name = definition.Name,
                    NameAr = definition.NameAr,
                };

                applicationDbContext.Countries.Add(country);
                countries.Add(country);
            }
            else
            {
                country.NameAr = definition.NameAr;
            }
        }

        await applicationDbContext.SaveChangesAsync();

        return countries
            .Where(item => definitions.Any(definition =>
                string.Equals(definition.Name, item.Name, StringComparison.OrdinalIgnoreCase)))
            .ToDictionary(item => item.Name, StringComparer.OrdinalIgnoreCase);
    }

    private static async Task<SubscriptionPackageSeedResult> EnsureSubscriptionPackagesAsync(ApplicationDbContext applicationDbContext)
    {
        var packages = await applicationDbContext.SubscriptionPackages.ToListAsync();
        var monthly = packages.FirstOrDefault(item => item.IsActive && item.BillingCycle == SubscriptionBillingCycle.Monthly);
        var annual = packages.FirstOrDefault(item => item.IsActive && item.BillingCycle == SubscriptionBillingCycle.Annual);
        var template = monthly ?? annual;
        var now = DateTime.UtcNow;

        if (monthly == null)
        {
            monthly = new SubscriptionPackage
            {
                Name = template?.Name ?? "LawyerSys Standard",
                NameAr = template?.NameAr ?? "الباقة القياسية",
                Description = template?.Description ?? "Standard monthly access for tenant testing",
                DescriptionAr = template?.DescriptionAr ?? "وصول شهري قياسي لاختبار المستأجرين",
                Feature1 = template?.Feature1 ?? "Case and client management",
                Feature1Ar = template?.Feature1Ar ?? "إدارة القضايا والعملاء",
                Feature2 = template?.Feature2 ?? "Billing and subscription tracking",
                Feature2Ar = template?.Feature2Ar ?? "متابعة الفوترة والاشتراكات",
                Feature3 = template?.Feature3 ?? "Notifications and reminders",
                Feature3Ar = template?.Feature3Ar ?? "الإشعارات والتذكيرات",
                OfficeSize = template?.OfficeSize ?? SubscriptionOfficeSize.Small,
                BillingCycle = SubscriptionBillingCycle.Monthly,
                Price = 299,
                Currency = template?.Currency ?? "SAR",
                IsActive = true,
                DisplayOrder = template?.DisplayOrder ?? 1,
                CreatedAtUtc = now,
                UpdatedAtUtc = now,
            };

            applicationDbContext.SubscriptionPackages.Add(monthly);
        }

        if (annual == null)
        {
            annual = new SubscriptionPackage
            {
                Name = monthly.Name,
                NameAr = monthly.NameAr,
                Description = monthly.Description,
                DescriptionAr = monthly.DescriptionAr,
                Feature1 = monthly.Feature1,
                Feature1Ar = monthly.Feature1Ar,
                Feature2 = monthly.Feature2,
                Feature2Ar = monthly.Feature2Ar,
                Feature3 = monthly.Feature3,
                Feature3Ar = monthly.Feature3Ar,
                OfficeSize = monthly.OfficeSize,
                BillingCycle = SubscriptionBillingCycle.Annual,
                Price = 2990,
                Currency = monthly.Currency,
                IsActive = true,
                DisplayOrder = monthly.DisplayOrder,
                CreatedAtUtc = now,
                UpdatedAtUtc = now,
            };

            applicationDbContext.SubscriptionPackages.Add(annual);
        }

        await applicationDbContext.SaveChangesAsync();
        return new SubscriptionPackageSeedResult(monthly, annual);
    }

    private static async Task EnsureRolesAsync(RoleManager<IdentityRole> roleManager)
    {
        foreach (var role in new[] { "SuperAdmin", "Admin", "Employee", "Customer" })
        {
            if (!await roleManager.RoleExistsAsync(role))
            {
                var result = await roleManager.CreateAsync(new IdentityRole(role));
                EnsureIdentitySucceeded(result);
            }
        }
    }

    private static async Task EnsureDemoTenantAsync(
        ApplicationDbContext applicationDbContext,
        LegacyDbContext legacyDbContext,
        UserManager<ApplicationUser> userManager,
        DemoTenantDefinition demoTenant,
        SubscriptionPackageSeedResult packages,
        string demoPassword)
    {
        var tenant = await applicationDbContext.Tenants
            .SingleOrDefaultAsync(item => item.ContactEmail == demoTenant.ContactEmail)
            ?? await applicationDbContext.Tenants
                .SingleOrDefaultAsync(item => item.Name == demoTenant.Name);

        if (tenant == null)
        {
            tenant = new Tenant
            {
                Name = demoTenant.Name,
                PhoneNumber = demoTenant.PhoneNumber,
                ContactEmail = demoTenant.ContactEmail,
                CountryId = demoTenant.Country.Id,
                IsActive = demoTenant.IsActive,
                CreatedAtUtc = DateTime.UtcNow,
            };

            applicationDbContext.Tenants.Add(tenant);
            await applicationDbContext.SaveChangesAsync();
        }
        else
        {
            tenant.Name = demoTenant.Name;
            tenant.PhoneNumber = demoTenant.PhoneNumber;
            tenant.ContactEmail = demoTenant.ContactEmail;
            tenant.CountryId = demoTenant.Country.Id;
            tenant.IsActive = demoTenant.IsActive;
            await applicationDbContext.SaveChangesAsync();
        }

        var adminUser = await EnsureIdentityUserAsync(
            userManager,
            email: demoTenant.AdminEmail,
            userName: demoTenant.AdminUserName,
            fullName: $"{demoTenant.ShortName} Admin",
            phoneNumber: demoTenant.AdminPhone,
            tenantId: tenant.Id,
            countryId: demoTenant.Country.Id,
            password: demoPassword,
            role: "Admin",
            isEnabled: true);

        await EnsureIdentityUserAsync(
            userManager,
            email: demoTenant.EmployeeEmail,
            userName: demoTenant.EmployeeUserName,
            fullName: $"{demoTenant.ShortName} Employee",
            phoneNumber: demoTenant.EmployeePhone,
            tenantId: tenant.Id,
            countryId: demoTenant.Country.Id,
            password: demoPassword,
            role: "Employee",
            isEnabled: true);

        await EnsureIdentityUserAsync(
            userManager,
            email: demoTenant.CustomerEmail,
            userName: demoTenant.CustomerUserName,
            fullName: $"{demoTenant.ShortName} Customer",
            phoneNumber: demoTenant.CustomerPhone,
            tenantId: tenant.Id,
            countryId: demoTenant.Country.Id,
            password: demoPassword,
            role: "Customer",
            isEnabled: true);

        await EnsureTenantCityAsync(applicationDbContext, tenant.Id, demoTenant, adminUser.Id);
        await EnsureTenantNotificationAsync(applicationDbContext, tenant.Id, adminUser.Id, demoTenant);
        await RebuildDemoSubscriptionAsync(applicationDbContext, tenant, demoTenant.SubscriptionScenario, packages);
        await EnsureLegacyDemoDataAsync(legacyDbContext, tenant.Id, demoTenant);
    }

    private static async Task RebuildDemoSubscriptionAsync(
        ApplicationDbContext applicationDbContext,
        Tenant tenant,
        DemoSubscriptionScenario scenario,
        SubscriptionPackageSeedResult packages)
    {
        var transactions = await applicationDbContext.TenantBillingTransactions
            .Where(item => item.TenantId == tenant.Id)
            .ToListAsync();
        if (transactions.Count > 0)
        {
            applicationDbContext.TenantBillingTransactions.RemoveRange(transactions);
        }

        var subscriptions = await applicationDbContext.TenantSubscriptions
            .Where(item => item.TenantId == tenant.Id)
            .ToListAsync();
        if (subscriptions.Count > 0)
        {
            applicationDbContext.TenantSubscriptions.RemoveRange(subscriptions);
        }

        await applicationDbContext.SaveChangesAsync();

        var now = DateTime.UtcNow;
        SubscriptionPackage package;
        TenantSubscription subscription;

        switch (scenario)
        {
            case DemoSubscriptionScenario.ActiveMonthly:
                package = packages.Monthly;
                subscription = new TenantSubscription
                {
                    TenantId = tenant.Id,
                    SubscriptionPackageId = package.Id,
                    Status = TenantSubscriptionStatus.Active,
                    StartDateUtc = now.AddDays(-10),
                    EndDateUtc = now.AddDays(20),
                    NextBillingDateUtc = now.AddDays(20),
                    CreatedAtUtc = now,
                    UpdatedAtUtc = now,
                };
                break;

            case DemoSubscriptionScenario.ActiveAnnual:
                package = packages.Annual;
                subscription = new TenantSubscription
                {
                    TenantId = tenant.Id,
                    SubscriptionPackageId = package.Id,
                    Status = TenantSubscriptionStatus.Active,
                    StartDateUtc = now.AddDays(-90),
                    EndDateUtc = now.AddDays(275),
                    NextBillingDateUtc = now.AddDays(275),
                    CreatedAtUtc = now,
                    UpdatedAtUtc = now,
                };
                break;

            case DemoSubscriptionScenario.PendingActivationMonthly:
                package = packages.Monthly;
                subscription = new TenantSubscription
                {
                    TenantId = tenant.Id,
                    SubscriptionPackageId = package.Id,
                    Status = TenantSubscriptionStatus.PendingActivation,
                    StartDateUtc = now.AddDays(-3),
                    EndDateUtc = now.AddDays(27),
                    NextBillingDateUtc = now.AddDays(27),
                    CreatedAtUtc = now,
                    UpdatedAtUtc = now,
                };
                break;

            case DemoSubscriptionScenario.ExpiredAnnual:
                package = packages.Annual;
                subscription = new TenantSubscription
                {
                    TenantId = tenant.Id,
                    SubscriptionPackageId = package.Id,
                    Status = TenantSubscriptionStatus.Expired,
                    StartDateUtc = now.AddYears(-1).AddDays(-35),
                    EndDateUtc = now.AddDays(-35),
                    NextBillingDateUtc = now.AddDays(-35),
                    CreatedAtUtc = now,
                    UpdatedAtUtc = now,
                };
                break;

            default:
                return;
        }

        applicationDbContext.TenantSubscriptions.Add(subscription);
        await applicationDbContext.SaveChangesAsync();

        if (scenario == DemoSubscriptionScenario.ExpiredAnnual)
        {
            applicationDbContext.TenantBillingTransactions.Add(CreateBillingTransaction(
                tenant.Id,
                subscription.Id,
                package,
                TenantBillingTransactionStatus.Paid,
                subscription.StartDateUtc.AddYears(-2),
                subscription.StartDateUtc.AddYears(-1),
                subscription.StartDateUtc.AddYears(-2),
                "DEMO-PAID-2",
                "Older paid annual period",
                subscription.StartDateUtc.AddYears(-2),
                subscription.StartDateUtc.AddYears(-2)));

            applicationDbContext.TenantBillingTransactions.Add(CreateBillingTransaction(
                tenant.Id,
                subscription.Id,
                package,
                TenantBillingTransactionStatus.Paid,
                subscription.StartDateUtc.AddYears(-1),
                subscription.StartDateUtc,
                subscription.StartDateUtc.AddYears(-1),
                "DEMO-PAID-1",
                "Latest paid annual period",
                subscription.StartDateUtc.AddYears(-1),
                subscription.StartDateUtc.AddYears(-1)));

            applicationDbContext.TenantBillingTransactions.Add(CreateBillingTransaction(
                tenant.Id,
                subscription.Id,
                package,
                TenantBillingTransactionStatus.Overdue,
                subscription.EndDateUtc,
                subscription.EndDateUtc.AddYears(1),
                subscription.EndDateUtc,
                "DEMO-OVERDUE",
                "Renewal overdue for testing",
                now,
                now));

            applicationDbContext.TenantBillingTransactions.Add(CreateBillingTransaction(
                tenant.Id,
                subscription.Id,
                package,
                TenantBillingTransactionStatus.Cancelled,
                subscription.EndDateUtc.AddYears(1),
                subscription.EndDateUtc.AddYears(2),
                subscription.EndDateUtc.AddYears(1),
                "DEMO-CANCELLED",
                "Follow-up renewal cancelled for testing",
                now,
                now));
        }
        else
        {
            var previousPeriodStart = package.BillingCycle == SubscriptionBillingCycle.Annual
                ? subscription.StartDateUtc.AddYears(-1)
                : subscription.StartDateUtc.AddMonths(-2);
            var previousPeriodMid = package.BillingCycle == SubscriptionBillingCycle.Annual
                ? subscription.StartDateUtc
                : subscription.StartDateUtc.AddMonths(-1);
            var firstFuturePeriodEnd = package.BillingCycle == SubscriptionBillingCycle.Annual
                ? subscription.EndDateUtc.AddYears(1)
                : subscription.EndDateUtc.AddMonths(1);
            var secondFuturePeriodEnd = package.BillingCycle == SubscriptionBillingCycle.Annual
                ? firstFuturePeriodEnd.AddYears(1)
                : firstFuturePeriodEnd.AddMonths(1);

            applicationDbContext.TenantBillingTransactions.Add(CreateBillingTransaction(
                tenant.Id,
                subscription.Id,
                package,
                TenantBillingTransactionStatus.Paid,
                previousPeriodStart,
                previousPeriodMid,
                previousPeriodStart,
                "DEMO-HISTORY-2",
                "Older paid billing period",
                previousPeriodStart,
                previousPeriodStart));

            applicationDbContext.TenantBillingTransactions.Add(CreateBillingTransaction(
                tenant.Id,
                subscription.Id,
                package,
                TenantBillingTransactionStatus.Paid,
                previousPeriodMid,
                subscription.StartDateUtc,
                previousPeriodMid,
                "DEMO-HISTORY-1",
                "Recent paid billing period",
                previousPeriodMid,
                previousPeriodMid));

            applicationDbContext.TenantBillingTransactions.Add(CreateBillingTransaction(
                tenant.Id,
                subscription.Id,
                package,
                TenantBillingTransactionStatus.Paid,
                subscription.StartDateUtc,
                subscription.EndDateUtc,
                subscription.StartDateUtc,
                "DEMO-CURRENT",
                "Demo subscription current period",
                now,
                now));

            applicationDbContext.TenantBillingTransactions.Add(CreateBillingTransaction(
                tenant.Id,
                subscription.Id,
                package,
                TenantBillingTransactionStatus.Pending,
                subscription.EndDateUtc,
                firstFuturePeriodEnd,
                subscription.EndDateUtc,
                "DEMO-UPCOMING-1",
                "Upcoming renewal for testing",
                now,
                now));

            applicationDbContext.TenantBillingTransactions.Add(CreateBillingTransaction(
                tenant.Id,
                subscription.Id,
                package,
                TenantBillingTransactionStatus.Pending,
                firstFuturePeriodEnd,
                secondFuturePeriodEnd,
                firstFuturePeriodEnd,
                "DEMO-UPCOMING-2",
                "Second future renewal for testing",
                now,
                now));
        }

        await applicationDbContext.SaveChangesAsync();
    }

    private static TenantBillingTransaction CreateBillingTransaction(
        int tenantId,
        int subscriptionId,
        SubscriptionPackage package,
        TenantBillingTransactionStatus status,
        DateTime periodStartUtc,
        DateTime periodEndUtc,
        DateTime dueDateUtc,
        string reference,
        string notes,
        DateTime createdAtUtc,
        DateTime updatedAtUtc)
    {
        return new TenantBillingTransaction
        {
            TenantId = tenantId,
            TenantSubscriptionId = subscriptionId,
            SubscriptionPackageId = package.Id,
            Status = status,
            BillingCycle = package.BillingCycle,
            Amount = package.Price,
            Currency = package.Currency,
            PeriodStartUtc = periodStartUtc,
            PeriodEndUtc = periodEndUtc,
            DueDateUtc = dueDateUtc,
            PaidAtUtc = status == TenantBillingTransactionStatus.Paid ? dueDateUtc : null,
            Reference = reference,
            Notes = notes,
            CreatedAtUtc = createdAtUtc,
            UpdatedAtUtc = updatedAtUtc,
        };
    }

    private static async Task<ApplicationUser> EnsureIdentityUserAsync(
        UserManager<ApplicationUser> userManager,
        string email,
        string userName,
        string fullName,
        string phoneNumber,
        int tenantId,
        int? countryId,
        string password,
        string role,
        bool isEnabled)
    {
        var normalizedEmail = userManager.NormalizeEmail(email);
        var normalizedUserName = userManager.NormalizeName(userName);

        var user = await userManager.Users.SingleOrDefaultAsync(item =>
            item.NormalizedEmail == normalizedEmail || item.NormalizedUserName == normalizedUserName);

        var isNew = false;
        if (user == null)
        {
            user = new ApplicationUser
            {
                UserName = userName,
                Email = email,
                FullName = fullName,
                PhoneNumber = phoneNumber,
                TenantId = tenantId,
                CountryId = countryId,
                EmailConfirmed = true,
                RequiresPasswordReset = false,
                LockoutEnabled = true,
            };

            var createResult = await userManager.CreateAsync(user, password);
            EnsureIdentitySucceeded(createResult);
            isNew = true;
        }

        user.UserName = userName;
        user.Email = email;
        user.FullName = fullName;
        user.PhoneNumber = phoneNumber;
        user.TenantId = tenantId;
        user.CountryId = countryId;
        user.EmailConfirmed = true;
        user.RequiresPasswordReset = false;
        user.LockoutEnabled = true;
        user.LockoutEnd = isEnabled ? null : DateTimeOffset.MaxValue;

        if (!isNew)
        {
            var updateResult = await userManager.UpdateAsync(user);
            EnsureIdentitySucceeded(updateResult);
        }
        else if (user.PasswordHash == null)
        {
            var passwordResult = await userManager.AddPasswordAsync(user, password);
            EnsureIdentitySucceeded(passwordResult);
        }

        var currentRoles = await userManager.GetRolesAsync(user);
        var rolesToRemove = currentRoles
            .Where(item => !string.Equals(item, role, StringComparison.OrdinalIgnoreCase))
            .ToArray();

        if (rolesToRemove.Length > 0)
        {
            var removeRolesResult = await userManager.RemoveFromRolesAsync(user, rolesToRemove);
            EnsureIdentitySucceeded(removeRolesResult);
        }

        if (!currentRoles.Contains(role, StringComparer.OrdinalIgnoreCase))
        {
            var addRoleResult = await userManager.AddToRoleAsync(user, role);
            EnsureIdentitySucceeded(addRoleResult);
        }

        return user;
    }

    private static async Task EnsureTenantCityAsync(
        ApplicationDbContext applicationDbContext,
        int tenantId,
        DemoTenantDefinition demoTenant,
        string createdByUserId)
    {
        var city = await applicationDbContext.Cities
            .SingleOrDefaultAsync(item => item.CountryId == demoTenant.Country.Id && item.Name == demoTenant.CityName);

        if (city == null)
        {
            city = new City
            {
                Name = demoTenant.CityName,
                NameAr = demoTenant.CityNameAr,
                CountryId = demoTenant.Country.Id,
                TenantId = tenantId,
                CreatedByUserId = createdByUserId,
            };

            applicationDbContext.Cities.Add(city);
        }
        else
        {
            city.NameAr = demoTenant.CityNameAr;
            city.TenantId = tenantId;
            city.CreatedByUserId = createdByUserId;
        }

        await applicationDbContext.SaveChangesAsync();
    }

    private static async Task EnsureTenantNotificationAsync(
        ApplicationDbContext applicationDbContext,
        int tenantId,
        string recipientUserId,
        DemoTenantDefinition demoTenant)
    {
        var notification = await applicationDbContext.Notifications
            .SingleOrDefaultAsync(item =>
                item.RecipientUserId == recipientUserId &&
                item.Type == DemoNotificationType &&
                item.RelatedEntityId == demoTenant.Slug);

        if (notification == null)
        {
            notification = new Notification
            {
                RecipientUserId = recipientUserId,
                TenantId = tenantId,
                Type = DemoNotificationType,
                RelatedEntityType = "tenant",
                RelatedEntityId = demoTenant.Slug,
                Route = "/dashboard",
                IsRead = false,
                CreatedAtUtc = DateTime.UtcNow,
            };

            applicationDbContext.Notifications.Add(notification);
        }

        notification.Title = demoTenant.NotificationTitle;
        notification.TitleAr = demoTenant.NotificationTitleAr;
        notification.Message = demoTenant.NotificationMessage;
        notification.MessageAr = demoTenant.NotificationMessageAr;

        await applicationDbContext.SaveChangesAsync();
    }

    private static async Task EnsureLegacyDemoDataAsync(
        LegacyDbContext legacyDbContext,
        int tenantId,
        DemoTenantDefinition demoTenant)
    {
        var baseUserId = tenantId * 10000;
        var legacyAdmin = await EnsureLegacyUserAsync(
            legacyDbContext,
            tenantId,
            id: baseUserId + 1,
            fullName: $"{demoTenant.ShortName} Admin",
            job: "Manager",
            userName: $"{demoTenant.Slug}.admin",
            password: "demo-pass",
            phoneNumber: 100000000 + tenantId * 10 + 1,
            ssn: 200000000 + tenantId * 10 + 1,
            dateOfBirth: new DateOnly(1986, 4, 12));

        var legacyEmployeeUser = await EnsureLegacyUserAsync(
            legacyDbContext,
            tenantId,
            id: baseUserId + 2,
            fullName: $"{demoTenant.ShortName} Associate",
            job: "Associate",
            userName: $"{demoTenant.Slug}.associate",
            password: "demo-pass",
            phoneNumber: 100000000 + tenantId * 10 + 2,
            ssn: 200000000 + tenantId * 10 + 2,
            dateOfBirth: new DateOnly(1990, 8, 3));

        var legacyCustomerUserOne = await EnsureLegacyUserAsync(
            legacyDbContext,
            tenantId,
            id: baseUserId + 3,
            fullName: $"{demoTenant.ShortName} Customer",
            job: "Client",
            userName: demoTenant.CustomerUserName,
            password: "demo-pass",
            phoneNumber: 100000000 + tenantId * 10 + 3,
            ssn: 200000000 + tenantId * 10 + 3,
            dateOfBirth: new DateOnly(1993, 1, 19));

        var legacyCustomerUserTwo = await EnsureLegacyUserAsync(
            legacyDbContext,
            tenantId,
            id: baseUserId + 4,
            fullName: $"{demoTenant.ShortName} Client Two",
            job: "Client",
            userName: $"{demoTenant.Slug}.client2",
            password: "demo-pass",
            phoneNumber: 100000000 + tenantId * 10 + 4,
            ssn: 200000000 + tenantId * 10 + 4,
            dateOfBirth: new DateOnly(1988, 11, 7));

        var legacyCustomerUserThree = await EnsureLegacyUserAsync(
            legacyDbContext,
            tenantId,
            id: baseUserId + 5,
            fullName: $"{demoTenant.ShortName} Client Three",
            job: "Client",
            userName: $"{demoTenant.Slug}.client3",
            password: "demo-pass",
            phoneNumber: 100000000 + tenantId * 10 + 5,
            ssn: 200000000 + tenantId * 10 + 5,
            dateOfBirth: new DateOnly(1995, 6, 14));

        var employee = await EnsureLegacyEmployeeAsync(legacyDbContext, tenantId, legacyEmployeeUser.Id, 14500);
        var customerOne = await EnsureLegacyCustomerAsync(legacyDbContext, tenantId, legacyCustomerUserOne.Id);
        var customerTwo = await EnsureLegacyCustomerAsync(legacyDbContext, tenantId, legacyCustomerUserTwo.Id);
        var customerThree = await EnsureLegacyCustomerAsync(legacyDbContext, tenantId, legacyCustomerUserThree.Id);
        var government = await EnsureGovernmentAsync(
            legacyDbContext,
            tenantId,
            id: tenantId * 100 + 1,
            name: $"{demoTenant.ShortName} Gov");

        NormalizePendingLegacyDateTimes(legacyDbContext);
        await legacyDbContext.SaveChangesAsync();

        var court = await EnsureCourtAsync(
            legacyDbContext,
            tenantId,
            name: $"{demoTenant.ShortName} Court",
            governmentId: government.Id);

        var caseOne = await EnsureCaseAsync(
            legacyDbContext,
            tenantId,
            code: tenantId * 10000 + 101,
            invitationStatement: "Open",
            invitationType: "Civil",
            invitationDate: DateOnly.FromDateTime(DateTime.UtcNow.AddDays(-30)),
            totalAmount: 45000,
            notes: "Civil claim",
            status: 1);

        var caseTwo = await EnsureCaseAsync(
            legacyDbContext,
            tenantId,
            code: tenantId * 10000 + 102,
            invitationStatement: "Filed",
            invitationType: "Labor",
            invitationDate: DateOnly.FromDateTime(DateTime.UtcNow.AddDays(-12)),
            totalAmount: 18000,
            notes: "Labor file",
            status: 2);

        var caseThree = await EnsureCaseAsync(
            legacyDbContext,
            tenantId,
            code: tenantId * 10000 + 103,
            invitationStatement: "Hearing",
            invitationType: "Commercial",
            invitationDate: DateOnly.FromDateTime(DateTime.UtcNow.AddDays(-45)),
            totalAmount: 72000,
            notes: "Commercial dispute",
            status: 1);

        var sitingOne = await EnsureSitingAsync(
            legacyDbContext,
            tenantId,
            judgeName: $"Judge {demoTenant.ShortName}",
            sitingDate: DateOnly.FromDateTime(DateTime.UtcNow.AddDays(7)),
            sitingTime: DateTime.UtcNow.AddDays(7).Date.AddHours(10),
            notificationTime: DateTime.UtcNow.AddDays(6).Date.AddHours(9),
            notes: "Main hearing");

        var sitingTwo = await EnsureSitingAsync(
            legacyDbContext,
            tenantId,
            judgeName: $"Judge {demoTenant.ShortName} B",
            sitingDate: DateOnly.FromDateTime(DateTime.UtcNow.AddDays(21)),
            sitingTime: DateTime.UtcNow.AddDays(21).Date.AddHours(11),
            notificationTime: DateTime.UtcNow.AddDays(20).Date.AddHours(9),
            notes: "Review date");

        var sitingThree = await EnsureSitingAsync(
            legacyDbContext,
            tenantId,
            judgeName: $"Judge {demoTenant.ShortName} C",
            sitingDate: DateOnly.FromDateTime(DateTime.UtcNow.AddDays(14)),
            sitingTime: DateTime.UtcNow.AddDays(14).Date.AddHours(9),
            notificationTime: DateTime.UtcNow.AddDays(13).Date.AddHours(9),
            notes: "Evidence hearing");

        var sitingFour = await EnsureSitingAsync(
            legacyDbContext,
            tenantId,
            judgeName: $"Judge {demoTenant.ShortName} D",
            sitingDate: DateOnly.FromDateTime(DateTime.UtcNow.AddDays(35)),
            sitingTime: DateTime.UtcNow.AddDays(35).Date.AddHours(12),
            notificationTime: DateTime.UtcNow.AddDays(34).Date.AddHours(10),
            notes: "Final follow-up");

        var contender = await EnsureContenderAsync(
            legacyDbContext,
            tenantId,
            fullName: $"{demoTenant.ShortName} Opponent",
            ssn: 210000000 + tenantId,
            birthDate: new DateOnly(1984, 5, 23));

        var file = await EnsureFileAsync(
            legacyDbContext,
            tenantId,
            code: $"{demoTenant.Slug}-file-001",
            path: $"/Uploads/{demoTenant.Slug}/case-001.pdf");

        var fileTwo = await EnsureFileAsync(
            legacyDbContext,
            tenantId,
            code: $"{demoTenant.Slug}-file-002",
            path: $"/Uploads/{demoTenant.Slug}/case-001-annex.pdf");

        var fileThree = await EnsureFileAsync(
            legacyDbContext,
            tenantId,
            code: $"{demoTenant.Slug}-file-003",
            path: $"/Uploads/{demoTenant.Slug}/case-002-contract.pdf");

        var fileFour = await EnsureFileAsync(
            legacyDbContext,
            tenantId,
            code: $"{demoTenant.Slug}-file-004",
            path: $"/Uploads/{demoTenant.Slug}/case-003-exhibit-a.pdf");

        var fileFive = await EnsureFileAsync(
            legacyDbContext,
            tenantId,
            code: $"{demoTenant.Slug}-file-005",
            path: $"/Uploads/{demoTenant.Slug}/case-003-exhibit-b.pdf");

        var consultation = await EnsureConsultationAsync(
            legacyDbContext,
            tenantId,
            subject: $"{demoTenant.ShortName} Intake",
            consultationState: "Done",
            type: "Advisory",
            description: "Initial consult",
            feedback: "Proceed",
            notes: "Qualified lead",
            dateTime: DateTime.UtcNow.AddDays(-6));

        var consultationTwo = await EnsureConsultationAsync(
            legacyDbContext,
            tenantId,
            subject: $"{demoTenant.ShortName} Followup",
            consultationState: "Done",
            type: "Strategy",
            description: "Case planning",
            feedback: "Approved",
            notes: "Move to filing",
            dateTime: DateTime.UtcNow.AddDays(-2));

        await EnsureAdministrativeTaskAsync(
            legacyDbContext,
            tenantId,
            taskName: $"{demoTenant.ShortName} Review",
            type: "Review",
            taskDate: DateOnly.FromDateTime(DateTime.UtcNow.AddDays(2)),
            reminderDate: DateTime.UtcNow.AddDays(1).Date.AddHours(8),
            notes: "Check docs",
            employeeId: employee.id);

        await EnsureAdministrativeTaskAsync(
            legacyDbContext,
            tenantId,
            taskName: $"{demoTenant.ShortName} Draft Motion",
            type: "Drafting",
            taskDate: DateOnly.FromDateTime(DateTime.UtcNow.AddDays(5)),
            reminderDate: DateTime.UtcNow.AddDays(4).Date.AddHours(9),
            notes: "Prepare motion",
            employeeId: employee.id);

        await EnsureAdministrativeTaskAsync(
            legacyDbContext,
            tenantId,
            taskName: $"{demoTenant.ShortName} Client Followup",
            type: "Client",
            taskDate: DateOnly.FromDateTime(DateTime.UtcNow.AddDays(8)),
            reminderDate: DateTime.UtcNow.AddDays(7).Date.AddHours(10),
            notes: "Call client",
            employeeId: employee.id);

        await EnsureIntakeLeadAsync(
            legacyDbContext,
            tenantId,
            email: $"{demoTenant.Slug}.lead@demo.local",
            fullName: $"{demoTenant.ShortName} Prospect",
            phoneNumber: $"050{tenantId:0000000}",
            subject: $"{demoTenant.ShortName} lead",
            description: "Needs case review",
            desiredCaseType: "Civil",
            status: "Qualified",
            assignedEmployeeId: employee.id,
            convertedCustomerId: customerOne.Id,
            convertedCaseCode: caseOne.Code);

        await EnsureIntakeLeadAsync(
            legacyDbContext,
            tenantId,
            email: $"{demoTenant.Slug}.lead2@demo.local",
            fullName: $"{demoTenant.ShortName} Prospect Two",
            phoneNumber: $"051{tenantId:0000000}",
            subject: $"{demoTenant.ShortName} second lead",
            description: "Needs urgent review",
            desiredCaseType: "Commercial",
            status: "Contacted",
            assignedEmployeeId: employee.id,
            convertedCustomerId: customerThree.Id,
            convertedCaseCode: caseThree.Code);

        await EnsureTimeTrackingEntryAsync(
            legacyDbContext,
            tenantId,
            caseCode: caseOne.Code,
            customerId: customerOne.Id,
            startedBy: legacyAdmin.User_Name,
            workType: "Research",
            description: "Prepared case summary",
            durationMinutes: 95,
            suggestedAmount: 950m);

        await EnsureTimeTrackingEntryAsync(
            legacyDbContext,
            tenantId,
            caseCode: caseTwo.Code,
            customerId: customerTwo.Id,
            startedBy: legacyAdmin.User_Name,
            workType: "Drafting",
            description: "Prepared response brief",
            durationMinutes: 130,
            suggestedAmount: 1250m);

        await EnsureTimeTrackingEntryAsync(
            legacyDbContext,
            tenantId,
            caseCode: caseThree.Code,
            customerId: customerThree.Id,
            startedBy: legacyAdmin.User_Name,
            workType: "Meeting",
            description: "Case strategy session",
            durationMinutes: 75,
            suggestedAmount: 700m);

        await EnsureTrustLedgerEntryAsync(
            legacyDbContext,
            tenantId,
            reference: $"{demoTenant.Slug}-trust-001",
            customerId: customerOne.Id,
            caseCode: caseOne.Code,
            entryType: "Deposit",
            amount: 5000,
            description: "Initial trust deposit",
            createdBy: legacyAdmin.User_Name);

        await EnsureTrustLedgerEntryAsync(
            legacyDbContext,
            tenantId,
            reference: $"{demoTenant.Slug}-trust-002",
            customerId: customerTwo.Id,
            caseCode: caseTwo.Code,
            entryType: "Deposit",
            amount: 3200,
            description: "Second client deposit",
            createdBy: legacyAdmin.User_Name);

        await EnsureTrustLedgerEntryAsync(
            legacyDbContext,
            tenantId,
            reference: $"{demoTenant.Slug}-trust-003",
            customerId: customerThree.Id,
            caseCode: caseThree.Code,
            entryType: "Withdrawal",
            amount: 1200,
            description: "Filing expense reimbursement",
            createdBy: legacyAdmin.User_Name);

        NormalizePendingLegacyDateTimes(legacyDbContext);
        await legacyDbContext.SaveChangesAsync();

        await EnsureCaseEmployeeLinkAsync(legacyDbContext, tenantId, caseOne.Code, employee.id);
        await EnsureCaseEmployeeLinkAsync(legacyDbContext, tenantId, caseTwo.Code, employee.id);
        await EnsureCaseEmployeeLinkAsync(legacyDbContext, tenantId, caseThree.Code, employee.id);
        await EnsureCustomerCaseLinkAsync(legacyDbContext, tenantId, caseOne.Code, customerOne.Id);
        await EnsureCustomerCaseLinkAsync(legacyDbContext, tenantId, caseTwo.Code, customerTwo.Id);
        await EnsureCustomerCaseLinkAsync(legacyDbContext, tenantId, caseThree.Code, customerThree.Id);
        await EnsureCaseCourtLinkAsync(legacyDbContext, tenantId, caseOne.Code, court.Id);
        await EnsureCaseCourtLinkAsync(legacyDbContext, tenantId, caseTwo.Code, court.Id);
        await EnsureCaseCourtLinkAsync(legacyDbContext, tenantId, caseThree.Code, court.Id);
        await EnsureCaseSitingLinkAsync(legacyDbContext, tenantId, caseOne.Code, sitingOne.Id);
        await EnsureCaseSitingLinkAsync(legacyDbContext, tenantId, caseTwo.Code, sitingTwo.Id);
        await EnsureCaseSitingLinkAsync(legacyDbContext, tenantId, caseTwo.Code, sitingThree.Id);
        await EnsureCaseSitingLinkAsync(legacyDbContext, tenantId, caseThree.Code, sitingFour.Id);
        await EnsureCaseContenderLinkAsync(legacyDbContext, tenantId, caseOne.Code, contender.Id);
        await EnsureCaseContenderLinkAsync(legacyDbContext, tenantId, caseThree.Code, contender.Id);
        await EnsureCaseFileLinkAsync(legacyDbContext, tenantId, caseOne.Code, file.Id);
        await EnsureCaseFileLinkAsync(legacyDbContext, tenantId, caseOne.Code, fileTwo.Id);
        await EnsureCaseFileLinkAsync(legacyDbContext, tenantId, caseTwo.Code, fileThree.Id);
        await EnsureCaseFileLinkAsync(legacyDbContext, tenantId, caseThree.Code, fileFour.Id);
        await EnsureCaseFileLinkAsync(legacyDbContext, tenantId, caseThree.Code, fileFive.Id);
        await EnsureConsultationCustomerLinkAsync(legacyDbContext, tenantId, consultation.Id, customerOne.Id);
        await EnsureConsultationEmployeeLinkAsync(legacyDbContext, tenantId, consultation.Id, employee.id);
        await EnsureConsultationCustomerLinkAsync(legacyDbContext, tenantId, consultationTwo.Id, customerThree.Id);
        await EnsureConsultationEmployeeLinkAsync(legacyDbContext, tenantId, consultationTwo.Id, employee.id);
        await EnsureCaseStatusHistoryAsync(legacyDbContext, tenantId, caseOne.Code, 0, 1, legacyAdmin.User_Name);
        await EnsureCaseStatusHistoryAsync(legacyDbContext, tenantId, caseTwo.Code, 1, 2, legacyAdmin.User_Name);
        await EnsureCaseStatusHistoryAsync(legacyDbContext, tenantId, caseThree.Code, 0, 1, legacyAdmin.User_Name);
        await EnsureCaseStatusHistoryAsync(legacyDbContext, tenantId, caseThree.Code, 1, 2, legacyAdmin.User_Name);
        await EnsureCaseConversationMessageAsync(
            legacyDbContext,
            tenantId,
            caseOne.Code,
            legacyAdmin.User_Name,
            legacyAdmin.Full_Name,
            "Admin",
            "We reviewed your file and scheduled the next hearing. Please check the session details.",
            true);
        await EnsureCaseConversationMessageAsync(
            legacyDbContext,
            tenantId,
            caseOne.Code,
            legacyCustomerUserOne.User_Name,
            legacyCustomerUserOne.Full_Name,
            "Customer",
            "Thank you. I have uploaded the requested documents and will attend the hearing.",
            true);
        await EnsureCaseConversationMessageAsync(
            legacyDbContext,
            tenantId,
            caseTwo.Code,
            legacyAdmin.User_Name,
            legacyAdmin.Full_Name,
            "Admin",
            "Please confirm whether the latest contract annex should be included before filing.",
            true);
        var billingPayOne = await EnsureBillingPayAsync(
            legacyDbContext,
            tenantId,
            customerOne.Id,
            4200,
            DateOnly.FromDateTime(DateTime.UtcNow.AddDays(-8)),
            "Initial retainer payment");
        await EnsureBillingPayAsync(
            legacyDbContext,
            tenantId,
            customerTwo.Id,
            1800,
            DateOnly.FromDateTime(DateTime.UtcNow.AddDays(-3)),
            "Document filing payment");
        await EnsureCustomerRequestedDocumentAsync(
            legacyDbContext,
            tenantId,
            caseOne.Code,
            customerOne.Id,
            "Signed authorization letter",
            "Upload the signed authorization letter before the next hearing.",
            DateOnly.FromDateTime(DateTime.UtcNow.AddDays(5)),
            "Submitted",
            legacyAdmin.User_Name,
            legacyAdmin.Full_Name,
            "Uploaded and ready for review.",
            string.Empty,
            fileTwo.Id);
        await EnsureCustomerRequestedDocumentAsync(
            legacyDbContext,
            tenantId,
            caseTwo.Code,
            customerTwo.Id,
            "Updated contract annex",
            "Please provide the latest contract annex with signature pages.",
            DateOnly.FromDateTime(DateTime.UtcNow.AddDays(3)),
            "Pending",
            legacyAdmin.User_Name,
            legacyAdmin.Full_Name,
            string.Empty,
            string.Empty,
            null);
        await EnsureCustomerPaymentProofAsync(
            legacyDbContext,
            tenantId,
            customerOne.Id,
            caseOne.Code,
            4200,
            DateOnly.FromDateTime(DateTime.UtcNow.AddDays(-8)),
            "Bank transfer proof for the initial retainer.",
            fileTwo.Id,
            "Approved",
            billingPayOne.Id,
            legacyAdmin.User_Name,
            legacyAdmin.Full_Name,
            "Payment matched and approved.");
        await EnsureCustomerPaymentProofAsync(
            legacyDbContext,
            tenantId,
            customerTwo.Id,
            caseTwo.Code,
            1800,
            DateOnly.FromDateTime(DateTime.UtcNow.AddDays(-1)),
            "Transfer receipt for filing costs.",
            fileThree.Id,
            "Pending",
            null,
            string.Empty,
            string.Empty,
            string.Empty);

        await legacyDbContext.SaveChangesAsync();
    }

    private static async Task<User> EnsureLegacyUserAsync(
        LegacyDbContext legacyDbContext,
        int tenantId,
        int id,
        string fullName,
        string job,
        string userName,
        string password,
        int phoneNumber,
        int ssn,
        DateOnly dateOfBirth)
    {
        var user = await ForFirm<User>(legacyDbContext, tenantId)
            .SingleOrDefaultAsync(item => item.Id == id || item.User_Name == userName);

        if (user == null)
        {
            user = new User { Id = id };
            legacyDbContext.Users.Add(user);
            SetFirmId(legacyDbContext, user, tenantId);
        }

        user.Full_Name = fullName;
        user.Address = $"{fullName} office";
        user.Job = job;
        user.Phon_Number = phoneNumber;
        user.Date_Of_Birth = dateOfBirth;
        user.SSN = ssn;
        user.User_Name = userName;
        user.Password = password;

        return user;
    }

    private static async Task EnsureCaseConversationMessageAsync(
        LegacyDbContext legacyDbContext,
        int tenantId,
        int caseCode,
        string senderUserId,
        string senderName,
        string senderRole,
        string message,
        bool visibleToCustomer)
    {
        var item = await ForFirm<CaseConversationMessage>(legacyDbContext, tenantId)
            .SingleOrDefaultAsync(entry =>
                entry.CaseCode == caseCode &&
                entry.SenderUserId == senderUserId &&
                entry.Message == message);

        if (item == null)
        {
            item = new CaseConversationMessage();
            legacyDbContext.CaseConversationMessages.Add(item);
            SetFirmId(legacyDbContext, item, tenantId);
        }

        item.CaseCode = caseCode;
        item.SenderUserId = senderUserId;
        item.SenderName = senderName;
        item.SenderRole = senderRole;
        item.Message = message;
        item.VisibleToCustomer = visibleToCustomer;
        if (item.CreatedAtUtc == default)
        {
            item.CreatedAtUtc = ToLegacyTimestamp(DateTime.UtcNow);
        }
    }

    private static async Task<Billing_Pay> EnsureBillingPayAsync(
        LegacyDbContext legacyDbContext,
        int tenantId,
        int customerId,
        double amount,
        DateOnly dateOfOperation,
        string notes)
    {
        var item = await ForFirm<Billing_Pay>(legacyDbContext, tenantId)
            .SingleOrDefaultAsync(entry =>
                entry.Custmor_Id == customerId &&
                entry.Amount == amount &&
                entry.Date_Of_Opreation == dateOfOperation &&
                entry.Notes == notes);

        if (item == null)
        {
            item = new Billing_Pay();
            legacyDbContext.Billing_Pays.Add(item);
            SetFirmId(legacyDbContext, item, tenantId);
        }

        item.Custmor_Id = customerId;
        item.Amount = amount;
        item.Date_Of_Opreation = dateOfOperation;
        item.Notes = notes;
        return item;
    }

    private static async Task EnsureCustomerRequestedDocumentAsync(
        LegacyDbContext legacyDbContext,
        int tenantId,
        int caseCode,
        int customerId,
        string title,
        string description,
        DateOnly? dueDate,
        string status,
        string requestedByUserId,
        string requestedByName,
        string customerNotes,
        string reviewNotes,
        int? uploadedFileId)
    {
        var item = await ForFirm<CustomerRequestedDocument>(legacyDbContext, tenantId)
            .SingleOrDefaultAsync(entry => entry.CaseCode == caseCode && entry.CustomerId == customerId && entry.Title == title);

        if (item == null)
        {
            item = new CustomerRequestedDocument();
            legacyDbContext.CustomerRequestedDocuments.Add(item);
            SetFirmId(legacyDbContext, item, tenantId);
        }

        item.CaseCode = caseCode;
        item.CustomerId = customerId;
        item.Title = title;
        item.Description = description;
        item.DueDate = dueDate;
        item.Status = status;
        item.RequestedByUserId = requestedByUserId;
        item.RequestedByName = requestedByName;
        item.CustomerNotes = customerNotes;
        item.ReviewNotes = reviewNotes;
        item.UploadedFileId = uploadedFileId;
        item.RequestedAtUtc = item.RequestedAtUtc == default ? ToLegacyTimestamp(DateTime.UtcNow.AddDays(-2)) : ToLegacyTimestamp(item.RequestedAtUtc);
        item.SubmittedAtUtc = status is "Submitted" or "Approved" ? ToLegacyTimestamp(DateTime.UtcNow.AddDays(-1)) : null;
        item.ReviewedAtUtc = status is "Approved" or "Rejected" ? ToLegacyTimestamp(DateTime.UtcNow) : null;
    }

    private static async Task EnsureCustomerPaymentProofAsync(
        LegacyDbContext legacyDbContext,
        int tenantId,
        int customerId,
        int? caseCode,
        double amount,
        DateOnly paymentDate,
        string notes,
        int? proofFileId,
        string status,
        int? billingPaymentId,
        string reviewedByUserId,
        string reviewedByName,
        string reviewNotes)
    {
        var item = await ForFirm<CustomerPaymentProof>(legacyDbContext, tenantId)
            .SingleOrDefaultAsync(entry =>
                entry.CustomerId == customerId &&
                entry.CaseCode == caseCode &&
                entry.Amount == amount &&
                entry.PaymentDate == paymentDate);

        if (item == null)
        {
            item = new CustomerPaymentProof();
            legacyDbContext.CustomerPaymentProofs.Add(item);
            SetFirmId(legacyDbContext, item, tenantId);
        }

        item.CustomerId = customerId;
        item.CaseCode = caseCode;
        item.Amount = amount;
        item.PaymentDate = paymentDate;
        item.Notes = notes;
        item.ProofFileId = proofFileId;
        item.Status = status;
        item.BillingPaymentId = billingPaymentId;
        item.ReviewedByUserId = reviewedByUserId;
        item.ReviewedByName = reviewedByName;
        item.ReviewNotes = reviewNotes;
        item.SubmittedAtUtc = item.SubmittedAtUtc == default ? ToLegacyTimestamp(DateTime.UtcNow.AddDays(-1)) : ToLegacyTimestamp(item.SubmittedAtUtc);
        item.ReviewedAtUtc = status is "Approved" or "Rejected" ? ToLegacyTimestamp(DateTime.UtcNow) : null;
    }

    private static async Task<Employee> EnsureLegacyEmployeeAsync(
        LegacyDbContext legacyDbContext,
        int tenantId,
        int userId,
        int salary)
    {
        var employee = await ForFirm<Employee>(legacyDbContext, tenantId)
            .SingleOrDefaultAsync(item => item.Users_Id == userId);

        if (employee == null)
        {
            employee = new Employee { Users_Id = userId };
            legacyDbContext.Employees.Add(employee);
            SetFirmId(legacyDbContext, employee, tenantId);
        }

        employee.Salary = salary;
        return employee;
    }

    private static async Task<Customer> EnsureLegacyCustomerAsync(
        LegacyDbContext legacyDbContext,
        int tenantId,
        int userId)
    {
        var customer = await ForFirm<Customer>(legacyDbContext, tenantId)
            .SingleOrDefaultAsync(item => item.Users_Id == userId);

        if (customer == null)
        {
            customer = new Customer { Users_Id = userId };
            legacyDbContext.Customers.Add(customer);
            SetFirmId(legacyDbContext, customer, tenantId);
        }

        return customer;
    }

    private static async Task<Governament> EnsureGovernmentAsync(
        LegacyDbContext legacyDbContext,
        int tenantId,
        int id,
        string name)
    {
        var government = await ForFirm<Governament>(legacyDbContext, tenantId)
            .SingleOrDefaultAsync(item => item.Id == id);

        if (government == null)
        {
            government = new Governament { Id = id };
            legacyDbContext.Governaments.Add(government);
            SetFirmId(legacyDbContext, government, tenantId);
        }

        government.Gov_Name = name;
        return government;
    }

    private static async Task<Court> EnsureCourtAsync(
        LegacyDbContext legacyDbContext,
        int tenantId,
        string name,
        int governmentId)
    {
        var court = await ForFirm<Court>(legacyDbContext, tenantId)
            .SingleOrDefaultAsync(item => item.Name == name);

        if (court == null)
        {
            court = new Court();
            legacyDbContext.Courts.Add(court);
            SetFirmId(legacyDbContext, court, tenantId);
        }

        court.Name = name;
        court.Address = $"{name} Street";
        court.Telephone = "0101001001";
        court.Notes = "Demo court";
        court.Gov_Id = governmentId;
        return court;
    }

    private static async Task<Case> EnsureCaseAsync(
        LegacyDbContext legacyDbContext,
        int tenantId,
        int code,
        string invitationStatement,
        string invitationType,
        DateOnly invitationDate,
        int totalAmount,
        string notes,
        int status)
    {
        var item = await ForFirm<Case>(legacyDbContext, tenantId)
            .SingleOrDefaultAsync(entry => entry.Code == code);

        if (item == null)
        {
            item = new Case { Code = code };
            legacyDbContext.Cases.Add(item);
            SetFirmId(legacyDbContext, item, tenantId);
        }

        item.Invitions_Statment = invitationStatement;
        item.Invition_Type = invitationType;
        item.Invition_Date = invitationDate;
        item.Total_Amount = totalAmount;
        item.Notes = notes;
        item.Status = status;
        return item;
    }

    private static async Task<Siting> EnsureSitingAsync(
        LegacyDbContext legacyDbContext,
        int tenantId,
        string judgeName,
        DateOnly sitingDate,
        DateTime sitingTime,
        DateTime notificationTime,
        string notes)
    {
        var siting = await ForFirm<Siting>(legacyDbContext, tenantId)
            .SingleOrDefaultAsync(item => item.Judge_Name == judgeName && item.Siting_Date == sitingDate);

        if (siting == null)
        {
            siting = new Siting();
            legacyDbContext.Sitings.Add(siting);
            SetFirmId(legacyDbContext, siting, tenantId);
        }

        siting.Judge_Name = judgeName;
        siting.Siting_Date = sitingDate;
        siting.Siting_Time = ToLegacyTimestamp(sitingTime);
        siting.Siting_Notification = ToLegacyTimestamp(notificationTime);
        siting.Notes = notes;
        return siting;
    }

    private static async Task<Contender> EnsureContenderAsync(
        LegacyDbContext legacyDbContext,
        int tenantId,
        string fullName,
        int ssn,
        DateOnly birthDate)
    {
        var contender = await ForFirm<Contender>(legacyDbContext, tenantId)
            .SingleOrDefaultAsync(item => item.SSN == ssn);

        if (contender == null)
        {
            contender = new Contender();
            legacyDbContext.Contenders.Add(contender);
            SetFirmId(legacyDbContext, contender, tenantId);
        }

        contender.Full_Name = fullName;
        contender.SSN = ssn;
        contender.BirthDate = birthDate;
        contender.Type = false;
        return contender;
    }

    private static async Task<FileEntity> EnsureFileAsync(
        LegacyDbContext legacyDbContext,
        int tenantId,
        string code,
        string path)
    {
        var file = await ForFirm<FileEntity>(legacyDbContext, tenantId)
            .SingleOrDefaultAsync(item => item.Code == code);

        if (file == null)
        {
            file = new FileEntity();
            legacyDbContext.Files.Add(file);
            SetFirmId(legacyDbContext, file, tenantId);
        }

        file.Code = code;
        file.Path = path;
        file.type = true;
        return file;
    }

    private static async Task<Consulation> EnsureConsultationAsync(
        LegacyDbContext legacyDbContext,
        int tenantId,
        string subject,
        string consultationState,
        string type,
        string description,
        string feedback,
        string notes,
        DateTime dateTime)
    {
        var consultation = await ForFirm<Consulation>(legacyDbContext, tenantId)
            .SingleOrDefaultAsync(item => item.Subject == subject);

        if (consultation == null)
        {
            consultation = new Consulation();
            legacyDbContext.Consulations.Add(consultation);
            SetFirmId(legacyDbContext, consultation, tenantId);
        }

        consultation.Subject = subject;
        consultation.Consultion_State = consultationState;
        consultation.Type = type;
        consultation.Descraption = description;
        consultation.Feedback = feedback;
        consultation.Notes = notes;
        consultation.Date_time = ToLegacyTimestamp(dateTime);
        return consultation;
    }

    private static async Task EnsureAdministrativeTaskAsync(
        LegacyDbContext legacyDbContext,
        int tenantId,
        string taskName,
        string type,
        DateOnly taskDate,
        DateTime reminderDate,
        string notes,
        int employeeId)
    {
        var task = await ForFirm<AdminstrativeTask>(legacyDbContext, tenantId)
            .SingleOrDefaultAsync(item => item.Task_Name == taskName);

        if (task == null)
        {
            task = new AdminstrativeTask();
            legacyDbContext.AdminstrativeTasks.Add(task);
            SetFirmId(legacyDbContext, task, tenantId);
        }

        task.Task_Name = taskName;
        task.Type = type;
        task.Task_Date = taskDate;
        task.Task_Reminder_Date = ToLegacyTimestamp(reminderDate);
        task.Notes = notes;
        task.employee_Id = employeeId;
    }

    private static async Task EnsureIntakeLeadAsync(
        LegacyDbContext legacyDbContext,
        int tenantId,
        string email,
        string fullName,
        string phoneNumber,
        string subject,
        string description,
        string desiredCaseType,
        string status,
        int assignedEmployeeId,
        int convertedCustomerId,
        int convertedCaseCode)
    {
        var lead = await ForFirm<IntakeLead>(legacyDbContext, tenantId)
            .SingleOrDefaultAsync(item => item.Email == email);

        if (lead == null)
        {
            lead = new IntakeLead();
            legacyDbContext.IntakeLeads.Add(lead);
            SetFirmId(legacyDbContext, lead, tenantId);
        }

        lead.FullName = fullName;
        lead.Email = email;
        lead.PhoneNumber = phoneNumber;
        lead.NationalId = $"NID-{tenantId}";
        lead.Subject = subject;
        lead.Description = description;
        lead.DesiredCaseType = desiredCaseType;
        lead.Status = status;
        lead.QualificationNotes = "Ready for intake";
        lead.ConflictChecked = true;
        lead.HasConflict = false;
        lead.ConflictDetails = null;
        lead.AssignedEmployeeId = assignedEmployeeId;
        lead.NextFollowUpAt = ToLegacyTimestamp(DateTime.UtcNow.AddDays(2));
        lead.AssignedAt = ToLegacyTimestamp(DateTime.UtcNow.AddDays(-1));
        lead.ConvertedCustomerId = convertedCustomerId;
        lead.ConvertedCaseCode = convertedCaseCode;
        lead.CreatedAt = ToLegacyTimestamp(DateTime.UtcNow.AddDays(-4));
        lead.UpdatedAt = ToLegacyTimestamp(DateTime.UtcNow);
    }

    private static async Task EnsureTimeTrackingEntryAsync(
        LegacyDbContext legacyDbContext,
        int tenantId,
        int caseCode,
        int customerId,
        string startedBy,
        string workType,
        string description,
        int durationMinutes,
        decimal suggestedAmount)
    {
        var entry = await ForFirm<TimeTrackingEntry>(legacyDbContext, tenantId)
            .SingleOrDefaultAsync(item => item.CaseCode == caseCode && item.StartedBy == startedBy);

        if (entry == null)
        {
            entry = new TimeTrackingEntry();
            legacyDbContext.TimeTrackingEntries.Add(entry);
            SetFirmId(legacyDbContext, entry, tenantId);
        }

        entry.CaseCode = caseCode;
        entry.CustomerId = customerId;
        entry.WorkType = workType;
        entry.Description = description;
        entry.Status = "Completed";
        entry.StartedBy = startedBy;
        entry.StartedAt = ToLegacyTimestamp(DateTime.UtcNow.AddHours(-5));
        entry.EndedAt = ToLegacyTimestamp(DateTime.UtcNow.AddHours(-3.5));
        entry.DurationMinutes = durationMinutes;
        entry.SuggestedAmount = suggestedAmount;
        entry.UpdatedAt = ToLegacyTimestamp(DateTime.UtcNow);
    }

    private static async Task EnsureTrustLedgerEntryAsync(
        LegacyDbContext legacyDbContext,
        int tenantId,
        string reference,
        int customerId,
        int caseCode,
        string entryType,
        double amount,
        string description,
        string createdBy)
    {
        var entry = await ForFirm<TrustLedgerEntry>(legacyDbContext, tenantId)
            .SingleOrDefaultAsync(item => item.Reference == reference);

        if (entry == null)
        {
            entry = new TrustLedgerEntry();
            legacyDbContext.TrustLedgerEntries.Add(entry);
            SetFirmId(legacyDbContext, entry, tenantId);
        }

        entry.CustomerId = customerId;
        entry.CaseCode = caseCode;
        entry.EntryType = entryType;
        entry.Amount = amount;
        entry.OperationDate = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(-2));
        entry.Description = description;
        entry.Reference = reference;
        entry.CreatedAt = ToLegacyTimestamp(DateTime.UtcNow.AddDays(-2));
        entry.CreatedBy = createdBy;
    }

    private static async Task EnsureCaseEmployeeLinkAsync(
        LegacyDbContext legacyDbContext,
        int tenantId,
        int caseCode,
        int employeeId)
    {
        var link = await ForFirm<Cases_Employee>(legacyDbContext, tenantId)
            .SingleOrDefaultAsync(item => item.Case_Code == caseCode && item.Employee_Id == employeeId);

        if (link == null)
        {
            link = new Cases_Employee
            {
                Case_Code = caseCode,
                Employee_Id = employeeId,
            };

            legacyDbContext.Cases_Employees.Add(link);
            SetFirmId(legacyDbContext, link, tenantId);
        }
    }

    private static async Task EnsureCustomerCaseLinkAsync(
        LegacyDbContext legacyDbContext,
        int tenantId,
        int caseCode,
        int customerId)
    {
        var link = await ForFirm<Custmors_Case>(legacyDbContext, tenantId)
            .SingleOrDefaultAsync(item => item.Case_Id == caseCode && item.Custmors_Id == customerId);

        if (link == null)
        {
            link = new Custmors_Case
            {
                Case_Id = caseCode,
                Custmors_Id = customerId,
            };

            legacyDbContext.Custmors_Cases.Add(link);
            SetFirmId(legacyDbContext, link, tenantId);
        }
    }

    private static async Task EnsureCaseCourtLinkAsync(
        LegacyDbContext legacyDbContext,
        int tenantId,
        int caseCode,
        int courtId)
    {
        var link = await ForFirm<Cases_Court>(legacyDbContext, tenantId)
            .SingleOrDefaultAsync(item => item.Case_Code == caseCode && item.Court_Id == courtId);

        if (link == null)
        {
            link = new Cases_Court
            {
                Case_Code = caseCode,
                Court_Id = courtId,
            };

            legacyDbContext.Cases_Courts.Add(link);
            SetFirmId(legacyDbContext, link, tenantId);
        }
    }

    private static async Task EnsureCaseSitingLinkAsync(
        LegacyDbContext legacyDbContext,
        int tenantId,
        int caseCode,
        int sitingId)
    {
        var link = await ForFirm<Cases_Siting>(legacyDbContext, tenantId)
            .SingleOrDefaultAsync(item => item.Case_Code == caseCode && item.Siting_Id == sitingId);

        if (link == null)
        {
            link = new Cases_Siting
            {
                Case_Code = caseCode,
                Siting_Id = sitingId,
            };

            legacyDbContext.Cases_Sitings.Add(link);
            SetFirmId(legacyDbContext, link, tenantId);
        }
    }

    private static async Task EnsureCaseContenderLinkAsync(
        LegacyDbContext legacyDbContext,
        int tenantId,
        int caseCode,
        int contenderId)
    {
        var link = await ForFirm<Cases_Contender>(legacyDbContext, tenantId)
            .SingleOrDefaultAsync(item => item.Case_Id == caseCode && item.Contender_Id == contenderId);

        if (link == null)
        {
            link = new Cases_Contender
            {
                Case_Id = caseCode,
                Contender_Id = contenderId,
            };

            legacyDbContext.Cases_Contenders.Add(link);
            SetFirmId(legacyDbContext, link, tenantId);
        }
    }

    private static async Task EnsureCaseFileLinkAsync(
        LegacyDbContext legacyDbContext,
        int tenantId,
        int caseCode,
        int fileId)
    {
        var link = await ForFirm<Cases_File>(legacyDbContext, tenantId)
            .SingleOrDefaultAsync(item => item.Case_Id == caseCode && item.File_Id == fileId);

        if (link == null)
        {
            link = new Cases_File
            {
                Case_Id = caseCode,
                File_Id = fileId,
            };

            legacyDbContext.Cases_Files.Add(link);
            SetFirmId(legacyDbContext, link, tenantId);
        }
    }

    private static async Task EnsureConsultationCustomerLinkAsync(
        LegacyDbContext legacyDbContext,
        int tenantId,
        int consultationId,
        int customerId)
    {
        var link = await ForFirm<Consltitions_Custmor>(legacyDbContext, tenantId)
            .SingleOrDefaultAsync(item => item.Consl_Id == consultationId && item.Customer_Id == customerId);

        if (link == null)
        {
            link = new Consltitions_Custmor
            {
                Consl_Id = consultationId,
                Customer_Id = customerId,
            };

            legacyDbContext.Consltitions_Custmors.Add(link);
            SetFirmId(legacyDbContext, link, tenantId);
        }
    }

    private static async Task EnsureConsultationEmployeeLinkAsync(
        LegacyDbContext legacyDbContext,
        int tenantId,
        int consultationId,
        int employeeId)
    {
        var link = await ForFirm<Consulations_Employee>(legacyDbContext, tenantId)
            .SingleOrDefaultAsync(item => item.Consl_ID == consultationId && item.Employee_Id == employeeId);

        if (link == null)
        {
            link = new Consulations_Employee
            {
                Consl_ID = consultationId,
                Employee_Id = employeeId,
            };

            legacyDbContext.Consulations_Employees.Add(link);
            SetFirmId(legacyDbContext, link, tenantId);
        }
    }

    private static async Task EnsureCaseStatusHistoryAsync(
        LegacyDbContext legacyDbContext,
        int tenantId,
        int caseCode,
        int oldStatus,
        int newStatus,
        string changedBy)
    {
        var history = await ForFirm<CaseStatusHistory>(legacyDbContext, tenantId)
            .SingleOrDefaultAsync(item => item.Case_Id == caseCode && item.NewStatus == newStatus && item.ChangedBy == changedBy);

        if (history == null)
        {
            history = new CaseStatusHistory();
            legacyDbContext.CaseStatusHistories.Add(history);
            SetFirmId(legacyDbContext, history, tenantId);
        }

        history.Case_Id = caseCode;
        history.OldStatus = oldStatus;
        history.NewStatus = newStatus;
        history.ChangedBy = changedBy;
        history.ChangedAt = ToLegacyTimestamp(DateTime.UtcNow.AddDays(-1));
    }

    private static DateTime ToLegacyTimestamp(DateTime value)
    {
        var normalized = value.Kind == DateTimeKind.Utc
            ? value.ToLocalTime()
            : value;

        return DateTime.SpecifyKind(normalized, DateTimeKind.Unspecified);
    }

    private static void NormalizePendingLegacyDateTimes(LegacyDbContext legacyDbContext)
    {
        foreach (var entry in legacyDbContext.ChangeTracker.Entries().Where(item => item.State is EntityState.Added or EntityState.Modified))
        {
            foreach (var property in entry.Properties)
            {
                if (property.CurrentValue is DateTime current)
                {
                    property.CurrentValue = ToLegacyTimestamp(current);
                }

                if (property.OriginalValue is DateTime original)
                {
                    property.OriginalValue = ToLegacyTimestamp(original);
                }
            }
        }
    }

    private static IQueryable<TEntity> ForFirm<TEntity>(LegacyDbContext legacyDbContext, int tenantId)
        where TEntity : class
    {
        return legacyDbContext.Set<TEntity>()
            .IgnoreQueryFilters()
            .Where(item => EF.Property<int>(item, "FirmId") == tenantId);
    }

    private static void SetFirmId<TEntity>(LegacyDbContext legacyDbContext, TEntity entity, int tenantId)
        where TEntity : class
    {
        legacyDbContext.Entry(entity).Property("FirmId").CurrentValue = tenantId;
    }

    private static string Normalize(string? value, string fallback)
    {
        return string.IsNullOrWhiteSpace(value) ? fallback : value.Trim();
    }

    private static void EnsureIdentitySucceeded(IdentityResult result)
    {
        if (result.Succeeded)
        {
            return;
        }

        throw new InvalidOperationException(string.Join(", ", result.Errors.Select(item => item.Description)));
    }

    private sealed record CountrySeedDefinition(string Name, string NameAr);

    private sealed record SubscriptionPackageSeedResult(SubscriptionPackage Monthly, SubscriptionPackage Annual);

    private sealed record DemoTenantDefinition(
        string Slug,
        string ShortName,
        string Name,
        string ContactEmail,
        string PhoneNumber,
        Country Country,
        string CityName,
        string CityNameAr,
        string AdminEmail,
        string AdminUserName,
        string AdminPhone,
        string EmployeeEmail,
        string EmployeeUserName,
        string EmployeePhone,
        string CustomerEmail,
        string CustomerUserName,
        string CustomerPhone,
        bool IsActive,
        DemoSubscriptionScenario SubscriptionScenario,
        string NotificationTitle,
        string NotificationTitleAr,
        string NotificationMessage,
        string NotificationMessageAr);

    private enum DemoSubscriptionScenario
    {
        ActiveMonthly = 1,
        ActiveAnnual = 2,
        PendingActivationMonthly = 3,
        ExpiredAnnual = 4,
    }
}
