using System.Text.Json;
using LawyerSys.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace LawyerSys.Infrastructure.Data.DesignTime;

public sealed class LegacyDbContextFactory : IDesignTimeDbContextFactory<LegacyDbContext>
{
    public LegacyDbContext CreateDbContext(string[] args)
    {
        var optionsBuilder = new DbContextOptionsBuilder<LegacyDbContext>();
        optionsBuilder.UseNpgsql(
            DesignTimeConnectionStringResolver.Resolve(),
            sql => sql.MigrationsAssembly("LawyerSys.Infrastructure"));
        return new LegacyDbContext(optionsBuilder.Options);
    }
}

public sealed class ApplicationDbContextFactory : IDesignTimeDbContextFactory<ApplicationDbContext>
{
    public ApplicationDbContext CreateDbContext(string[] args)
    {
        var optionsBuilder = new DbContextOptionsBuilder<ApplicationDbContext>();
        optionsBuilder.UseNpgsql(
            DesignTimeConnectionStringResolver.Resolve(),
            sql => sql.MigrationsAssembly("LawyerSys.Infrastructure"));
        return new ApplicationDbContext(optionsBuilder.Options);
    }
}

internal static class DesignTimeConnectionStringResolver
{
    internal static string Resolve()
    {
        var fromEnv = Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection");
        if (!string.IsNullOrWhiteSpace(fromEnv))
        {
            return fromEnv;
        }

        foreach (var path in CandidateConfigPaths())
        {
            if (!File.Exists(path))
            {
                continue;
            }

            using var doc = JsonDocument.Parse(File.ReadAllText(path));
            if (doc.RootElement.TryGetProperty("ConnectionStrings", out var csRoot) &&
                csRoot.TryGetProperty("DefaultConnection", out var value) &&
                !string.IsNullOrWhiteSpace(value.GetString()))
            {
                return value.GetString()!;
            }
        }

        throw new InvalidOperationException("Unable to resolve ConnectionStrings:DefaultConnection for EF design-time operations.");
    }

    private static IEnumerable<string> CandidateConfigPaths()
    {
        var current = Directory.GetCurrentDirectory();
        yield return Path.Combine(current, "LawyerSys", "appsettings.json");
        yield return Path.Combine(current, "..", "LawyerSys", "appsettings.json");
        yield return Path.Combine(current, "appsettings.json");
        yield return Path.Combine(AppContext.BaseDirectory, "appsettings.json");
    }
}
