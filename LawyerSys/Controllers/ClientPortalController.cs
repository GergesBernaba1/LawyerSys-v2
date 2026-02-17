using LawyerSys.Data;
using LawyerSys.DTOs;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LawyerSys.Controllers;

[Authorize(Roles = "Customer")]
[ApiController]
[Route("api/[controller]")]
public class ClientPortalController : ControllerBase
{
    private readonly LegacyDbContext _context;

    public ClientPortalController(LegacyDbContext context)
    {
        _context = context;
    }

    [HttpGet("overview")]
    public async Task<ActionResult<ClientPortalResponseDto>> GetOverview()
    {
        var userName = User.Identity?.Name;
        if (string.IsNullOrWhiteSpace(userName))
        {
            return Unauthorized(new { message = "User identity not found" });
        }

        var customer = await _context.Customers
            .Include(c => c.Users)
            .FirstOrDefaultAsync(c => c.Users.User_Name == userName);

        if (customer is null)
        {
            return NotFound(new { message = "Customer profile not found" });
        }

        var caseCodes = await _context.Custmors_Cases
            .Where(cc => cc.Custmors_Id == customer.Id)
            .Select(cc => cc.Case_Id)
            .Distinct()
            .ToListAsync();

        var cases = await _context.Cases
            .Where(c => caseCodes.Contains(c.Code))
            .OrderByDescending(c => c.Invition_Date)
            .Select(c => new ClientPortalCaseDto
            {
                Code = c.Code,
                Type = c.Invition_Type,
                Date = c.Invition_Date,
                TotalAmount = c.Total_Amount,
                Status = c.Status
            })
            .ToListAsync();

        var hearings = await _context.Cases_Sitings
            .Where(cs => caseCodes.Contains(cs.Case_Code))
            .OrderBy(cs => cs.Siting.Siting_Date)
            .Select(cs => new ClientPortalHearingDto
            {
                CaseCode = cs.Case_Code,
                Date = cs.Siting.Siting_Date,
                Time = cs.Siting.Siting_Time,
                JudgeName = cs.Siting.Judge_Name
            })
            .ToListAsync();

        var documents = await _context.Judicial_Documents
            .Where(d => d.Customers_Id == customer.Id)
            .OrderByDescending(d => d.Id)
            .Select(d => new ClientPortalDocumentDto
            {
                Id = d.Id,
                Type = d.Doc_Type,
                Number = d.Doc_Num,
                Details = d.Doc_Details
            })
            .ToListAsync();

        var totalPayments = await _context.Billing_Pays
            .Where(p => p.Custmor_Id == customer.Id)
            .SumAsync(p => p.Amount);

        var totalCaseAmount = cases.Sum(c => (double)c.TotalAmount);

        return Ok(new ClientPortalResponseDto
        {
            CustomerName = customer.Users?.Full_Name ?? customer.Users?.User_Name ?? $"Customer #{customer.Id}",
            Cases = cases,
            Hearings = hearings,
            Documents = documents,
            Billing = new ClientPortalBillingDto
            {
                TotalPayments = totalPayments,
                CasesTotalAmount = totalCaseAmount,
                OutstandingBalance = totalCaseAmount - totalPayments
            }
        });
    }
}
