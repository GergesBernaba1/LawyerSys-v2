using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using LawyerSys.Data;
using LawyerSys.DTOs;
using LawyerSys.Data.ScaffoldedModels;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Identity;
using LawyerSys.Services.Email;
using Microsoft.Extensions.Localization;
using Microsoft.Extensions.Configuration;
using LawyerSys.Resources;
using Serilog;

namespace LawyerSys.Services
{
    public class CustomerService : ICustomerService
    {
        private readonly LegacyDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly RoleManager<IdentityRole> _roleManager;
        private readonly IEmailSender _emailSender;
        private readonly IStringLocalizer<SharedResource> _localizer;
        private readonly IConfiguration _configuration;
        private readonly ApplicationDbContext _applicationDbContext;
        private readonly IUserContext _userContext;

        public CustomerService(
            LegacyDbContext context,
            UserManager<ApplicationUser> userManager,
            RoleManager<IdentityRole> roleManager,
            IEmailSender emailSender,
            IStringLocalizer<SharedResource> localizer,
            IConfiguration configuration,
            ApplicationDbContext applicationDbContext,
            IUserContext userContext)
        {
            _context = context;
            _userManager = userManager;
            _roleManager = roleManager;
            _emailSender = emailSender;
            _localizer = localizer;
            _configuration = configuration;
            _applicationDbContext = applicationDbContext;
            _userContext = userContext;
        }

        public async Task<IEnumerable<CustomerDto>> GetCustomersAsync()
        {
            var customers = await _context.Customers
                .Include(c => c.Users)
                .ToListAsync();

            var dtos = customers.Select(MapToDto).ToList();

            foreach (var dto in dtos)
            {
                if (dto.User?.UserName != null)
                {
                    var appUser = await _userManager.FindByNameAsync(dto.User.UserName);
                    if (appUser != null)
                    {
                        dto.Identity = new IdentityUserInfoDto
                        {
                            Id = appUser.Id,
                            UserName = appUser.UserName ?? string.Empty,
                            Email = appUser.Email ?? string.Empty,
                            FullName = appUser.FullName ?? string.Empty,
                            EmailConfirmed = appUser.EmailConfirmed,
                            RequiresPasswordReset = appUser.RequiresPasswordReset
                        };
                    }
                }
            }

            return dtos;
        }

        public async Task<PagedResult<CustomerDto>> GetCustomersAsync(int page, int pageSize, string? search)
        {
            IQueryable<Customer> query = _context.Customers.Include(c => c.Users);

            if (!string.IsNullOrWhiteSpace(search))
            {
                var s = search.Trim();
                query = query.Where(c =>
                    c.Id.ToString().Contains(s) ||
                    c.Users_Id.ToString().Contains(s) ||
                    (c.Users != null && (
                        c.Users.Full_Name.Contains(s) ||
                        c.Users.User_Name.Contains(s) ||
                        c.Users.Job.Contains(s) ||
                        c.Users.Phon_Number.ToString().Contains(s) ||
                        c.Users.SSN.ToString().Contains(s))));
            }

            var p = Math.Max(1, page);
            var ps = Math.Clamp(pageSize, 1, 200);
            var total = await query.CountAsync();
            var items = await query.OrderBy(c => c.Id).Skip((p - 1) * ps).Take(ps).ToListAsync();

            var dtos = items.Select(MapToDto).ToList();
            foreach (var dto in dtos)
            {
                if (dto.User?.UserName != null)
                {
                    var appUser = await _userManager.FindByNameAsync(dto.User.UserName);
                    if (appUser != null)
                    {
                        dto.Identity = new IdentityUserInfoDto
                        {
                            Id = appUser.Id,
                            UserName = appUser.UserName ?? string.Empty,
                            Email = appUser.Email ?? string.Empty,
                            FullName = appUser.FullName ?? string.Empty,
                            EmailConfirmed = appUser.EmailConfirmed,
                            RequiresPasswordReset = appUser.RequiresPasswordReset
                        };
                    }
                }
            }

            return new PagedResult<CustomerDto>
            {
                Items = dtos,
                TotalCount = total,
                Page = p,
                PageSize = ps
            };
        }

