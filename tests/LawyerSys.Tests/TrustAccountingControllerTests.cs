using System;
using System.Threading.Tasks;
using LawyerSys.Controllers;
using LawyerSys.Data;
using LawyerSys.Data.ScaffoldedModels;
using LawyerSys.DTOs;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace LawyerSys.Tests;

public class TrustAccountingControllerTests
{
    private static LegacyDbContext CreateInMemoryContext(string dbName)
    {
        var options = new DbContextOptionsBuilder<LegacyDbContext>()
            .UseInMemoryDatabase(dbName)
            .Options;
        return new LegacyDbContext(options);
    }

    [Fact]
    public async Task CreateWithdrawal_WhenInsufficientBalance_ReturnsBadRequest()
    {
        using var ctx = CreateInMemoryContext(nameof(CreateWithdrawal_WhenInsufficientBalance_ReturnsBadRequest));
        var user = new User
        {
            Id = 101,
            Full_Name = "Client One",
            User_Name = "client.one",
            Password = "x",
            Job = "Client",
            Date_Of_Birth = DateOnly.FromDateTime(DateTime.UtcNow),
            Phon_Number = 0,
            SSN = 1
        };
        var customer = new Customer { Id = 10, Users_Id = user.Id, Users = user };
        ctx.Users.Add(user);
        ctx.Customers.Add(customer);
        await ctx.SaveChangesAsync();

        var controller = new TrustAccountingController(ctx);
        await controller.CreateDeposit(new CreateTrustDepositDto
        {
            CustomerId = customer.Id,
            Amount = 100,
            OperationDate = DateOnly.FromDateTime(DateTime.UtcNow),
            Description = "Initial trust deposit"
        });

        var result = await controller.CreateWithdrawal(new CreateTrustWithdrawalDto
        {
            CustomerId = customer.Id,
            Amount = 150,
            OperationDate = DateOnly.FromDateTime(DateTime.UtcNow),
            Description = "Too large withdrawal"
        });

        Assert.IsType<BadRequestObjectResult>(result.Result);
    }

    [Fact]
    public async Task CreateReconciliation_ComputesExpectedDifferences()
    {
        using var ctx = CreateInMemoryContext(nameof(CreateReconciliation_ComputesExpectedDifferences));
        var user = new User
        {
            Id = 102,
            Full_Name = "Client Two",
            User_Name = "client.two",
            Password = "x",
            Job = "Client",
            Date_Of_Birth = DateOnly.FromDateTime(DateTime.UtcNow),
            Phon_Number = 0,
            SSN = 2
        };
        var customer = new Customer { Id = 20, Users_Id = user.Id, Users = user };
        ctx.Users.Add(user);
        ctx.Customers.Add(customer);
        await ctx.SaveChangesAsync();

        var controller = new TrustAccountingController(ctx);
        await controller.CreateDeposit(new CreateTrustDepositDto
        {
            CustomerId = customer.Id,
            Amount = 100,
            OperationDate = DateOnly.FromDateTime(DateTime.UtcNow),
            Description = "Trust funding"
        });

        var action = await controller.CreateReconciliation(new CreateTrustReconciliationDto
        {
            ReconciliationDate = DateOnly.FromDateTime(DateTime.UtcNow),
            BankStatementBalance = 130,
            Notes = "Monthly close"
        });

        var ok = Assert.IsType<OkObjectResult>(action.Result);
        var dto = Assert.IsType<TrustReconciliationDto>(ok.Value);

        Assert.Equal(100, dto.BookBalance);
        Assert.Equal(100, dto.ClientLedgerBalance);
        Assert.Equal(30, dto.BankToBookDifference);
        Assert.Equal(0, dto.ClientToBookDifference);
    }

