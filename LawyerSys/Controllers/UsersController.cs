using LawyerSys.DTOs;
using LawyerSys.Extensions;
using LawyerSys.Resources;
using LawyerSys.Services.Users;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Localization;

namespace LawyerSys.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class UsersController : ControllerBase
{
    private readonly IUsersService _usersService;
    private readonly IStringLocalizer<SharedResource> _localizer;

    public UsersController(IUsersService usersService, IStringLocalizer<SharedResource> localizer)
    {
        _usersService = usersService;
        _localizer = localizer;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<UserDto>>> GetUsers([FromQuery] int? page = null, [FromQuery] int? pageSize = null, [FromQuery] string? search = null, CancellationToken cancellationToken = default)
    {
        var result = await _usersService.GetUsersAsync(page, pageSize, search, cancellationToken);

        if (result.Page.HasValue && result.PageSize.HasValue && result.TotalCount.HasValue)
        {
            return Ok(new PagedResult<UserDto>
            {
                Items = result.Items,
                TotalCount = result.TotalCount.Value,
                Page = result.Page.Value,
                PageSize = result.PageSize.Value
            });
        }

        return Ok(result.Items);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<UserDto>> GetUser(int id, CancellationToken cancellationToken)
    {
        var user = await _usersService.GetUserAsync(id, cancellationToken);
        if (user == null)
        {
            return this.EntityNotFound<UserDto>(_localizer, "User");
        }

        return Ok(user);
    }

    [HttpGet("byusername/{username}")]
    public async Task<ActionResult<UserDto>> GetUserByUsername(string username, CancellationToken cancellationToken)
    {
        var user = await _usersService.GetUserByUsernameAsync(username, cancellationToken);
        if (user == null)
        {
            return this.EntityNotFound<UserDto>(_localizer, "User");
        }

        return Ok(user);
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpPost]
    public async Task<ActionResult<UserDto>> CreateUser([FromBody] CreateUserDto dto, CancellationToken cancellationToken)
    {
        var result = await _usersService.CreateUserAsync(dto, cancellationToken);
        if (result.UserNameExists)
        {
            return BadRequest(new { message = _localizer["RegistrationFieldAlreadyUsedMessage", _localizer["RegistrationFieldUserName"].Value].Value });
        }

        var user = result.User!;
        return CreatedAtAction(nameof(GetUser), new { id = user.Id }, user);
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateUser(int id, [FromBody] UpdateUserDto dto, CancellationToken cancellationToken)
    {
        var user = await _usersService.UpdateUserAsync(id, dto, cancellationToken);
        if (user == null)
        {
            return this.EntityNotFound(_localizer, "User");
        }

        return Ok(user);
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteUser(int id, CancellationToken cancellationToken)
    {
        var result = await _usersService.DeleteUserAsync(id, cancellationToken);
        if (result.NotFound)
        {
            return this.EntityNotFound(_localizer, "User");
        }
        if (result.HasCustomers)
        {
            return BadRequest(new { message = _localizer["UserHasCustomers"].Value });
        }
        if (result.HasEmployees)
        {
            return BadRequest(new { message = _localizer["UserHasEmployees"].Value });
        }

        return Ok(new { message = _localizer["UserDeleted"].Value });
    }
}
