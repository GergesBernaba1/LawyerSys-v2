using System;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using LawyerSys.Controllers;
using LawyerSys.Data;
using LawyerSys.Data.ScaffoldedModels;
using LawyerSys.DTOs;
using LawyerSys.Tests.Infrastructure;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace LawyerSys.Tests;

public class CourtAutomationControllerTests
{
    private static LegacyDbContext CreateInMemoryContext(string dbName)
    {
        var options = new DbContextOptionsBuilder<LegacyDbContext>()
            .UseInMemoryDatabase(dbName)
            .Options;
        return new LegacyDbContext(options);
    }

    private static async Task SeedPackAsync(LegacyDbContext ctx)
    {
        var pack = new CourtAutomationPack
        {
            Id = 9101,
            Key = "sa-commercial-first-instance",
            NameEn = "Saudi Commercial Court - First Instance",
            NameAr = "المحكمة التجارية السعودية - الدرجة الأولى",
            DescriptionEn = "Commercial litigation filing pack.",
            DescriptionAr = "حزمة القضايا التجارية.",
            JurisdictionCode = "SA-COMMERCIAL",
            IsActive = true
        };

        ctx.CourtAutomationPacks.Add(pack);
        ctx.CourtAutomationFormTemplates.Add(new CourtAutomationFormTemplate
        {
            Id = 9201,
            Pack = pack,
            PackId = pack.Id,
            Key = "statement-of-claim",
            NameEn = "Statement Of Claim",
            NameAr = "صحيفة الدعوى",
            DescriptionEn = "Initial claim template",
            DescriptionAr = "نموذج صحيفة الدعوى",
            BodyEn = "STATEMENT OF CLAIM\n\nCourt: {{CourtName}}\nCase Code: {{CaseCode}}\nClient: {{CustomerName}}\nSubject: {{Subject}}\nFacts: {{Facts}}\nRequests: {{Requests}}",
            BodyAr = "صحيفة دعوى\n\nالمحكمة: {{CourtName}}\nرقم القضية: {{CaseCode}}\nالعميل: {{CustomerName}}\nالموضوع: {{Subject}}\nالوقائع: {{Facts}}\nالطلبات: {{Requests}}",
            IsActive = true
        });
        ctx.CourtAutomationDeadlineRules.Add(new CourtAutomationDeadlineRule
        {
            Id = 9301,
            Pack = pack,
            PackId = pack.Id,
            Key = "hearing-prep",
            NameEn = "Hearing Prep",
            NameAr = "تحضير الجلسة",
            DescriptionEn = "Prepare hearing documents.",
            DescriptionAr = "تجهيز مستندات الجلسة.",
            OffsetDays = -1,
            Anchor = "HearingDate",
            IsActive = true
        });
        ctx.CourtAutomationFilingChannels.Add(new CourtAutomationFilingChannel
        {
            Id = 9401,
            Pack = pack,
            PackId = pack.Id,
            ChannelCode = "Najez",
            DisplayNameEn = "Najez",
            DisplayNameAr = "ناجز",
            IsActive = true
        });

        await ctx.SaveChangesAsync();
    }

    [Fact]
    public async Task GetPacks_ReturnsConfiguredJurisdictionPacks()
    {
        using var ctx = CreateInMemoryContext(nameof(GetPacks_ReturnsConfiguredJurisdictionPacks));
        await SeedPackAsync(ctx);
        var controller = new CourtAutomationController(ctx, new TestStringLocalizer<LawyerSys.Resources.SharedResource>());

        var result = await controller.GetPacks("en");
        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var packs = Assert.IsAssignableFrom<System.Collections.Generic.IEnumerable<CourtJurisdictionPackDto>>(ok.Value);

        Assert.NotEmpty(packs);
        Assert.Contains(packs, p => p.Key == "sa-commercial-first-instance");
    }

    [Fact]
    public async Task CalculateDeadlines_UsesHearingAnchorRules()
    {
        using var ctx = CreateInMemoryContext(nameof(CalculateDeadlines_UsesHearingAnchorRules));
        await SeedPackAsync(ctx);
        var controller = new CourtAutomationController(ctx, new TestStringLocalizer<LawyerSys.Resources.SharedResource>());

        var action = await controller.CalculateDeadlines(new CalculateCourtDeadlinesRequestDto
        {
            PackKey = "sa-commercial-first-instance",
            TriggerDate = new DateOnly(2026, 3, 1),
            HearingDate = new DateOnly(2026, 3, 10),
            Language = "en"
        });

        var ok = Assert.IsType<OkObjectResult>(action.Result);
        var dto = Assert.IsType<CalculateCourtDeadlinesResponseDto>(ok.Value);
        var hearingPrep = dto.Deadlines.First(x => x.RuleKey == "hearing-prep");

        Assert.Equal(new DateOnly(2026, 3, 9), hearingPrep.DueDate);
    }

