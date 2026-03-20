using System;
using System.Threading.Tasks;
using LawyerSys.Data.ScaffoldedModels;
using LawyerSys.DTOs;
using LawyerSys.Services;
using LawyerSys.Services.Governments;
using LawyerSys.Tests.Infrastructure;
using Xunit;

namespace LawyerSys.Tests;

public class GovernmentsServiceTests
{
    [Fact]
    public async Task CreateGovernment_WhenNameExists_ReturnsConflict()
    {
        using var legacyDb = ControllerRefactorTestHost.CreateLegacyDbContext(nameof(CreateGovernment_WhenNameExists_ReturnsConflict));
        using var appDb = ControllerRefactorTestHost.CreateApplicationDbContext(nameof(CreateGovernment_WhenNameExists_ReturnsConflict));
        legacyDb.Governaments.Add(new Governament { Id = 1, Gov_Name = "Cairo" });
        await legacyDb.SaveChangesAsync();

        var service = new GovernmentsService(
            legacyDb,
            appDb,
            new ServiceOperationContextFactory(new TestUserContext(userId: "admin-1", userName: "admin", tenantId: 1, roles: new[] { "Admin" })));

        var result = await service.CreateGovernmentAsync(new CreateGovernamentDto { GovName = "Cairo" });

        Assert.Equal(ServiceResultStatus.Conflict, result.Status);
        Assert.Equal("GovernmentNameExists", result.MessageKey);
    }

    [Fact]
    public async Task GetLocationCatalog_ForTenantUser_UsesProfileCountry()
    {
        using var legacyDb = ControllerRefactorTestHost.CreateLegacyDbContext(nameof(GetLocationCatalog_ForTenantUser_UsesProfileCountry));
        using var appDb = ControllerRefactorTestHost.CreateApplicationDbContext(nameof(GetLocationCatalog_ForTenantUser_UsesProfileCountry));

        appDb.Countries.AddRange(
            new Country { Id = 1, Name = "Egypt", NameAr = "مصر" },
            new Country { Id = 2, Name = "Jordan", NameAr = "الأردن" });
        appDb.Cities.AddRange(
            new City { Id = 1, CountryId = 1, Name = "Cairo", NameAr = "القاهرة" },
            new City { Id = 2, CountryId = 2, Name = "Amman", NameAr = "عمان" });
        appDb.Users.Add(new ApplicationUser { Id = "user-1", UserName = "tenant.user", TenantId = 5, CountryId = 1 });
        await appDb.SaveChangesAsync();

        var service = new GovernmentsService(
            legacyDb,
            appDb,
            new ServiceOperationContextFactory(new TestUserContext("user-1", "tenant.user", email: null, tenantId: 5, roles: new[] { "Admin" })));

        var result = await service.GetLocationCatalogAsync(2);

        Assert.Single(result);
        Assert.Equal(1, result[0].Id);
        Assert.Single(result[0].Cities);
        Assert.Equal("Cairo", result[0].Cities[0].NameEn);
    }
}
