using LawyerSys.Data;
using LawyerSys.Services.Auditing;
using LawyerSys.Services.MultiTenancy;
using LawyerSys.Services.Notifications;
using LawyerSys.Services.Reminders;
using LawyerSys.Services.TrustAccounting;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Localization;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Serilog;
using System.Globalization;
using System.Text;
using System.Threading.RateLimiting;

var builder = WebApplication.CreateBuilder(args);

builder.Host.UseSerilog((context, services, configuration) => configuration
    .ReadFrom.Configuration(context.Configuration)
    .ReadFrom.Services(services)
    .Enrich.FromLogContext()
    .WriteTo.Console()
    .WriteTo.File("Logs/lawyersys-.log", rollingInterval: RollingInterval.Day));

builder.Services.AddControllers();
builder.Services.AddHttpContextAccessor();
builder.Services.AddLocalization(options => options.ResourcesPath = "Resources");
builder.Services.Configure<RequestLocalizationOptions>(options =>
{
    var supportedCultures = new[] { new CultureInfo("en-US"), new CultureInfo("ar-SA") };
    options.DefaultRequestCulture = new RequestCulture("en-US");
    options.SupportedCultures = supportedCultures;
    options.SupportedUICultures = supportedCultures;
    options.RequestCultureProviders = new IRequestCultureProvider[]
    {
        new QueryStringRequestCultureProvider(),
        new CookieRequestCultureProvider(),
        new AcceptLanguageHeaderRequestCultureProvider()
    };
});
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(httpContext =>
        RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown",
            factory: _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 120,
                Window = TimeSpan.FromMinutes(1),
                QueueProcessingOrder = QueueProcessingOrder.OldestFirst,
                QueueLimit = 0
            }));
});

builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "LawyerSys API",
        Version = "v1",
        Description = "Lawyer Management System API - Manage cases, customers, employees, files, and more.",
        Contact = new OpenApiContact
        {
            Name = "LawyerSys Support",
            Email = "support@lawyersys.com"
        }
    });

    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "JWT Authorization header using the Bearer scheme. Enter 'Bearer' [space] and then your token.",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });

    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

var conn = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? "Host=localhost;Port=5432;Database=Lawer;Username=postgres;Password=postgres";
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseNpgsql(conn, b => b.MigrationsAssembly("LawyerSys.Infrastructure")));
builder.Services.AddDbContext<LegacyDbContext>(options =>
    options.UseNpgsql(conn, b => b.MigrationsAssembly("LawyerSys.Infrastructure")));

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowReactClient", policy =>
    {
        policy.WithOrigins("http://localhost:3000", "http://localhost:3001", "http://localhost:3002", "http://localhost:5173", "https://localhost:5173")
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials();
    });
});

builder.Services.Configure<LawyerSys.Services.Email.EmailSettings>(builder.Configuration.GetSection("Email"));
var emailPassword = builder.Configuration.GetValue<string>("Email:Password");
if (string.IsNullOrWhiteSpace(emailPassword) || emailPassword.StartsWith("<", StringComparison.Ordinal))
{
    var msg = "Email:Password is not configured. Set Email:Password in user-secrets or environment variable.";
    if (!builder.Environment.IsDevelopment()) throw new InvalidOperationException(msg);
    Log.Warning("{Message}", msg);
}

builder.Services.AddScoped<LawyerSys.Services.Email.IEmailSender, LawyerSys.Services.Email.SmtpEmailSender>();
builder.Services.Configure<NotificationChannelsOptions>(builder.Configuration.GetSection("Notifications"));
builder.Services.AddHttpClient();
builder.Services.AddSingleton<IExternalMessageSender, TwilioExternalMessageSender>();
builder.Services.AddSingleton<ReminderDispatchStore>();
builder.Services.Configure<HearingReminderOptions>(builder.Configuration.GetSection("Reminders:Hearing"));
builder.Services.AddHostedService<HearingReminderBackgroundService>();
builder.Services.Configure<TaskReminderOptions>(builder.Configuration.GetSection("Reminders:Task"));
builder.Services.AddHostedService<TaskReminderBackgroundService>();

