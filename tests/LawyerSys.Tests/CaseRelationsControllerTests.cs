using System.Threading;
using System.Threading.Tasks;
using LawyerSys.Controllers;
using LawyerSys.Services;
using LawyerSys.Services.CaseRelations;
using LawyerSys.Tests.Infrastructure;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Moq;
using Xunit;

namespace LawyerSys.Tests;

public class CaseRelationsControllerTests
{
    [Fact]
    public async Task GetCaseSitings_WhenServiceReturnsForbidden_MapsToForbid()
    {
        var service = new Mock<ICaseRelationsService>();
        service.Setup(item => item.GetCaseSitingsAsync(12, It.IsAny<CancellationToken>()))
            .ReturnsAsync(ServiceResult<object>.Forbidden("Forbidden"));

        var controller = new CaseRelationsController(service.Object, new TestStringLocalizer<LawyerSys.Resources.SharedResource>());
        controller.ControllerContext = new ControllerContext { HttpContext = new DefaultHttpContext() };

        var result = await controller.GetCaseSitings(12);

        Assert.IsType<ForbidResult>(result);
    }

    [Fact]
    public async Task AddCustomerToCase_WhenServiceSucceeds_ReturnsOkWithId()
    {
        var service = new Mock<ICaseRelationsService>();
        service.Setup(item => item.AddCustomerToCaseAsync(12, 4, It.IsAny<CancellationToken>()))
            .ReturnsAsync(ServiceResult<int>.Success(88));

        var controller = new CaseRelationsController(service.Object, new TestStringLocalizer<LawyerSys.Resources.SharedResource>());
        controller.ControllerContext = new ControllerContext { HttpContext = new DefaultHttpContext() };

        var result = await controller.AddCustomerToCase(12, 4);

        Assert.IsType<OkObjectResult>(result);
    }
}