        public async Task<CustomerDto?> GetCustomerAsync(int id)
        {
            var customer = await _context.Customers
                .Include(c => c.Users)
                .FirstOrDefaultAsync(c => c.Id == id);

            if (customer == null) return null;

            var dto = MapToDto(customer);
            if (dto.User?.UserName != null)
            {
                var appUser = await _userManager.FindByNameAsync(dto.User.UserName);
                if (appUser != null)
                {
                    dto.Identity = new IdentityUserInfoDto
                    {
                        Id = appUser.Id,
                        UserName = appUser.UserName ?? string.Empty,
                        Email = appUser.Email ?? string.Empty,
                        FullName = appUser.FullName ?? string.Empty,
                        EmailConfirmed = appUser.EmailConfirmed,
                        RequiresPasswordReset = appUser.RequiresPasswordReset
                    };
                }
            }

            return dto;
        }

        public async Task<CustomerProfileDto?> GetCustomerProfileAsync(int id)
        {
            var customer = await _context.Customers
                .Include(c => c.Users)
                .Include(c => c.Custmors_Cases)
                    .ThenInclude(cc => cc.Case)
                .FirstOrDefaultAsync(c => c.Id == id);

            if (customer == null) return null;

            var dto = new CustomerProfileDto
            {
                Id = customer.Id,
                User = customer.Users != null ? new UserDto
                {
                    Id = customer.Users.Id,
                    FullName = customer.Users.Full_Name,
                    Address = customer.Users.Address,
                    Job = customer.Users.Job,
                    PhoneNumber = customer.Users.Phon_Number.ToString(),
                    DateOfBirth = customer.Users.Date_Of_Birth,
                    SSN = customer.Users.SSN.ToString(),
                    UserName = customer.Users.User_Name,
                    ProfileImagePath = customer.Users.Profile_Image_Path
                } : null
            };

            foreach (var cc in customer.Custmors_Cases)
            {
                var c = cc.Case;

                // Cases_Employee is not exposed on Case entity; query cases_employees table for the assigned employee
                var assigned = await _context.Cases_Employees
                    .Include(ce => ce.Employee)
                        .ThenInclude(e => e.Users)
                    .FirstOrDefaultAsync(ce => ce.Case_Code == c.Code);

                dto.Cases.Add(new CaseWithEmployeeDto
                {
                    CaseId = c.Id,
                    CaseName = c.Invitions_Statment,
                    Code = c.Code,
                    AssignedEmployee = assigned != null && assigned.Employee?.Users != null ? new UserDto
                    {
                        Id = assigned.Employee.Users.Id,
                        FullName = assigned.Employee.Users.Full_Name,
                        Address = assigned.Employee.Users.Address,
                        Job = assigned.Employee.Users.Job,
                        PhoneNumber = assigned.Employee.Users.Phon_Number.ToString(),
                        DateOfBirth = assigned.Employee.Users.Date_Of_Birth,
                        SSN = assigned.Employee.Users.SSN.ToString(),
                        UserName = assigned.Employee.Users.User_Name,
                        ProfileImagePath = assigned.Employee.Users.Profile_Image_Path
                    } : null
                });
            }

            // Populate identity info if available
            if (dto.User?.UserName != null)
            {
                var appUser = await _userManager.FindByNameAsync(dto.User.UserName);
                if (appUser != null)
                {
                    dto.Identity = new IdentityUserInfoDto
                    {
                        Id = appUser.Id,
                        UserName = appUser.UserName ?? string.Empty,
                        Email = appUser.Email ?? string.Empty,
                        FullName = appUser.FullName ?? string.Empty,
                        EmailConfirmed = appUser.EmailConfirmed,
                        RequiresPasswordReset = appUser.RequiresPasswordReset
                    };
                }
            }

            return dto;
        }