builder.Services.AddScoped<LawyerSys.Services.IUserContext, LawyerSys.Services.UserContext>();
builder.Services.AddScoped<LawyerSys.Services.ICustomerService, LawyerSys.Services.CustomerService>();
builder.Services.AddScoped<LawyerSys.Services.IEmployeeService, LawyerSys.Services.EmployeeService>();
builder.Services.AddScoped<LawyerSys.Services.IAccountService, LawyerSys.Services.AccountService>();

builder.Services.AddIdentity<ApplicationUser, IdentityRole>(options =>
{
    options.Password.RequireDigit = true;
    options.Password.RequireLowercase = true;
    options.Password.RequireUppercase = true;
    options.Password.RequireNonAlphanumeric = true;
    options.Password.RequiredLength = 8;
    options.Lockout.DefaultLockoutTimeSpan = TimeSpan.FromMinutes(15);
    options.Lockout.MaxFailedAccessAttempts = 5;
    options.User.RequireUniqueEmail = true;
})
    .AddEntityFrameworkStores<ApplicationDbContext>()
    .AddDefaultTokenProviders();

var jwtSection = builder.Configuration.GetSection("Jwt");
var configuredSecret = jwtSection.GetValue<string>("Key");
string secret;
if (string.IsNullOrWhiteSpace(configuredSecret))
{
    var msg = "JWT signing key is not configured. Set Jwt:Key via user-secrets or environment variable.";
    if (!builder.Environment.IsDevelopment())
    {
        throw new InvalidOperationException(msg);
    }

    // Development-only fallback to keep local auth flow operational.
    secret = "dev-only-jwt-key-change-me-at-least-32-chars";
    Log.Warning("{Message} Using development fallback key.", msg);
}
else
{
    secret = configuredSecret;

    if (secret.Length < 32)
    {
        var msg = "JWT signing key length is less than 32 characters - increase entropy.";
        if (!builder.Environment.IsDevelopment()) throw new InvalidOperationException(msg);
        Log.Warning("{Message}", msg);
    }
}

var key = Encoding.UTF8.GetBytes(secret);

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtSection.GetValue<string>("Issuer"),
        ValidAudience = jwtSection.GetValue<string>("Audience"),
        IssuerSigningKey = new SymmetricSecurityKey(key),
    };
});

builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("AdminOnly", policy => policy.RequireRole("Admin"));
    options.AddPolicy("EmployeeOrAdmin", policy => policy.RequireRole("Admin", "Employee"));
    options.AddPolicy("CustomerAccess", policy => policy.RequireRole("Admin", "Employee", "Customer"));
});

var app = builder.Build();

app.UseRequestLocalization();

app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "LawyerSys API v1");
    c.RoutePrefix = "swagger";
    c.DocExpansion(Swashbuckle.AspNetCore.SwaggerUI.DocExpansion.None);
});

app.UseHttpsRedirection();
app.UseCors("AllowReactClient");
app.UseRateLimiter();
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

try
{
    using var scope = app.Services.CreateScope();
    var scopedLegacy = scope.ServiceProvider.GetRequiredService<LegacyDbContext>();
    try
    {
        var tenantInitializer = new MultiTenancySchemaInitializer(scopedLegacy);
        await tenantInitializer.EnsureCreatedAsync();
    }
    catch (Exception ex)
    {
        Log.Error(ex, "Error during multi-tenancy schema initialization");
    }

    try
    {
        var initializer = new AuditLogSchemaInitializer(scopedLegacy);
        await initializer.EnsureCreatedAsync();
    }
    catch (Exception ex)
    {
        Log.Error(ex, "Error during audit schema initialization");
    }

    try
    {
        var trustInitializer = new TrustAccountingSchemaInitializer(scopedLegacy);
        await trustInitializer.EnsureCreatedAsync();
    }
    catch (Exception ex)
    {
        Log.Error(ex, "Error during trust accounting schema initialization");
    }
}
catch (Exception ex)
{
    Log.Error(ex, "Error during startup scope initialization");
}

app.Run();
