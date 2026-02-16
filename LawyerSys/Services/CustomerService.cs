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
using LawyerSys.Resources;

namespace LawyerSys.Services
{
    public class CustomerService : ICustomerService
    {
        private readonly LegacyDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly RoleManager<IdentityRole> _roleManager;
        private readonly IEmailSender _emailSender;
        private readonly IStringLocalizer<SharedResource> _localizer;

        public CustomerService(LegacyDbContext context, UserManager<ApplicationUser> userManager, RoleManager<IdentityRole> roleManager, IEmailSender emailSender, IStringLocalizer<SharedResource> localizer)
        {
            _context = context;
            _userManager = userManager;
            _roleManager = roleManager;
            _emailSender = emailSender;
            _localizer = localizer;
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
                User = customer.Users != null ? new LegacyUserDto
                {
                    Id = customer.Users.Id,
                    FullName = customer.Users.Full_Name,
                    Address = customer.Users.Address,
                    Job = customer.Users.Job,
                    PhoneNumber = customer.Users.Phon_Number.ToString(),
                    DateOfBirth = customer.Users.Date_Of_Birth,
                    SSN = customer.Users.SSN.ToString(),
                    UserName = customer.Users.User_Name
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
                    AssignedEmployee = assigned != null && assigned.Employee?.Users != null ? new LegacyUserDto
                    {
                        Id = assigned.Employee.Users.Id,
                        FullName = assigned.Employee.Users.Full_Name,
                        Address = assigned.Employee.Users.Address,
                        Job = assigned.Employee.Users.Job,
                        PhoneNumber = assigned.Employee.Users.Phon_Number.ToString(),
                        DateOfBirth = assigned.Employee.Users.Date_Of_Birth,
                        SSN = assigned.Employee.Users.SSN.ToString(),
                        UserName = assigned.Employee.Users.User_Name
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
            string createdUserName = dto.Email ?? dto.UserName ?? dto.FullName.Replace(" ", "_").ToLowerInvariant();

            if (await _context.Users.AnyAsync(u => u.User_Name == createdUserName) || (await _userManager.FindByNameAsync(createdUserName)) != null || (!string.IsNullOrWhiteSpace(dto.Email) && (await _userManager.FindByEmailAsync(dto.Email)) != null))
                throw new ArgumentException("Username or email already exists");

            var maxId = await _context.Users.MaxAsync(u => (int?)u.Id) ?? 0;

            var legacyUser = new User
            {
                Id = maxId + 1,
                Full_Name = dto.FullName,
                Address = dto.Address,
                Job = dto.Job,
                Phon_Number = int.TryParse(dto.PhoneNumber, out var phone) ? phone : 0,
                Date_Of_Birth = dto.DateOfBirth,
                SSN = int.TryParse(dto.SSN, out var ssn) ? ssn : 0,
                User_Name = createdUserName,
                Password = dto.Password
            };

            _context.Users.Add(legacyUser);
            await _context.SaveChangesAsync();

            var customer = new Customer { Users_Id = legacyUser.Id };
            _context.Customers.Add(customer);
            await _context.SaveChangesAsync();
            customer.Users = legacyUser;

            string generatedPassword = dto.Password;
if (_userManager != null)
                {
                    if (string.IsNullOrWhiteSpace(generatedPassword))
                    {
                        generatedPassword = "Temp@" + Guid.NewGuid().ToString("N").Substring(0, 8);
                    }

                    var appUser = new ApplicationUser
                    {
                        UserName = createdUserName,
                        Email = dto.Email ?? string.Empty,
                        FullName = dto.FullName,
                        EmailConfirmed = !string.IsNullOrWhiteSpace(dto.Email),
                        RequiresPasswordReset = true
                    };

                    var result = await _userManager.CreateAsync(appUser, generatedPassword);
                    if (result.Succeeded)
                    {
                        if (_roleManager != null && await _roleManager.RoleExistsAsync("Customer"))
                        {
                            await _userManager.AddToRoleAsync(appUser, "Customer");
                        }

                        if (_emailSender != null && !string.IsNullOrWhiteSpace(dto.Email))
                        {
                            var subject = _localizer["AccountCreatedSubject"].Value;
                            var template = _localizer["AccountCreatedBody"].Value;
                            var body = template.Replace("{FullName}", dto.FullName)
                                               .Replace("{Email}", dto.Email ?? string.Empty)
                                               .Replace("{UserName}", appUser.UserName ?? string.Empty)
                                               .Replace("{Password}", generatedPassword)
                                               .Replace("{Phone}", dto.PhoneNumber ?? string.Empty)
                                               .Replace("{Job}", dto.Job ?? string.Empty)
                                               .Replace("{Address}", dto.Address ?? "N/A")
                                               .Replace("{DateOfBirth}", dto.DateOfBirth.ToString("yyyy-MM-dd"))
                                               .Replace("{SSN}", dto.SSN ?? string.Empty);

                            await _emailSender.SendEmailAsync(dto.Email ?? string.Empty, subject, body);
                        }
                        else
                        {
                            Console.WriteLine($"Account created for {appUser.UserName} but no email was provided to send credentials.");
                        }
                    }
                    else
                    {
                        Console.WriteLine("Failed to create identity user: " + string.Join(", ", result.Errors.Select(e => e.Description)));
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

        public async Task<CustomerDto> UpdateCustomerAsync(int id, UpdateCustomerDto dto)
        {
            var customer = await _context.Customers.Include(c => c.Users).FirstOrDefaultAsync(c => c.Id == id);
            if (customer == null) throw new ArgumentException("Customer not found");

            if (dto.UsersId.HasValue)
            {
                var user = await _context.Users.FindAsync(dto.UsersId.Value);
                if (user == null) throw new ArgumentException("User not found");
                customer.Users_Id = dto.UsersId.Value;
            }

            await _context.SaveChangesAsync();
            return MapToDto(customer);
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
            User = c.Users != null ? new LegacyUserDto
            {
                Id = c.Users.Id,
                FullName = c.Users.Full_Name,
                Address = c.Users.Address,
                Job = c.Users.Job,
                PhoneNumber = c.Users.Phon_Number.ToString(),
                DateOfBirth = c.Users.Date_Of_Birth,
                SSN = c.Users.SSN.ToString(),
                UserName = c.Users.User_Name
            } : null
        };
    }
}
