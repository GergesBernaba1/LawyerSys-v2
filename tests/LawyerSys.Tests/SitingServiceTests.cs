using System;
using System.Linq;
using System.Threading.Tasks;
using LawyerSys.Data;
using LawyerSys.Data.ScaffoldedModels;
using LawyerSys.Services;
using LawyerSys.Services.Notifications;
using LawyerSys.Tests.Infrastructure;
using Microsoft.EntityFrameworkCore;
using Moq;
using Xunit;

namespace LawyerSys.Tests
{
    public class SitingServiceTests
    {
        [Fact]
        public async Task GetSitingsAsync_InvalidPageAndPageSize_ClampsToDefaults()
        {
            using var legacyDb = ControllerRefactorTestHost.CreateLegacyDbContext(nameof(GetSitingsAsync_InvalidPageAndPageSize_ClampsToDefaults));

            for (int i = 1; i <= 25; i++)
            {
                legacyDb.Sitings.Add(new Siting
                {
                    Siting_Date = DateOnly.FromDateTime(DateTime.UtcNow),
                    Siting_Time = DateTime.UtcNow,
                    Siting_Notification = DateTime.UtcNow,
                    Judge_Name = $"Judge{i}",
                    Notes = "n"
                });
            }
            await legacyDb.SaveChangesAsync();

            var employeeAccessService = new Mock<IEmployeeAccessService>();
            employeeAccessService.Setup(x => x.IsCurrentUserEmployeeOnlyAsync()).ReturnsAsync(false);

            var service = new SitingService(legacyDb, employeeAccessService.Object, Mock.Of<IInAppNotificationService>());

            var result = await service.GetSitingsAsync(page: 0, pageSize: 0, search: null);

            Assert.Equal(1, result.Page);
            Assert.Equal(10, result.PageSize);
            Assert.Equal(25, result.TotalCount);
            Assert.Equal(10, result.Items.Count());
            Assert.Equal(1, result.Items.First().Id);
        }

        [Fact]
        public async Task GetSitingsAsync_PageSizeAboveMax_ClampsToMax()
        {
            using var legacyDb = ControllerRefactorTestHost.CreateLegacyDbContext(nameof(GetSitingsAsync_PageSizeAboveMax_ClampsToMax));

            for (int i = 1; i <= 120; i++)
            {
                legacyDb.Sitings.Add(new Siting
                {
                    Siting_Date = DateOnly.FromDateTime(DateTime.UtcNow),
                    Siting_Time = DateTime.UtcNow,
                    Siting_Notification = DateTime.UtcNow,
                    Judge_Name = $"Judge{i}",
                    Notes = "n"
                });
            }
            await legacyDb.SaveChangesAsync();

            var employeeAccessService = new Mock<IEmployeeAccessService>();
            employeeAccessService.Setup(x => x.IsCurrentUserEmployeeOnlyAsync()).ReturnsAsync(false);

            var service = new SitingService(legacyDb, employeeAccessService.Object, Mock.Of<IInAppNotificationService>());

            var result = await service.GetSitingsAsync(page: 1, pageSize: 150, search: null);

            Assert.Equal(1, result.Page);
            Assert.Equal(100, result.PageSize);
            Assert.Equal(120, result.TotalCount);
            Assert.Equal(100, result.Items.Count());
        }

        [Fact]
        public async Task GetSitingAsync_EmployeeWithoutAssignedCase_ThrowsUnauthorizedAccessException()
        {
            using var legacyDb = ControllerRefactorTestHost.CreateLegacyDbContext(nameof(GetSitingAsync_EmployeeWithoutAssignedCase_ThrowsUnauthorizedAccessException));

            var siting = new Siting
            {
                Siting_Date = DateOnly.FromDateTime(DateTime.UtcNow),
                Siting_Time = DateTime.UtcNow,
                Siting_Notification = DateTime.UtcNow,
                Judge_Name = "JudgeX",
                Notes = "n"
            };

            legacyDb.Sitings.Add(siting);
            await legacyDb.SaveChangesAsync();

            legacyDb.Cases_Sitings.Add(new Cases_Siting { Case_Code = 123, Siting_Id = siting.Id });
            await legacyDb.SaveChangesAsync();

            var employeeAccessService = new Mock<IEmployeeAccessService>();
            employeeAccessService.Setup(x => x.IsCurrentUserEmployeeOnlyAsync()).ReturnsAsync(true);
            employeeAccessService.Setup(x => x.CanAccessCaseAsync(It.IsAny<int>())).ReturnsAsync(false);

            var service = new SitingService(legacyDb, employeeAccessService.Object, Mock.Of<IInAppNotificationService>());

            await Assert.ThrowsAsync<UnauthorizedAccessException>(() => service.GetSitingAsync(siting.Id));
        }
    }
}