    [Fact]
    public async Task ExportCustomerLedger_Csv_ReturnsFile()
    {
        using var ctx = CreateInMemoryContext(nameof(ExportCustomerLedger_Csv_ReturnsFile));
        var user = new User
        {
            Id = 103,
            Full_Name = "Client Three",
            User_Name = "client.three",
            Password = "x",
            Job = "Client",
            Date_Of_Birth = DateOnly.FromDateTime(DateTime.UtcNow),
            Phon_Number = 0,
            SSN = 3
        };
        var customer = new Customer { Id = 30, Users_Id = user.Id, Users = user };
        ctx.Users.Add(user);
        ctx.Customers.Add(customer);
        await ctx.SaveChangesAsync();

        var controller = new TrustAccountingController(ctx);
        await controller.CreateDeposit(new CreateTrustDepositDto
        {
            CustomerId = customer.Id,
            Amount = 250,
            OperationDate = DateOnly.FromDateTime(DateTime.UtcNow),
            Description = "Retainer deposit"
        });

        var exportResult = await controller.ExportCustomerLedger(customer.Id, "csv");
        var file = Assert.IsType<FileContentResult>(exportResult);

        Assert.Equal("text/csv", file.ContentType);
        Assert.Contains("trust-ledger", file.FileDownloadName, StringComparison.OrdinalIgnoreCase);
        Assert.NotEmpty(file.FileContents);
    }

    [Fact]
    public async Task ExportReconciliations_Pdf_ReturnsFile()
    {
        using var ctx = CreateInMemoryContext(nameof(ExportReconciliations_Pdf_ReturnsFile));
        var user = new User
        {
            Id = 104,
            Full_Name = "Client Four",
            User_Name = "client.four",
            Password = "x",
            Job = "Client",
            Date_Of_Birth = DateOnly.FromDateTime(DateTime.UtcNow),
            Phon_Number = 0,
            SSN = 4
        };
        var customer = new Customer { Id = 40, Users_Id = user.Id, Users = user };
        ctx.Users.Add(user);
        ctx.Customers.Add(customer);
        await ctx.SaveChangesAsync();

        var controller = new TrustAccountingController(ctx);
        await controller.CreateDeposit(new CreateTrustDepositDto
        {
            CustomerId = customer.Id,
            Amount = 300,
            OperationDate = DateOnly.FromDateTime(DateTime.UtcNow),
            Description = "Deposit for reconciliation"
        });

        await controller.CreateReconciliation(new CreateTrustReconciliationDto
        {
            ReconciliationDate = DateOnly.FromDateTime(DateTime.UtcNow),
            BankStatementBalance = 295,
            Notes = "Bank fee adjustment"
        });

        var exportResult = await controller.ExportReconciliations("pdf");
        var file = Assert.IsType<FileContentResult>(exportResult);

        Assert.Equal("application/pdf", file.ContentType);
        Assert.Contains("trust-reconciliations", file.FileDownloadName, StringComparison.OrdinalIgnoreCase);
        Assert.NotEmpty(file.FileContents);
    }

    [Fact]
    public async Task GetMonthlyTrends_ReturnsExpectedWindowAndTotals()
    {
        using var ctx = CreateInMemoryContext(nameof(GetMonthlyTrends_ReturnsExpectedWindowAndTotals));
        var user = new User
        {
            Id = 105,
            Full_Name = "Client Five",
            User_Name = "client.five",
            Password = "x",
            Job = "Client",
            Date_Of_Birth = DateOnly.FromDateTime(DateTime.UtcNow),
            Phon_Number = 0,
            SSN = 5
        };
        var customer = new Customer { Id = 50, Users_Id = user.Id, Users = user };
        ctx.Users.Add(user);
        ctx.Customers.Add(customer);
        await ctx.SaveChangesAsync();

        var controller = new TrustAccountingController(ctx);
        await controller.CreateDeposit(new CreateTrustDepositDto
        {
            CustomerId = customer.Id,
            Amount = 1000,
            OperationDate = new DateOnly(2026, 1, 5),
            Description = "Jan deposit"
        });

        await controller.CreateWithdrawal(new CreateTrustWithdrawalDto
        {
            CustomerId = customer.Id,
            Amount = 250,
            OperationDate = new DateOnly(2026, 2, 10),
            Description = "Feb withdrawal"
        });

        var result = await controller.GetMonthlyTrends(3, customer.Id, new DateOnly(2026, 3, 31));
        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var dto = Assert.IsType<TrustMonthlyTrendsReportDto>(ok.Value);

        Assert.Equal(3, dto.Months);
        Assert.Equal(1000, dto.TotalDeposits);
        Assert.Equal(250, dto.TotalWithdrawals);
        Assert.Equal(750, dto.EndingBalance);
        Assert.Equal(3, dto.MonthlyPoints.Count);
    }
}
