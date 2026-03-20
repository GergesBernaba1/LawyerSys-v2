using System.Threading.Tasks;
using LawyerSys.Services;
using Xunit;

namespace LawyerSys.Tests;

public class ServiceResultContractTests
{
    [Fact]
    public void SuccessResult_StoresPayloadAndStatus()
    {
        var result = ServiceResult<string>.Success("ok");

        Assert.True(result.IsSuccess);
        Assert.Equal(ServiceResultStatus.Success, result.Status);
        Assert.Equal("ok", result.Payload);
    }

    [Fact]
    public void ValidationResult_StoresIssues()
    {
        var issue = new ValidationIssue
        {
            Field = "NameEn",
            Code = "required",
            MessageKey = "EnglishCityNameRequired"
        };

        var result = ServiceResult<object>.Validation("ValidationFailed", issue);

        Assert.Equal(ServiceResultStatus.ValidationFailed, result.Status);
        Assert.Single(result.ValidationIssues);
        Assert.Equal("NameEn", result.ValidationIssues[0].Field);
    }

    [Fact]
    public async Task OperationContextFactory_CapturesCurrentUserRolesAndTenant()
    {
        var userContext = new Infrastructure.TestUserContext(userId: "user-1", userName: "admin", tenantId: 7, roles: new[] { "Admin", "Employee" });
        var factory = new ServiceOperationContextFactory(userContext);

        var context = await factory.CreateAsync();

        Assert.Equal("user-1", context.UserId);
        Assert.Equal("admin", context.UserName);
        Assert.Equal(7, context.TenantId);
        Assert.True(context.IsInRole("Admin"));
        Assert.True(context.IsInRole("Employee"));
    }
}
