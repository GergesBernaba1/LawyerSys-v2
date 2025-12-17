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
    public class EmployeeService : IEmployeeService
    {
        private readonly LegacyDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly RoleManager<IdentityRole> _roleManager;
        private readonly IEmailSender _emailSender;
        private readonly IStringLocalizer<SharedResource> _localizer;

        public EmployeeService(LegacyDbContext context, UserManager<ApplicationUser> userManager, RoleManager<IdentityRole> roleManager, IEmailSender emailSender, IStringLocalizer<SharedResource> localizer)
        {
            _context = context;
            _userManager = userManager;
            _roleManager = roleManager;
            _emailSender = emailSender;
            _localizer = localizer;
        }

        public async Task<IEnumerable<EmployeeDto>> GetEmployeesAsync()
        {
            var employees = await _context.Employees
                .Include(e => e.Users)
                .ToListAsync();

            var dtos = employees.Select(MapToDto).ToList();

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

        public async Task<EmployeeDto?> GetEmployeeAsync(int id)
        {
            var employee = await _context.Employees
                .Include(e => e.Users)
                .FirstOrDefaultAsync(e => e.id == id);

            if (employee == null) return null;

            var dto = MapToDto(employee);
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

        public async Task<EmployeeDto> CreateEmployeeAsync(CreateEmployeeDto dto)
        {
            var user = await _context.Users.FindAsync(dto.UsersId);
            if (user == null) throw new ArgumentException("User not found");

            var employee = new Employee { Salary = dto.Salary, Users_Id = dto.UsersId };
            _context.Employees.Add(employee);
            await _context.SaveChangesAsync();

            await _context.Entry(employee).Reference(e => e.Users).LoadAsync();

            var result = MapToDto(employee);
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

        public async Task<(EmployeeDto Employee, (string UserName, string Password) TempCredentials)> CreateEmployeeWithUserAsync(CreateEmployeeWithUserDto dto)
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

            var employee = new Employee { Salary = dto.Salary, Users_Id = legacyUser.Id };
            _context.Employees.Add(employee);
            await _context.SaveChangesAsync();
            employee.Users = legacyUser;

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
                    if (_roleManager != null && await _roleManager.RoleExistsAsync("Employee"))
                    {
                        await _userManager.AddToRoleAsync(appUser, "Employee");
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

            var responseDto = MapToDto(employee);
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

        public async Task<EmployeeDto> UpdateEmployeeAsync(int id, UpdateEmployeeDto dto)
        {
            var employee = await _context.Employees.Include(e => e.Users).FirstOrDefaultAsync(e => e.id == id);
            if (employee == null) throw new ArgumentException("Employee not found");

            if (dto.Salary.HasValue) employee.Salary = dto.Salary.Value;

            await _context.SaveChangesAsync();
            return MapToDto(employee);
        }

        public async Task<bool> DeleteEmployeeAsync(int id)
        {
            var employee = await _context.Employees.FindAsync(id);
            if (employee == null) return false;
            _context.Employees.Remove(employee);
            await _context.SaveChangesAsync();
            return true;
        }

        private static EmployeeDto MapToDto(Employee e) => new()
        {
            Id = e.id,
            Salary = e.Salary,
            UsersId = e.Users_Id,
            User = e.Users != null ? new LegacyUserDto
            {
                Id = e.Users.Id,
                FullName = e.Users.Full_Name,
                Address = e.Users.Address,
                Job = e.Users.Job,
                PhoneNumber = e.Users.Phon_Number.ToString(),
                DateOfBirth = e.Users.Date_Of_Birth,
                SSN = e.Users.SSN.ToString(),
                UserName = e.Users.User_Name
            } : null
        };
    }
}
