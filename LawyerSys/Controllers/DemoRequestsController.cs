using LawyerSys.Resources;
using LawyerSys.Services.Email;
using LawyerSys.Services.Notifications;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Localization;

namespace LawyerSys.Controllers;

[ApiController]
[Route("api/[controller]")]
public class DemoRequestsController : ControllerBase
{
    private readonly ApplicationDbContext _applicationDbContext;
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly IInAppNotificationService _inAppNotificationService;
    private readonly IEmailSender _emailSender;
    private readonly IStringLocalizer<SharedResource> _localizer;

    public DemoRequestsController(
        ApplicationDbContext applicationDbContext,
        UserManager<ApplicationUser> userManager,
        IInAppNotificationService inAppNotificationService,
        IEmailSender emailSender,
        IStringLocalizer<SharedResource> localizer)
    {
        _applicationDbContext = applicationDbContext;
        _userManager = userManager;
        _inAppNotificationService = inAppNotificationService;
        _emailSender = emailSender;
        _localizer = localizer;
    }

    [AllowAnonymous]
    [HttpPost]
    public async Task<IActionResult> CreateDemoRequest([FromBody] CreateDemoRequestRequest request)
    {
        var fullName = Normalize(request.FullName);
        var email = Normalize(request.Email);
        var phoneNumber = Normalize(request.PhoneNumber);
        var officeName = Normalize(request.OfficeName);
        var notes = Normalize(request.Notes);

        if (string.IsNullOrWhiteSpace(fullName))
        {
            return BadRequest(new { message = _localizer["DemoFullNameRequired"].Value });
        }

        if (string.IsNullOrWhiteSpace(email))
        {
            return BadRequest(new { message = _localizer["DemoEmailRequired"].Value });
        }

        if (string.IsNullOrWhiteSpace(officeName))
        {
            return BadRequest(new { message = _localizer["DemoOfficeNameRequired"].Value });
        }

        var item = new DemoRequest
        {
            FullName = fullName,
            Email = email,
            PhoneNumber = phoneNumber,
            OfficeName = officeName,
            Notes = notes,
            Status = DemoRequestStatus.Pending,
            CreatedAtUtc = DateTime.UtcNow,
            UpdatedAtUtc = DateTime.UtcNow,
        };

        _applicationDbContext.DemoRequests.Add(item);
        await _applicationDbContext.SaveChangesAsync();
        await _inAppNotificationService.NotifySuperAdminsOfDemoRequestAsync(item);

        return Ok(new { message = _localizer["DemoRequestSubmitted"].Value });
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpGet]
    public async Task<IActionResult> GetDemoRequests()
    {
        if (!User.IsInRole("SuperAdmin"))
        {
            return Forbid();
        }

        var items = await _applicationDbContext.DemoRequests
            .AsNoTracking()
            .Include(item => item.ReviewedByUser)
            .OrderBy(item => item.Status)
            .ThenByDescending(item => item.CreatedAtUtc)
            .Select(item => new DemoRequestDto
            {
                Id = item.Id,
                FullName = item.FullName,
                Email = item.Email,
                PhoneNumber = item.PhoneNumber,
                OfficeName = item.OfficeName,
                Notes = item.Notes,
                Status = item.Status.ToString(),
                CreatedAtUtc = item.CreatedAtUtc,
                ReviewedAtUtc = item.ReviewedAtUtc,
                ReviewedByName = item.ReviewedByUser != null
                    ? (!string.IsNullOrWhiteSpace(item.ReviewedByUser.FullName)
                        ? item.ReviewedByUser.FullName
                        : item.ReviewedByUser.UserName ?? string.Empty)
                    : string.Empty,
            })
            .ToListAsync();

        return Ok(items);
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpPut("{id:int}/review")]
    public async Task<IActionResult> ReviewDemoRequest(int id, [FromBody] ReviewDemoRequestRequest request)
    {
        if (!User.IsInRole("SuperAdmin"))
        {
            return Forbid();
        }

        if (!Enum.TryParse<DemoRequestStatus>(request.Status, true, out var status) ||
            (status != DemoRequestStatus.Approved && status != DemoRequestStatus.Rejected))
        {
            return BadRequest(new { message = _localizer["DemoInvalidReviewStatus"].Value });
        }

        var item = await _applicationDbContext.DemoRequests.SingleOrDefaultAsync(entry => entry.Id == id);
        if (item == null)
        {
            return NotFound(new { message = _localizer["DemoRequestNotFound"].Value });
        }

        item.Status = status;
        item.ReviewedAtUtc = DateTime.UtcNow;
        item.UpdatedAtUtc = DateTime.UtcNow;
        item.ReviewedByUserId = _userManager.GetUserId(User);

        await _applicationDbContext.SaveChangesAsync();
        await SendDecisionEmailAsync(item, status, Normalize(request.Message));

        return Ok(new { message = _localizer["DemoRequestUpdated"].Value });
    }

    private async Task SendDecisionEmailAsync(DemoRequest request, DemoRequestStatus status, string reviewerMessage)
    {
        if (string.IsNullOrWhiteSpace(request.Email))
        {
            return;
        }

        var subject = status == DemoRequestStatus.Approved
            ? "Your demo request has been approved"
            : "Your demo request has been reviewed";
        var body = status == DemoRequestStatus.Approved
            ? $@"
<p>Hello {System.Net.WebUtility.HtmlEncode(request.FullName)},</p>
<p>Your demo request for <strong>{System.Net.WebUtility.HtmlEncode(request.OfficeName)}</strong> has been approved.</p>
<p>Our team can now coordinate the demo with you.</p>
{BuildMessageBlock(reviewerMessage)}
<p>Regards,<br/>Qadaya team</p>"
            : $@"
<p>Hello {System.Net.WebUtility.HtmlEncode(request.FullName)},</p>
<p>Your demo request for <strong>{System.Net.WebUtility.HtmlEncode(request.OfficeName)}</strong> has been reviewed.</p>
{BuildMessageBlock(reviewerMessage)}
<p>Regards,<br/>Qadaya team</p>";

        await _emailSender.SendEmailAsync(request.Email, subject, body);
    }

    private static string BuildMessageBlock(string reviewerMessage)
    {
        return string.IsNullOrWhiteSpace(reviewerMessage)
            ? string.Empty
            : $"<p>Message from the team: {System.Net.WebUtility.HtmlEncode(reviewerMessage)}</p>";
    }

    private static string Normalize(string? value) => (value ?? string.Empty).Trim();
}

public class CreateDemoRequestRequest
{
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string OfficeName { get; set; } = string.Empty;
    public string Notes { get; set; } = string.Empty;
}

public class ReviewDemoRequestRequest
{
    public string Status { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
}

public class DemoRequestDto
{
    public int Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string OfficeName { get; set; } = string.Empty;
    public string Notes { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAtUtc { get; set; }
    public DateTime? ReviewedAtUtc { get; set; }
    public string ReviewedByName { get; set; } = string.Empty;
}