        public async Task<CustomerDto> CreateCustomerAsync(CreateCustomerDto dto)
        {
            var user = await _context.Users.FindAsync(dto.UsersId);
            if (user == null) throw new ArgumentException("User not found");

            var customer = new Customer { Users_Id = dto.UsersId };
            _context.Customers.Add(customer);
            await _context.SaveChangesAsync();

            await _context.Entry(customer).Reference(c => c.Users).LoadAsync();

            var result = MapToDto(customer);
            if (result.User?.UserName != null)
            {
                var appUser = await _userManager.FindByNameAsync(result.User.UserName);
                if (appUser != null)
                {
                    result.Identity = new IdentityUserInfoDto
                    {
                        Id = appUser.Id,
                        UserName = appUser.UserName ?? string.Empty,
                        Email = appUser.Email ?? string.Empty,
                        FullName = appUser.FullName ?? string.Empty,
                        EmailConfirmed = appUser.EmailConfirmed,
                        RequiresPasswordReset = appUser.RequiresPasswordReset
                    };
                }
            }

            return result;
        }

        public async Task<(CustomerDto Customer, (string UserName, string Password) TempCredentials)> CreateCustomerWithUserAsync(CreateCustomerWithUserDto dto)
        {
            if (string.IsNullOrWhiteSpace(dto.Email))
                throw new ArgumentException("Email is required");
            if (string.IsNullOrWhiteSpace(dto.Password))
                throw new ArgumentException("Password is required");
            if (!string.Equals(dto.Password, dto.ConfirmPassword, StringComparison.Ordinal))
                throw new ArgumentException("Password and confirm password do not match");

            var normalizedEmail = dto.Email.Trim();
            var preferredUserName = string.IsNullOrWhiteSpace(dto.UserName)
                ? normalizedEmail
                : dto.UserName.Trim();
            string createdUserName = preferredUserName;

            if (await _context.Users.AnyAsync(u => u.User_Name == createdUserName) || (await _userManager.FindByNameAsync(createdUserName)) != null || (await _userManager.FindByEmailAsync(normalizedEmail)) != null)
                throw new ArgumentException("Username or email already exists");

            var parsedPhone = ConvertToLegacyInt(dto.PhoneNumber, "phoneNumber");
            var parsedSsn = ConvertToLegacyInt(dto.SSN, "SSN");

            var maxId = await _context.Users.MaxAsync(u => (int?)u.Id) ?? 0;

            var user = new User
            {
                Id = maxId + 1,
                Full_Name = dto.FullName,
                Address = dto.Address,
                Job = dto.Job,
                Phon_Number = parsedPhone,
                Date_Of_Birth = dto.DateOfBirth,
                SSN = parsedSsn,
                User_Name = createdUserName,
                Password = dto.Password
            };

            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            var customer = new Customer { Users_Id = user.Id };
            _context.Customers.Add(customer);
            await _context.SaveChangesAsync();
            customer.Users = user;

            string generatedPassword = dto.Password;
            var tenantInfo = await GetCurrentTenantInfoAsync();
            if (_userManager != null)
                {
                    if (string.IsNullOrWhiteSpace(generatedPassword))
                    {
                        generatedPassword = "Temp@" + Guid.NewGuid().ToString("N").Substring(0, 8);
                    }

                    var appUser = new ApplicationUser
                    {
                        UserName = createdUserName,
                        Email = normalizedEmail,
                        FullName = dto.FullName,
                        TenantId = tenantInfo.TenantId,
                        CountryId = tenantInfo.CountryId,
                        EmailConfirmed = true,
                        RequiresPasswordReset = true
                    };

                    var result = await _userManager.CreateAsync(appUser, generatedPassword);
                    if (result.Succeeded)
                    {
                        if (_roleManager != null && await _roleManager.RoleExistsAsync("Customer"))
                        {
                            await _userManager.AddToRoleAsync(appUser, "Customer");
                        }

                        if (_emailSender != null)
                        {
                            var subject = _localizer["AccountCreatedSubject"].Value;
                            var template = _localizer["AccountCreatedBody"].Value;
                            var body = template.Replace("{FullName}", dto.FullName)
                                               .Replace("{Email}", normalizedEmail)
                                               .Replace("{UserName}", appUser.UserName ?? string.Empty)
                                               .Replace("{Password}", generatedPassword)
                                               .Replace("{Phone}", dto.PhoneNumber ?? string.Empty)
                                               .Replace("{Job}", dto.Job ?? string.Empty)
                                               .Replace("{Address}", dto.Address ?? "N/A")
                                               .Replace("{DateOfBirth}", dto.DateOfBirth.ToString("yyyy-MM-dd"))
                                               .Replace("{SSN}", dto.SSN ?? string.Empty);

                            try
                            {
                                await _emailSender.SendEmailAsync(normalizedEmail, subject, body);
                            }
                            catch (Exception ex)
                            {
                                Log.Warning(ex, "Customer was created but sending account email failed for {Email}", normalizedEmail);
                            }
                        }
                        else
                        {
                            Log.Information("Account created for {UserName} but no email was provided to send credentials.", appUser.UserName);
                        }
                    }
                    else
                    {
                        Log.Error("Failed to create identity user: {Errors}", string.Join(", ", result.Errors.Select(e => e.Description)));
                    }
            }

            var responseDto = MapToDto(customer);
            var createdAppUser = await _userManager.FindByNameAsync(createdUserName);
            if (createdAppUser != null)
            {
                responseDto.Identity = new IdentityUserInfoDto
                {
                    Id = createdAppUser.Id,
                    UserName = createdAppUser.UserName ?? string.Empty,
                    Email = createdAppUser.Email ?? string.Empty,
                    FullName = createdAppUser.FullName ?? string.Empty,
                    EmailConfirmed = createdAppUser.EmailConfirmed,
                    RequiresPasswordReset = createdAppUser.RequiresPasswordReset
                };
            }

            return (responseDto, (createdUserName, generatedPassword));
        }

