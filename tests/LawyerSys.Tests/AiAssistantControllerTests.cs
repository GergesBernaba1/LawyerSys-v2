using System;
using System.Threading;
using System.Threading.Tasks;
using LawyerSys.Controllers;
using LawyerSys.Data;
using LawyerSys.Data.ScaffoldedModels;
using LawyerSys.DTOs;
using LawyerSys.Services.AIAssistant;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Moq;
using Xunit;

namespace LawyerSys.Tests;

public class AiAssistantControllerTests
{
    private static LegacyDbContext CreateInMemoryContext(string dbName)
    {
        var options = new DbContextOptionsBuilder<LegacyDbContext>()
            .UseInMemoryDatabase(dbName)
            .Options;
        return new LegacyDbContext(options);
    }

    [Fact]
    public async Task Summarize_WithoutAiProvider_ReturnsFallback()
    {
        using var ctx = CreateInMemoryContext(nameof(Summarize_WithoutAiProvider_ReturnsFallback));
        var ai = new Mock<IAiAssistantTextService>();
        ai.Setup(x => x.TryGenerateAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((string?)null);

        var controller = new AIAssistantController(ctx, ai.Object);
        var action = await controller.Summarize(new AiSummaryRequestDto
        {
            Language = "en",
            Text = "First legal point. Second legal point. Third legal point.",
            MaxKeyPoints = 4
        }, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(action.Result);
        var dto = Assert.IsType<AiSummaryResponseDto>(ok.Value);

        Assert.False(dto.UsedAiModel);
        Assert.False(string.IsNullOrWhiteSpace(dto.Summary));
        Assert.NotEmpty(dto.KeyPoints);
    }

    [Fact]
    public async Task Draft_WithAiProvider_ReturnsAiText()
    {
        using var ctx = CreateInMemoryContext(nameof(Draft_WithAiProvider_ReturnsAiText));
        var ai = new Mock<IAiAssistantTextService>();
        ai.Setup(x => x.TryGenerateAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync("Generated draft output");

        var controller = new AIAssistantController(ctx, ai.Object);
        var action = await controller.Draft(new AiDraftRequestDto
        {
            Language = "en",
            DraftType = "Memo",
            Instructions = "Draft a memo for settlement options.",
            Context = "Case value and liability risk details."
        }, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(action.Result);
        var dto = Assert.IsType<AiDraftResponseDto>(ok.Value);

        Assert.True(dto.UsedAiModel);
        Assert.Equal("Generated draft output", dto.DraftText);
    }

    [Fact]
    public async Task TaskDeadlineSuggestions_IncludesTaskAndHearingItems()
    {
        using var ctx = CreateInMemoryContext(nameof(TaskDeadlineSuggestions_IncludesTaskAndHearingItems));
        var ai = new Mock<IAiAssistantTextService>();
        ai.Setup(x => x.TryGenerateAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((string?)null);

        var today = DateOnly.FromDateTime(DateTime.UtcNow.Date);

        ctx.AdminstrativeTasks.Add(new AdminstrativeTask
        {
            Id = 901,
            Task_Name = "Collect evidence bundle",
            Type = "Preparation",
            Task_Date = today.AddDays(-1),
            Task_Reminder_Date = DateTime.UtcNow.AddDays(-2),
            Notes = "Overdue"
        });

        var hearing = new Siting
        {
            Id = 3001,
            Judge_Name = "Judge Smith",
            Notes = "Hearing notes",
            Siting_Date = today.AddDays(2),
            Siting_Time = DateTime.UtcNow.AddDays(2),
            Siting_Notification = DateTime.UtcNow.AddDays(1)
        };
        var caseEntity = new Case
        {
            Id = 7001,
            Code = 7001,
            Invition_Type = "Civil",
            Invitions_Statment = "Claim statement",
            Invition_Date = today.AddDays(-30),
            Total_Amount = 1000,
            Notes = "Case notes",
            Status = 1
        };

        ctx.Sitings.Add(hearing);
        ctx.Cases.Add(caseEntity);
        ctx.Cases_Sitings.Add(new Cases_Siting
        {
            Id = 5001,
            Case_Code = caseEntity.Code,
            Siting_Id = hearing.Id,
            Case_CodeNavigation = caseEntity,
            Siting = hearing
        });
        await ctx.SaveChangesAsync();

        var controller = new AIAssistantController(ctx, ai.Object);
        var action = await controller.GetTaskDeadlineSuggestions(new AiTaskSuggestionsQueryDto
        {
            Days = 14,
            MaxSuggestions = 12,
            Language = "en"
        }, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(action.Result);
        var dto = Assert.IsType<AiTaskSuggestionsResponseDto>(ok.Value);

        Assert.NotEmpty(dto.Suggestions);
        Assert.Contains(dto.Suggestions, x => x.SourceType == "Task");
        Assert.Contains(dto.Suggestions, x => x.SourceType == "Hearing");
    }
}
