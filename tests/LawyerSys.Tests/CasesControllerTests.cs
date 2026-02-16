using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Moq;
using Xunit;
using LawyerSys.Controllers;
using LawyerSys.Data;
using LawyerSys.Data.ScaffoldedModels;
using LawyerSys.Services;
using System.Linq;

namespace LawyerSys.Tests
{
    class TestUserContext : IUserContext
    {
        private readonly string? _userId;
        private readonly string? _userName;
        private readonly IList<string> _roles;

        public TestUserContext(string? userId, string? userName, params string[] roles)
        {
            _userId = userId;
            _userName = userName;
            _roles = roles.ToList();
        }

        public string? GetUserId() => _userId;
        public string? GetUserName() => _userName;
        public string? GetEmail() => null;
        public Task<bool> IsInRoleAsync(string role) => Task.FromResult(_roles.Contains(role));
        public Task<IList<string>> GetUserRolesAsync() => Task.FromResult((IList<string>)_roles);
    }

    public class CasesControllerTests
    {
        private static LegacyDbContext CreateInMemoryContext(string dbName)
        {
            var options = new DbContextOptionsBuilder<LegacyDbContext>()
                .UseInMemoryDatabase(dbName)
                .Options;
            return new LegacyDbContext(options);
        }

        [Fact]
        public async Task GetCases_AsAdmin_ReturnsAllCases()
        {
            using var ctx = CreateInMemoryContext("admin_all_cases");
            ctx.Cases.AddRange(new Case { Code = 100 }, new Case { Code = 200 });
            await ctx.SaveChangesAsync();

            var userCtx = new TestUserContext("u1", "admin", "Admin");
            var controller = new CasesController(ctx, userCtx);

            var actionResult = await controller.GetCases(null, null, null);
            var value = Assert.IsType<OkObjectResult>(actionResult.Result);
            var list = Assert.IsAssignableFrom<IEnumerable<LawyerSys.DTOs.CaseDto>>(value.Value);
            Assert.Equal(2, list.Count());
        }

        [Fact]
        public async Task GetCases_Paginated_ReturnsCorrectPage()
        {
            using var ctx = CreateInMemoryContext("paging_cases");
            for (int i = 1; i <= 12; i++) ctx.Cases.Add(new Case { Code = i, Invition_Type = "T", Notes = "n" });
            await ctx.SaveChangesAsync();

            var userCtx = new TestUserContext("u1", "admin", "Admin");
            var controller = new CasesController(ctx, userCtx);

            var actionResult = await controller.GetCases(2, 5, null);
            var ok = Assert.IsType<OkObjectResult>(actionResult.Result);
            var paged = Assert.IsType<LawyerSys.DTOs.PagedResult<LawyerSys.DTOs.CaseDto>>(ok.Value);

            Assert.Equal(12, paged.TotalCount);
            Assert.Equal(2, paged.Page);
            Assert.Equal(5, paged.PageSize);
            Assert.Equal(3, paged.TotalPages);
            Assert.Equal(5, paged.Items.Count());
            Assert.Equal(6, paged.Items.First().Code);
        }
        [Fact]
        public async Task GetCases_AsEmployee_ReturnsAssignedOnly()
        {
            using var ctx = CreateInMemoryContext("employee_cases");
            ctx.Cases.AddRange(new Case { Code = 11 }, new Case { Code = 22 });

            // legacy user + employee
            var legacyUser = new User { Id = 1, User_Name = "emp1", Full_Name = "Emp One", Password = "x" , Date_Of_Birth = System.DateOnly.FromDateTime(System.DateTime.UtcNow), Phon_Number = 0, Job = "" , SSN = 0 };
            ctx.Users.Add(legacyUser);
            var employee = new Employee { id = 10, Users_Id = legacyUser.Id, Users = legacyUser };
            ctx.Employees.Add(employee);

            // Link employee to case Code = 11
            ctx.Cases_Employees.Add(new Cases_Employee { Case_Code = 11, Employee_Id = employee.id });

            await ctx.SaveChangesAsync();

            var userCtx = new TestUserContext("u2", "emp1", "Employee");
            var controller = new CasesController(ctx, userCtx);

            var actionResult = await controller.GetCases();
            var value = Assert.IsType<OkObjectResult>(actionResult.Result);
            var list = Assert.IsAssignableFrom<IEnumerable<LawyerSys.DTOs.CaseDto>>(value.Value);
            Assert.Single(list);
            Assert.Equal(11, list.First().Code);
        }

        [Fact]
        public async Task GetCases_AsCustomer_ReturnsLinkedOnly()
        {
            using var ctx = CreateInMemoryContext("customer_cases");
            ctx.Cases.AddRange(new Case { Code = 7 }, new Case { Code = 8 });

            var legacyUser = new User { Id = 5, User_Name = "cust1", Full_Name = "Cust One", Password = "x" , Date_Of_Birth = System.DateOnly.FromDateTime(System.DateTime.UtcNow), Phon_Number = 0, Job = "" , SSN = 0 };
            ctx.Users.Add(legacyUser);
            var customer = new Customer { Id = 3, Users_Id = legacyUser.Id, Users = legacyUser };
            ctx.Customers.Add(customer);

            // Link customer to Case 8
            ctx.Custmors_Cases.Add(new Custmors_Case { Case_Id = 8, Custmors_Id = customer.Id });

            await ctx.SaveChangesAsync();

            var userCtx = new TestUserContext("u3", "cust1", "Customer");
            var controller = new CasesController(ctx, userCtx);

            var actionResult = await controller.GetCases();
            var value = Assert.IsType<OkObjectResult>(actionResult.Result);
            var list = Assert.IsAssignableFrom<IEnumerable<LawyerSys.DTOs.CaseDto>>(value.Value);
            Assert.Single(list);
            Assert.Equal(8, list.First().Code);
        }
    }
}