        private async Task<(int TenantId, int? CountryId)> GetCurrentTenantInfoAsync()
        {
            var tenantId = _userContext.GetTenantId();
            if (!tenantId.HasValue || tenantId.Value <= 0)
                throw new InvalidOperationException("Tenant context is required.");

            var tenant = await _applicationDbContext.Tenants
                .AsNoTracking()
                .SingleOrDefaultAsync(item => item.Id == tenantId.Value);
            if (tenant == null)
                throw new InvalidOperationException("Tenant not found.");

            return (tenant.Id, tenant.CountryId);
        }

        private static int ConvertToLegacyInt(string? value, string fieldName)
        {
            if (string.IsNullOrWhiteSpace(value))
                return 0;

            var digitsOnly = new string(value.Where(char.IsDigit).ToArray());
            if (string.IsNullOrWhiteSpace(digitsOnly))
                return 0;

            if (int.TryParse(digitsOnly, out var parsedInt))
                return parsedInt;

            var safeLength = Math.Min(9, digitsOnly.Length);
            var tailDigits = digitsOnly.Substring(digitsOnly.Length - safeLength, safeLength);
            if (int.TryParse(tailDigits, out parsedInt))
            {
                Log.Warning("{FieldName} value exceeded legacy int capacity. Using trailing digits for legacy storage.", fieldName);
                return parsedInt;
            }

            Log.Warning("{FieldName} value could not be converted for legacy storage. Using 0.", fieldName);
            return 0;
        }

