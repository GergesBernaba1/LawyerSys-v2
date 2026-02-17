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

        [Fact]
        public async Task JudicialDocuments_Paginated_ReturnsCorrectPage()
        {
            using var ctx = CreateInMemoryContext("paging_judicial_docs");
            var user = new User { Id = 1, User_Name = "alice", Full_Name = "Alice" , Password = "x" , Date_Of_Birth = System.DateOnly.FromDateTime(System.DateTime.UtcNow), Phon_Number = 0, Job = "" , SSN = 0 };
            ctx.Users.Add(user);
            var customer = new Customer { Id = 10, Users_Id = user.Id, Users = user };
            ctx.Customers.Add(customer);

            // add 5 documents
            for (int i = 1; i <= 5; i++)
            {
                ctx.Judicial_Documents.Add(new Judicial_Document { Id = i, Doc_Type = i % 2 == 0 ? "Contract" : "Note", Doc_Num = 100 + i, Doc_Details = "details" + i, Customers_Id = customer.Id, Customers = customer });
            }
            await ctx.SaveChangesAsync();

            var controller = new JudicialDocumentsController(ctx);
            var actionResult = await controller.GetDocuments(2, 2, null);
            var ok = Assert.IsType<OkObjectResult>(actionResult.Result);
            var paged = Assert.IsType<LawyerSys.DTOs.PagedResult<LawyerSys.DTOs.JudicialDocumentDto>>(ok.Value);

            Assert.Equal(5, paged.TotalCount);
            Assert.Equal(2, paged.Page);
            Assert.Equal(2, paged.PageSize);
            Assert.Equal(3, paged.TotalPages);
            Assert.Equal(2, paged.Items.Count());
            Assert.Equal(3, paged.Items.First().Id);
        }

        [Fact]
        public async Task JudicialDocuments_SearchByCustomerName_ReturnsMatching()
        {
            using var ctx = CreateInMemoryContext("search_judicial_docs");
            var user = new User { Id = 2, User_Name = "bob", Full_Name = "Bob Smith" , Password = "x" , Date_Of_Birth = System.DateOnly.FromDateTime(System.DateTime.UtcNow), Phon_Number = 0, Job = "" , SSN = 0 };
            ctx.Users.Add(user);
            var customer = new Customer { Id = 20, Users_Id = user.Id, Users = user };
            ctx.Customers.Add(customer);

            ctx.Judicial_Documents.Add(new Judicial_Document { Id = 1, Doc_Type = "Contract", Doc_Num = 555, Doc_Details = "Signed", Customers_Id = customer.Id, Customers = customer });
            ctx.Judicial_Documents.Add(new Judicial_Document { Id = 2, Doc_Type = "Note", Doc_Num = 556, Doc_Details = "Other", Customers_Id = customer.Id, Customers = customer });
            await ctx.SaveChangesAsync();

            var controller = new JudicialDocumentsController(ctx);
            var actionResult = await controller.GetDocuments(1, 10, "Bob");
            var ok = Assert.IsType<OkObjectResult>(actionResult.Result);
            var paged = Assert.IsType<LawyerSys.DTOs.PagedResult<LawyerSys.DTOs.JudicialDocumentDto>>(ok.Value);

            Assert.Equal(1, paged.TotalCount);
            Assert.Single(paged.Items);
            Assert.Equal(1, paged.Items.First().Id);
        }

        [Fact]
        public async Task AdminTasks_PaginatedAndSearchByEmployee_ReturnsMatching()
        {
            using var ctx = CreateInMemoryContext("paging_admin_tasks");
            var user = new User { Id = 3, User_Name = "jane", Full_Name = "Jane Manager" , Password = "x" , Date_Of_Birth = System.DateOnly.FromDateTime(System.DateTime.UtcNow), Phon_Number = 0, Job = "" , SSN = 0 };
            ctx.Users.Add(user);
            var employee = new Employee { id = 50, Users_Id = user.Id, Users = user };
            ctx.Employees.Add(employee);

            // create 4 tasks, one assigned to Jane
            ctx.AdminstrativeTasks.AddRange(
                new AdminstrativeTask { Id = 1, Task_Name = "T1", Type = "A", Notes = "n1" },
                new AdminstrativeTask { Id = 2, Task_Name = "T2", Type = "B", Notes = "n2", employee_Id = employee.id, employee = employee },
                new AdminstrativeTask { Id = 3, Task_Name = "T3", Type = "A", Notes = "n3" },
                new AdminstrativeTask { Id = 4, Task_Name = "T4", Type = "B", Notes = "n4" }
            );
            await ctx.SaveChangesAsync();

            var controller = new AdminTasksController(ctx);
            var actionResult = await controller.GetAdminTasks(1, 2, null);
            var ok = Assert.IsType<OkObjectResult>(actionResult.Result);
            var paged = Assert.IsType<LawyerSys.DTOs.PagedResult<LawyerSys.DTOs.AdminTaskDto>>(ok.Value);

            Assert.Equal(4, paged.TotalCount);
            Assert.Equal(2, paged.Items.Count());

            // now search by employee name
            var actionSearch = await controller.GetAdminTasks(1, 10, "Jane");
            var ok2 = Assert.IsType<OkObjectResult>(actionSearch.Result);
            var paged2 = Assert.IsType<LawyerSys.DTOs.PagedResult<LawyerSys.DTOs.AdminTaskDto>>(ok2.Value);
            Assert.Equal(1, paged2.TotalCount);
            Assert.Equal(2, paged2.Items.First().Id == 2 ? 1 : 0);
        }

        [Fact]
        public async Task ChangeCaseStatus_AsAssignedEmployee_RecordsHistory()
        {
            using var ctx = CreateInMemoryContext("status_change_employee");
            ctx.Cases.Add(new Case { Code = 900, Invitions_Statment = "s", Invition_Type = "t", Invition_Date = System.DateOnly.FromDateTime(System.DateTime.UtcNow), Total_Amount = 0, Notes = "n", Status = 0 });

            var legacyUser = new User { Id = 11, User_Name = "empx", Full_Name = "Emp X", Password = "x" , Date_Of_Birth = System.DateOnly.FromDateTime(System.DateTime.UtcNow), Phon_Number = 0, Job = "" , SSN = 0 };
            ctx.Users.Add(legacyUser);
            var employee = new Employee { id = 77, Users_Id = legacyUser.Id, Users = legacyUser };
            ctx.Employees.Add(employee);

            // assign employee to case
            ctx.Cases_Employees.Add(new Cases_Employee { Case_Code = 900, Employee_Id = employee.id });
            await ctx.SaveChangesAsync();

            var userCtx = new TestUserContext("uX", "empx", "Employee");
            var controller = new CasesController(ctx, userCtx);

            var res = await controller.ChangeCaseStatus(900, new LawyerSys.DTOs.ChangeCaseStatusDto { Status = "InProgress" });
            var ok = Assert.IsType<OkObjectResult>(res);
            var dto = Assert.IsType<LawyerSys.DTOs.CaseDto>(ok.Value);
            Assert.Equal(LawyerSys.DTOs.CaseStatus.InProgress, dto.Status);

            var history = ctx.CaseStatusHistories.Where(h => h.Case_Id == 900).ToList();
            Assert.Single(history);
            Assert.Equal(0, history.First().OldStatus);
            Assert.Equal(1, history.First().NewStatus);
        }

        [Fact]
        public async Task ChangeCaseStatus_AsCustomer_IsForbidden()
        {
            using var ctx = CreateInMemoryContext("status_change_customer");
            ctx.Cases.Add(new Case { Code = 901, Invitions_Statment = "s", Invition_Type = "t", Invition_Date = System.DateOnly.FromDateTime(System.DateTime.UtcNow), Total_Amount = 0, Notes = "n", Status = 0 });

            var legacyUser = new User { Id = 12, User_Name = "custx", Full_Name = "Cust X", Password = "x" , Date_Of_Birth = System.DateOnly.FromDateTime(System.DateTime.UtcNow), Phon_Number = 0, Job = "" , SSN = 0 };
            ctx.Users.Add(legacyUser);
            var customer = new Customer { Id = 88, Users_Id = legacyUser.Id, Users = legacyUser };
            ctx.Customers.Add(customer);

            await ctx.SaveChangesAsync();

            var userCtx = new TestUserContext("uC", "custx", "Customer");
            var controller = new CasesController(ctx, userCtx);

            var res = await controller.ChangeCaseStatus(901, new LawyerSys.DTOs.ChangeCaseStatusDto { Status = "InProgress" });
            Assert.IsType<ForbidResult>(res);
        }
    }
}