    [Fact]
    public async Task GenerateForm_ReturnsTxtFileWithCaseContext()
    {
        using var ctx = CreateInMemoryContext(nameof(GenerateForm_ReturnsTxtFileWithCaseContext));
        await SeedPackAsync(ctx);

        var user = new User
        {
            Id = 4001,
            Full_Name = "Client Form User",
            User_Name = "client.form",
            Password = "x",
            Job = "Client",
            Date_Of_Birth = DateOnly.FromDateTime(DateTime.UtcNow),
            Phon_Number = 0,
            SSN = 999
        };
        var customer = new Customer { Id = 5001, Users_Id = user.Id, Users = user };
        var court = new Court { Id = 6001, Name = "Riyadh Commercial Court", Address = "Riyadh", Telephone = "000", Notes = "", Gov_Id = 1 };
        var caseEntity = new Case
        {
            Id = 7001,
            Code = 7001,
            Invition_Type = "Commercial",
            Invitions_Statment = "Contract breach facts",
            Invition_Date = new DateOnly(2026, 1, 2),
            Total_Amount = 100000,
            Notes = "Claim full amount",
            Status = 1
        };

        ctx.Users.Add(user);
        ctx.Customers.Add(customer);
        ctx.Courts.Add(court);
        ctx.Cases.Add(caseEntity);
        ctx.Custmors_Cases.Add(new Custmors_Case { Id = 1, Case_Id = caseEntity.Code, Custmors_Id = customer.Id, Case = caseEntity, Custmors = customer });
        ctx.Cases_Courts.Add(new Cases_Court { Id = 1, Case_Code = caseEntity.Code, Court_Id = court.Id, Case_CodeNavigation = caseEntity, Court = court });
        await ctx.SaveChangesAsync();

        var controller = new CourtAutomationController(ctx, new TestStringLocalizer<LawyerSys.Resources.SharedResource>());
        var fileResult = await controller.GenerateForm(new GenerateCourtFormRequestDto
        {
            PackKey = "sa-commercial-first-instance",
            FormKey = "statement-of-claim",
            CaseCode = caseEntity.Code,
            Format = "txt",
            Language = "en"
        });

        var file = Assert.IsType<FileContentResult>(fileResult);
        var text = Encoding.UTF8.GetString(file.FileContents);

        Assert.Equal("text/plain", file.ContentType);
        Assert.Contains("statement-of-claim", file.FileDownloadName, StringComparison.OrdinalIgnoreCase);
        Assert.Contains("7001", text, StringComparison.Ordinal);
        Assert.Contains("Riyadh Commercial Court", text, StringComparison.Ordinal);
    }

    [Fact]
    public async Task SubmitFiling_ThenGetSubmission_ReturnsSameSubmission()
    {
        using var ctx = CreateInMemoryContext(nameof(SubmitFiling_ThenGetSubmission_ReturnsSameSubmission));
        await SeedPackAsync(ctx);
        var controller = new CourtAutomationController(ctx, new TestStringLocalizer<LawyerSys.Resources.SharedResource>());

        var submit = await controller.SubmitFiling(new SubmitCourtFilingRequestDto
        {
            PackKey = "sa-commercial-first-instance",
            FormKey = "statement-of-claim",
            FilingChannel = "Najez",
            Language = "en"
        });

        var created = Assert.IsType<CreatedAtActionResult>(submit.Result);
        var dto = Assert.IsType<CourtFilingSubmissionDto>(created.Value);

        var getResult = await controller.GetFilingSubmission(dto.SubmissionId);
        var ok = Assert.IsType<OkObjectResult>(getResult.Result);
        var fetched = Assert.IsType<CourtFilingSubmissionDto>(ok.Value);

        Assert.Equal(dto.SubmissionId, fetched.SubmissionId);
        Assert.Equal("sa-commercial-first-instance", fetched.PackKey);
    }
}