        public async Task<CustomerDto> UpdateCustomerAsync(int id, UpdateCustomerDto dto)
        {
            var customer = await _context.Customers.Include(c => c.Users).FirstOrDefaultAsync(c => c.Id == id);
            if (customer == null) throw new ArgumentException("Customer not found");

            if (dto.UsersId.HasValue && dto.UsersId.Value != customer.Users_Id)
            {
                var user = await _context.Users.FindAsync(dto.UsersId.Value);
                if (user == null) throw new ArgumentException("User not found");
                customer.Users_Id = dto.UsersId.Value;
                customer.Users = user;
            }

            var targetUser = customer.Users ?? await _context.Users.FindAsync(customer.Users_Id);
            if (targetUser == null) throw new ArgumentException("User not found");

            var currentLegacyUserName = targetUser.User_Name;

            if (dto.FullName != null) targetUser.Full_Name = dto.FullName.Trim();
            if (dto.Address != null) targetUser.Address = string.IsNullOrWhiteSpace(dto.Address) ? null : dto.Address.Trim();
            if (dto.Job != null) targetUser.Job = dto.Job.Trim();
            if (dto.PhoneNumber != null) targetUser.Phon_Number = ConvertToLegacyInt(dto.PhoneNumber, "phoneNumber");
            if (dto.DateOfBirth.HasValue) targetUser.Date_Of_Birth = dto.DateOfBirth.Value;
            if (dto.SSN != null) targetUser.SSN = ConvertToLegacyInt(dto.SSN, "SSN");

            if (dto.UserName != null)
            {
                var requestedUserName = dto.UserName.Trim();
                if (string.IsNullOrWhiteSpace(requestedUserName))
                    throw new ArgumentException("Username is required");

                var legacyConflict = await _context.Users.AnyAsync(u => u.User_Name == requestedUserName && u.Id != targetUser.Id);
                if (legacyConflict)
                    throw new ArgumentException("Username is already in use");

                targetUser.User_Name = requestedUserName;
            }

            ApplicationUser? appUser = null;
            if (!string.IsNullOrWhiteSpace(currentLegacyUserName))
            {
                appUser = await _userManager.FindByNameAsync(currentLegacyUserName);
            }
            if (appUser == null && !string.IsNullOrWhiteSpace(targetUser.User_Name))
            {
                appUser = await _userManager.FindByNameAsync(targetUser.User_Name);
            }

            if (appUser != null)
            {
                if (dto.UserName != null)
                {
                    var requestedUserName = dto.UserName.Trim();
                    var existingIdentityUser = await _userManager.FindByNameAsync(requestedUserName);
                    if (existingIdentityUser != null && !string.Equals(existingIdentityUser.Id, appUser.Id, StringComparison.Ordinal))
                        throw new ArgumentException("Username is already in use");

                    appUser.UserName = requestedUserName;
                }

                if (dto.Email != null)
                {
                    var requestedEmail = dto.Email.Trim();
                    if (!string.IsNullOrWhiteSpace(requestedEmail))
                    {
                        var existingEmailUser = await _userManager.FindByEmailAsync(requestedEmail);
                        if (existingEmailUser != null && !string.Equals(existingEmailUser.Id, appUser.Id, StringComparison.Ordinal))
                            throw new ArgumentException("Email is already in use");
                    }
                    appUser.Email = string.IsNullOrWhiteSpace(requestedEmail) ? null : requestedEmail;
                }

                if (dto.FullName != null) appUser.FullName = dto.FullName.Trim();
                if (dto.PhoneNumber != null) appUser.PhoneNumber = string.IsNullOrWhiteSpace(dto.PhoneNumber) ? null : dto.PhoneNumber.Trim();

                var identityUpdate = await _userManager.UpdateAsync(appUser);
                if (!identityUpdate.Succeeded)
                    throw new InvalidOperationException(string.Join(", ", identityUpdate.Errors.Select(e => e.Description)));
            }

            await _context.SaveChangesAsync();
            await _context.Entry(customer).Reference(c => c.Users).LoadAsync();

            var updated = MapToDto(customer);
            if (updated.User?.UserName != null)
            {
                var refreshedIdentityUser = await _userManager.FindByNameAsync(updated.User.UserName);
                if (refreshedIdentityUser != null)
                {
                    updated.Identity = new IdentityUserInfoDto
                    {
                        Id = refreshedIdentityUser.Id,
                        UserName = refreshedIdentityUser.UserName ?? string.Empty,
                        Email = refreshedIdentityUser.Email ?? string.Empty,
                        FullName = refreshedIdentityUser.FullName ?? string.Empty,
                        EmailConfirmed = refreshedIdentityUser.EmailConfirmed,
                        RequiresPasswordReset = refreshedIdentityUser.RequiresPasswordReset
                    };
                }
            }

            return updated;
        }

