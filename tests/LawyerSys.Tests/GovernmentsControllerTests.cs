using System.Threading;
using System.Threading.Tasks;
using LawyerSys.Controllers;
using LawyerSys.DTOs;
using LawyerSys.Services;
using LawyerSys.Services.Governments;
using LawyerSys.Tests.Infrastructure;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Moq;
using Xunit;

namespace LawyerSys.Tests;

public class GovernmentsControllerTests
{
    [Fact]
    public async Task GetGovernment_WhenServiceReturnsNotFound_MapsToNotFound()
    {
        var service = new Mock<IGovernmentsService>();
        service.Setup(item => item.GetGovernmentAsync(5, It.IsAny<CancellationToken>()))
            .ReturnsAsync(ServiceResult<GovernamentDto>.NotFound("Government"));

        var controller = new GovernmentsController(service.Object, new TestStringLocalizer<LawyerSys.Resources.SharedResource>());
        controller.ControllerContext = new ControllerContext { HttpContext = new DefaultHttpContext() };

        var result = await controller.GetGovernment(5);

        Assert.IsType<NotFoundObjectResult>(result.Result);
    }

    [Fact]
    public async Task CreateGovernment_WhenServiceSucceeds_MapsToCreatedAtAction()
    {
        var service = new Mock<IGovernmentsService>();
        service.Setup(item => item.CreateGovernmentAsync(It.IsAny<CreateGovernamentDto>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(ServiceResult<GovernamentDto>.Success(new GovernamentDto { Id = 9, GovName = "Giza" }));

        var controller = new GovernmentsController(service.Object, new TestStringLocalizer<LawyerSys.Resources.SharedResource>());
        controller.ControllerContext = new ControllerContext { HttpContext = new DefaultHttpContext() };

        var result = await controller.CreateGovernment(new CreateGovernamentDto { GovName = "Giza" });

        Assert.IsType<CreatedAtActionResult>(result.Result);
    }
}
