using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Threading.Tasks;
using LawyerSys.Data;
using LawyerSys.Resources;
using LawyerSys.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Localization;

namespace LawyerSys.Tests.Infrastructure;

internal static class ControllerRefactorTestHost
{
    public static LegacyDbContext CreateLegacyDbContext(string databaseName)
    {
        var options = new DbContextOptionsBuilder<LegacyDbContext>()
            .UseInMemoryDatabase(databaseName)
            .Options;
        return new LegacyDbContext(options);
    }

    public static ApplicationDbContext CreateApplicationDbContext(string databaseName)
    {
        var options = new DbContextOptionsBuilder<ApplicationDbContext>()
            .UseInMemoryDatabase(databaseName)
            .Options;
        return new ApplicationDbContext(options);
    }
}

internal sealed class TestUserContext : IUserContext
{
    private readonly string? _userId;
    private readonly string? _userName;
    private readonly string? _email;
    private readonly int? _tenantId;
    private readonly IList<string> _roles;

    public TestUserContext(string? userId, string? userName, string? email = null, int? tenantId = null, params string[] roles)
    {
        _userId = userId;
        _userName = userName;
        _email = email;
        _tenantId = tenantId;
        _roles = roles.ToList();
    }
    
    public string? GetUserId() => _userId;
    public string? GetUserName() => _userName;
    public string? GetEmail() => _email;
    public int? GetTenantId() => _tenantId;
    public Task<bool> IsInRoleAsync(string role) => Task.FromResult(_roles.Contains(role));
    public Task<IList<string>> GetUserRolesAsync() => Task.FromResult(_roles);
}

internal sealed class TestStringLocalizer<T> : IStringLocalizer<T>
{
    public LocalizedString this[string name] => new(name, name, resourceNotFound: false);

    public LocalizedString this[string name, params object[] arguments]
        => new(name, string.Format(CultureInfo.InvariantCulture, name + (arguments.Length == 0 ? string.Empty : ":" + string.Join("|", arguments))), resourceNotFound: false);

    public IEnumerable<LocalizedString> GetAllStrings(bool includeParentCultures)
        => Array.Empty<LocalizedString>();

    public IStringLocalizer WithCulture(CultureInfo culture) => this;
}