        public async Task SendPasswordResetEmailAsync(int id)
        {
            var customer = await _context.Customers
                .Include(c => c.Users)
                .FirstOrDefaultAsync(c => c.Id == id);
            if (customer == null) throw new ArgumentException("Customer not found");
            if (customer.Users == null) throw new InvalidOperationException("Customer does not have a linked user");
            if (string.IsNullOrWhiteSpace(customer.Users.User_Name)) throw new InvalidOperationException("Customer username is missing");

            var appUser = await _userManager.FindByNameAsync(customer.Users.User_Name);
            if (appUser == null) throw new InvalidOperationException("Identity account not found for this customer");
            if (string.IsNullOrWhiteSpace(appUser.Email)) throw new InvalidOperationException("Customer account does not have an email address");

            var token = await _userManager.GeneratePasswordResetTokenAsync(appUser);
            appUser.RequiresPasswordReset = true;
            var flagUpdate = await _userManager.UpdateAsync(appUser);
            if (!flagUpdate.Succeeded)
                throw new InvalidOperationException(string.Join(", ", flagUpdate.Errors.Select(e => e.Description)));

            var clientBaseUrl = _configuration["ClientApp:BaseUrl"]?.TrimEnd('/')
                ?? _configuration["ClientBaseUrl"]?.TrimEnd('/')
                ?? "http://localhost:3002";

            var resetLink = $"{clientBaseUrl}/reset-password?userName={Uri.EscapeDataString(appUser.UserName ?? string.Empty)}&token={Uri.EscapeDataString(token)}";
            var fullName = string.IsNullOrWhiteSpace(appUser.FullName) ? customer.Users.Full_Name : appUser.FullName;

            var localizedSubject = _localizer["PasswordResetSubject"];
            var localizedBody = _localizer["PasswordResetBody"];
            var subject = localizedSubject.ResourceNotFound ? "Password reset request" : localizedSubject.Value;
            var bodyTemplate = localizedBody.ResourceNotFound
                ? "<h3>Password reset request</h3><p>Hello {FullName},</p><p>Use this link to reset your password:</p><p><a href=\"{ResetLink}\">{ResetLink}</a></p><p>If the link does not open, use this token:</p><p><strong>User:</strong> {UserName}</p><p><strong>Token:</strong> {Token}</p>"
                : localizedBody.Value;

            var body = bodyTemplate
                .Replace("{FullName}", fullName ?? string.Empty)
                .Replace("{ResetLink}", resetLink)
                .Replace("{UserName}", appUser.UserName ?? string.Empty)
                .Replace("{Token}", token);

            await _emailSender.SendEmailAsync(appUser.Email, subject, body);
        }

        public async Task<bool> DeleteCustomerAsync(int id)
        {
            var customer = await _context.Customers.FindAsync(id);
            if (customer == null) return false;
            _context.Customers.Remove(customer);
            await _context.SaveChangesAsync();
            return true;
        }

        private static CustomerDto MapToDto(Customer c) => new()
        {
            Id = c.Id,
            UsersId = c.Users_Id,
            User = c.Users != null ? new UserDto
            {
                Id = c.Users.Id,
                FullName = c.Users.Full_Name,
                Address = c.Users.Address,
                Job = c.Users.Job,
                PhoneNumber = c.Users.Phon_Number.ToString(),
                DateOfBirth = c.Users.Date_Of_Birth,
                SSN = c.Users.SSN.ToString(),
                UserName = c.Users.User_Name,
                ProfileImagePath = c.Users.Profile_Image_Path
            } : null
        };
    }
}

