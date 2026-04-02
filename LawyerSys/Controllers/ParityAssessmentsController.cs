using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using LawyerSys.Extensions.Authorization;
using LawyerSys.Services.Parity;

namespace LawyerSys.Controllers;

[Authorize(Policy = ParityPolicies.ParityWrite)]
[ApiController]
[Route("api/parity/capabilities/{capabilityId}/assessments")]
public class ParityAssessmentsController : ControllerBase
{
    [HttpPost]
    public IActionResult UpsertAssessment(string capabilityId)
    {
        return Ok(new { capabilityId, message = "Assessment captured" });
    }
}
