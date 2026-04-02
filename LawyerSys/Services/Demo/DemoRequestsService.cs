using LawyerSys.Data;
using LawyerSys.DTOs;
using LawyerSys.Resources;
using LawyerSys.Services.Email;
using LawyerSys.Services.Notifications;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Localization;

namespace LawyerSys.Services.Demo;

public sealed class DemoRequestsService : IDemoRequestsService
{
    private readonly ApplicationDbContext _applicationDbContext;
    private readonly IInAppNotificationService _inAppNotificationService;
    private readonly IEmailSender _emailSender;
    private readonly IStringLocalizer<SharedResource> _localizer;

    public DemoRequestsService(
        ApplicationDbContext applicationDbContext,
        IInAppNotificationService inAppNotificationService,
        IEmailSender emailSender,
        IStringLocalizer<SharedResource> localizer)
    {
        _applicationDbContext = applicationDbContext;
        _inAppNotificationService = inAppNotificationService;
        _emailSender = emailSender;
        _localizer = localizer;
    }

    public async Task<ServiceMessageResult> CreateDemoRequestAsync(CreateDemoRequestRequest request, CancellationToken cancellationToken = default)
    {
        var fullName = Normalize(request.FullName);
        var email = Normalize(request.Email);
        var phoneNumber = Normalize(request.PhoneNumber);
        var officeName = Normalize(request.OfficeName);
        var notes = Normalize(request.Notes);

        if (string.IsNullOrWhiteSpace(fullName))
        {
            return new ServiceMessageResult { Message = _localizer["DemoFullNameRequired"].Value };
        }

        if (string.IsNullOrWhiteSpace(email))
        {
            return new ServiceMessageResult { Message = _localizer["DemoEmailRequired"].Value };
        }

        if (string.IsNullOrWhiteSpace(officeName))
        {
            return new ServiceMessageResult { Message = _localizer["DemoOfficeNameRequired"].Value };
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
        await _applicationDbContext.SaveChangesAsync(cancellationToken);
        await _inAppNotificationService.NotifySuperAdminsOfDemoRequestAsync(item);

        return new ServiceMessageResult { Success = true, Message = _localizer["DemoRequestSubmitted"].Value };
    }

    public async Task<IReadOnlyList<DemoRequestDto>> GetDemoRequestsAsync(CancellationToken cancellationToken = default)
    {
        return await _applicationDbContext.DemoRequests
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
            .ToListAsync(cancellationToken);
    }

    public async Task<ServiceMessageResult> ReviewDemoRequestAsync(int id, ReviewDemoRequestRequest request, string? reviewedByUserId, CancellationToken cancellationToken = default)
    {
        if (!Enum.TryParse<DemoRequestStatus>(request.Status, true, out var status) ||
            (status != DemoRequestStatus.Approved && status != DemoRequestStatus.Rejected))
        {
            return new ServiceMessageResult { InvalidStatus = true, Message = _localizer["DemoInvalidReviewStatus"].Value };
        }

        var item = await _applicationDbContext.DemoRequests.SingleOrDefaultAsync(entry => entry.Id == id, cancellationToken);
        if (item == null)
        {
            return new ServiceMessageResult { NotFound = true, Message = _localizer["DemoRequestNotFound"].Value };
        }

        item.Status = status;
        item.ReviewedAtUtc = DateTime.UtcNow;
        item.UpdatedAtUtc = DateTime.UtcNow;
        item.ReviewedByUserId = reviewedByUserId;

        await _applicationDbContext.SaveChangesAsync(cancellationToken);
        await SendDecisionEmailAsync(item, status, Normalize(request.Message));

        return new ServiceMessageResult { Success = true, Message = _localizer["DemoRequestUpdated"].Value };
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
