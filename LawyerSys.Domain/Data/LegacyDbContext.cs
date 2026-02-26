using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Text.Json;
using LawyerSys.Data.ScaffoldedModels;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ChangeTracking;
using FileEntity = LawyerSys.Data.ScaffoldedModels.File;

namespace LawyerSys.Data;

public partial class LegacyDbContext : DbContext
{
    private readonly IHttpContextAccessor? _httpContextAccessor;
    private bool _isSavingAuditLogs;
    private int CurrentFirmId
    {
        get
        {
            var httpContext = _httpContextAccessor?.HttpContext;
            if (httpContext == null)
            {
                return 1;
            }

            var headerValue = httpContext.Request.Headers["X-Firm-Id"].FirstOrDefault();
            if (int.TryParse(headerValue, out var fromHeader) && fromHeader > 0)
            {
                return fromHeader;
            }

            var claimValue = httpContext.User.FindFirst("firm_id")?.Value
                             ?? httpContext.User.FindFirst("FirmId")?.Value
                             ?? httpContext.User.FindFirst("tenant_id")?.Value
                             ?? httpContext.User.FindFirst(ClaimTypes.GroupSid)?.Value;
            if (int.TryParse(claimValue, out var fromClaim) && fromClaim > 0)
            {
                return fromClaim;
            }

            return 1;
        }
    }

    public LegacyDbContext(DbContextOptions<LegacyDbContext> options)
        : base(options)
    {
    }

    public LegacyDbContext(DbContextOptions<LegacyDbContext> options, IHttpContextAccessor httpContextAccessor)
        : base(options)
    {
        _httpContextAccessor = httpContextAccessor;
    }

    public virtual DbSet<AdminstrativeTask> AdminstrativeTasks { get; set; }

    public virtual DbSet<AuditLog> AuditLogs { get; set; }

    public virtual DbSet<App_Page> App_Pages { get; set; }

    public virtual DbSet<App_Sitting> App_Sittings { get; set; }

    public virtual DbSet<Billing_Pay> Billing_Pays { get; set; }

    public virtual DbSet<Billing_Receipt> Billing_Receipts { get; set; }

    public virtual DbSet<Case> Cases { get; set; }

    public virtual DbSet<Cases_Contender> Cases_Contenders { get; set; }

    public virtual DbSet<Cases_Court> Cases_Courts { get; set; }

    public virtual DbSet<Cases_Employee> Cases_Employees { get; set; }

    public virtual DbSet<Cases_File> Cases_Files { get; set; }

    public virtual DbSet<Cases_Siting> Cases_Sitings { get; set; }

    public virtual DbSet<CaseStatusHistory> CaseStatusHistories { get; set; }

    public virtual DbSet<Con_Lawyers_Custmor> Con_Lawyers_Custmors { get; set; }

    public virtual DbSet<Consltitions_Custmor> Consltitions_Custmors { get; set; }

    public virtual DbSet<Consulation> Consulations { get; set; }

    public virtual DbSet<Consulations_Employee> Consulations_Employees { get; set; }

    public virtual DbSet<Contender> Contenders { get; set; }

    public virtual DbSet<Contenders_Custmor> Contenders_Custmors { get; set; }

    public virtual DbSet<Contenders_Lawyer> Contenders_Lawyers { get; set; }

    public virtual DbSet<Court> Courts { get; set; }

    public virtual DbSet<Custmors_Case> Custmors_Cases { get; set; }

    public virtual DbSet<Customer> Customers { get; set; }

    public virtual DbSet<ESignatureRequest> ESignatureRequests { get; set; }

    public virtual DbSet<Employee> Employees { get; set; }

    public virtual DbSet<FileEntity> Files { get; set; }

    public virtual DbSet<Governament> Governaments { get; set; }

    public virtual DbSet<Judicial_Document> Judicial_Documents { get; set; }

    public virtual DbSet<IntakeLead> IntakeLeads { get; set; }

    public virtual DbSet<Siting> Sitings { get; set; }

    public virtual DbSet<User> Users { get; set; }

    public virtual DbSet<TrustLedgerEntry> TrustLedgerEntries { get; set; }

    public virtual DbSet<TrustReconciliation> TrustReconciliations { get; set; }

    public virtual DbSet<__EFMigrationsHistory_Legacy> __EFMigrationsHistory_Legacies { get; set; }

    public override int SaveChanges()
    {
        return SaveChangesAsync().GetAwaiter().GetResult();
    }

    public override int SaveChanges(bool acceptAllChangesOnSuccess)
    {
        return SaveChangesAsync(acceptAllChangesOnSuccess).GetAwaiter().GetResult();
    }

    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        return SaveChangesAsync(true, cancellationToken);
    }

    public override async Task<int> SaveChangesAsync(bool acceptAllChangesOnSuccess, CancellationToken cancellationToken = default)
    {
        if (_isSavingAuditLogs)
        {
            return await base.SaveChangesAsync(acceptAllChangesOnSuccess, cancellationToken);
        }

        ApplyFirmIdToAddedEntities();
        var pendingAudits = CapturePendingAuditEntries();
        var result = await base.SaveChangesAsync(acceptAllChangesOnSuccess, cancellationToken);

        if (pendingAudits.Count == 0)
        {
            return result;
        }

        var finalizedLogs = FinalizeAuditEntries(pendingAudits);
        if (finalizedLogs.Count == 0)
        {
            return result;
        }

        try
        {
            _isSavingAuditLogs = true;
            AuditLogs.AddRange(finalizedLogs);
            await base.SaveChangesAsync(acceptAllChangesOnSuccess, cancellationToken);
        }
        finally
        {
            _isSavingAuditLogs = false;
        }

        return result;
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<AdminstrativeTask>(entity =>
        {
            entity.Property(e => e.Notes).HasMaxLength(50);
            entity.Property(e => e.Task_Name).HasMaxLength(50);
            entity.Property(e => e.Task_Reminder_Date).HasColumnType("timestamp without time zone");
            entity.Property(e => e.Type).HasMaxLength(50);

            entity.HasOne(d => d.employee).WithMany(p => p.AdminstrativeTasks)
                .HasForeignKey(d => d.employee_Id)
                .HasConstraintName("FK_AdminstrativeTasks_AdminstrativeTasks");
        });

        modelBuilder.Entity<AuditLog>(entity =>
        {
            entity.ToTable("AuditLogs");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.EntityName).HasMaxLength(128);
            entity.Property(e => e.Action).HasMaxLength(16);
            entity.Property(e => e.EntityId).HasMaxLength(256);
            entity.Property(e => e.UserId).HasMaxLength(256);
            entity.Property(e => e.UserName).HasMaxLength(256);
            entity.Property(e => e.RequestPath).HasMaxLength(512);
            entity.Property(e => e.Timestamp).HasColumnType("timestamp without time zone");
        });

        modelBuilder.Entity<App_Page>(entity =>
        {
            entity.Property(e => e.Page_Name).HasMaxLength(50);
        });

        modelBuilder.Entity<App_Sitting>(entity =>
        {
            entity.ToTable("App_Sitting");

            entity.HasOne(d => d.App_Page).WithMany(p => p.App_Sittings)
                .HasForeignKey(d => d.App_PageID)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_App_Sitting_App_Pages");

            entity.HasOne(d => d.User).WithMany(p => p.App_Sittings)
                .HasForeignKey(d => d.User_Id)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_App_Sitting_Users");
        });

        modelBuilder.Entity<Billing_Pay>(entity =>
        {
            entity.ToTable("Billing_Pay");

            entity.HasOne(d => d.Custmor).WithMany(p => p.Billing_Pays)
                .HasForeignKey(d => d.Custmor_Id)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Billing_Pay_Customers");
        });

        modelBuilder.Entity<Billing_Receipt>(entity =>
        {
            entity.ToTable("Billing_Receipt");

            entity.HasOne(d => d.Employee).WithMany(p => p.Billing_Receipts)
                .HasForeignKey(d => d.Employee_Id)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Billing_Receipt_Customers");
        });

        modelBuilder.Entity<Case>(entity =>
        {
            entity.HasKey(e => e.Code).HasName("PK_Cases_1");

            entity.Property(e => e.Code).ValueGeneratedNever();
            entity.Property(e => e.Invition_Type).HasMaxLength(50);
            entity.Property(e => e.Invitions_Statment).HasMaxLength(50);
            entity.Property(e => e.Notes).HasMaxLength(50);
            entity.Property(e => e.Status).HasDefaultValue(0);
        });

        modelBuilder.Entity<CaseStatusHistory>(entity =>
        {
            entity.ToTable("CaseStatusHistory");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.ChangedAt).HasColumnType("timestamp without time zone");
            entity.HasOne(d => d.Case).WithMany(p => p.CaseStatusHistories)
                .HasForeignKey(d => d.Case_Id)
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("FK_CaseStatusHistory_Cases");
        });

        modelBuilder.Entity<Cases_Contender>(entity =>
        {
            entity.HasOne(d => d.Case).WithMany(p => p.Cases_Contenders)
                .HasForeignKey(d => d.Case_Id)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Cases_Contenders_Cases");

            entity.HasOne(d => d.Contender).WithMany(p => p.Cases_Contenders)
                .HasForeignKey(d => d.Contender_Id)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Cases_Contenders_Contenders");
        });

        modelBuilder.Entity<Cases_Court>(entity =>
        {
            entity.HasOne(d => d.Case_CodeNavigation).WithMany(p => p.Cases_Courts)
                .HasForeignKey(d => d.Case_Code)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Cases_Courts_Cases");

            entity.HasOne(d => d.Court).WithMany(p => p.Cases_Courts)
                .HasForeignKey(d => d.Court_Id)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Cases_Courts_Courts");
        });

        modelBuilder.Entity<Cases_Employee>(entity =>
        {
            entity.HasOne(d => d.Employee).WithMany(p => p.Cases_Employees)
                .HasForeignKey(d => d.Employee_Id)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Cases_Employees_Employees");
        });

        modelBuilder.Entity<Cases_File>(entity =>
        {
            entity.HasOne(d => d.Case).WithMany(p => p.Cases_Files)
                .HasForeignKey(d => d.Case_Id)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Cases_Files_Cases");

            entity.HasOne(d => d.File).WithMany(p => p.Cases_Files)
                .HasForeignKey(d => d.File_Id)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Cases_Files_Files");
        });

        modelBuilder.Entity<Cases_Siting>(entity =>
        {
            entity.HasOne(d => d.Case_CodeNavigation).WithMany(p => p.Cases_Sitings)
                .HasForeignKey(d => d.Case_Code)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Cases_Sitings_Cases");

            entity.HasOne(d => d.Siting).WithMany(p => p.Cases_Sitings)
                .HasForeignKey(d => d.Siting_Id)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Cases_Sitings_Sitings");
        });

        modelBuilder.Entity<Con_Lawyers_Custmor>(entity =>
        {
            entity.HasOne(d => d.Con_Lawyer).WithMany(p => p.Con_Lawyers_Custmors)
                .HasForeignKey(d => d.Con_Lawyer_Id)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Con_Lawyers_Custmors_Contenders_Lawyers");
        });

        modelBuilder.Entity<Consltitions_Custmor>(entity =>
        {
            entity.HasOne(d => d.Consl).WithMany(p => p.Consltitions_Custmors)
                .HasForeignKey(d => d.Consl_Id)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Consltitions_Custmors_Consulations");

            entity.HasOne(d => d.Customer).WithMany(p => p.Consltitions_Custmors)
                .HasForeignKey(d => d.Customer_Id)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Consltitions_Custmors_Customers");
        });

        modelBuilder.Entity<Consulation>(entity =>
        {
            entity.Property(e => e.Consultion_State).HasMaxLength(50);
            entity.Property(e => e.Date_time).HasColumnType("timestamp without time zone");
            entity.Property(e => e.Descraption).HasMaxLength(50);
            entity.Property(e => e.Feedback).HasMaxLength(50);
            entity.Property(e => e.Notes).HasMaxLength(50);
            entity.Property(e => e.Subject).HasMaxLength(50);
            entity.Property(e => e.Type).HasMaxLength(50);
        });

        modelBuilder.Entity<Consulations_Employee>(entity =>
        {
            entity.ToTable("Consulations_Employee");

            entity.HasOne(d => d.Employee).WithMany(p => p.Consulations_Employees)
                .HasForeignKey(d => d.Employee_Id)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Consulations_Employee_Employees");
        });

        modelBuilder.Entity<Contender>(entity =>
        {
            entity.Property(e => e.Full_Name).HasMaxLength(50);
        });

        modelBuilder.Entity<Contenders_Custmor>(entity =>
        {
            entity.HasOne(d => d.Con).WithMany(p => p.Contenders_Custmors)
                .HasForeignKey(d => d.Con_Id)
                .HasConstraintName("FK_Contenders_Custmors_Contenders");

            entity.HasOne(d => d.Con_Lawyer).WithMany(p => p.Contenders_Custmors)
                .HasForeignKey(d => d.Con_Lawyer_ID)
                .HasConstraintName("FK_Contenders_Custmors_Contenders_Lawyers");
        });

        modelBuilder.Entity<Contenders_Lawyer>(entity =>
        {
            entity.HasOne(d => d.Contender).WithMany(p => p.Contenders_Lawyers)
                .HasForeignKey(d => d.Contender_Id)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Contenders_Lawyers_Contenders");
        });

        modelBuilder.Entity<Court>(entity =>
        {
            entity.Property(e => e.Address).HasMaxLength(50);
            entity.Property(e => e.Name).HasMaxLength(50);
            entity.Property(e => e.Notes).HasMaxLength(50);
            entity.Property(e => e.Telephone).HasMaxLength(50);

            entity.HasOne(d => d.Gov).WithMany(p => p.Courts)
                .HasForeignKey(d => d.Gov_Id)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Courts_Governaments");
        });

        modelBuilder.Entity<Custmors_Case>(entity =>
        {
            entity.HasOne(d => d.Case).WithMany(p => p.Custmors_Cases)
                .HasForeignKey(d => d.Case_Id)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Custmors_Cases_Cases");

            entity.HasOne(d => d.Custmors).WithMany(p => p.Custmors_Cases)
                .HasForeignKey(d => d.Custmors_Id)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Custmors_Cases_Customers");
        });

        modelBuilder.Entity<Customer>(entity =>
        {
            entity.HasOne(d => d.Users).WithMany(p => p.Customers)
                .HasForeignKey(d => d.Users_Id)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Customers_Customers");
        });

        modelBuilder.Entity<ESignatureRequest>(entity =>
        {
            entity.ToTable("ESignatureRequests");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.RequestTitle).HasMaxLength(200);
            entity.Property(e => e.TemplateType).HasMaxLength(80);
            entity.Property(e => e.SignerName).HasMaxLength(120);
            entity.Property(e => e.SignerEmail).HasMaxLength(256);
            entity.Property(e => e.SignerPhoneNumber).HasMaxLength(32);
            entity.Property(e => e.Message).HasMaxLength(2000);
            entity.Property(e => e.Status).HasMaxLength(24);
            entity.Property(e => e.ExternalReference).HasMaxLength(200);
            entity.Property(e => e.PublicToken).HasMaxLength(120);
            entity.Property(e => e.SignedByName).HasMaxLength(120);
            entity.Property(e => e.RequestedBy).HasMaxLength(256);
            entity.Property(e => e.RequestedAt).HasColumnType("timestamp without time zone");
            entity.Property(e => e.SignedAt).HasColumnType("timestamp without time zone");
            entity.Property(e => e.TokenExpiresAt).HasColumnType("timestamp without time zone");
            entity.Property(e => e.UpdatedAt).HasColumnType("timestamp without time zone");
        });

        modelBuilder.Entity<Employee>(entity =>
        {
            entity.HasOne(d => d.Users).WithMany(p => p.Employees)
                .HasForeignKey(d => d.Users_Id)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Employees_Users");
        });

        modelBuilder.Entity<FileEntity>(entity =>
        {
            entity.Property(e => e.Code).HasMaxLength(50);
            entity.Property(e => e.Path).HasMaxLength(50);
        });

        modelBuilder.Entity<Governament>(entity =>
        {
            entity.Property(e => e.Id).ValueGeneratedNever();
            entity.Property(e => e.Gov_Name).HasMaxLength(50);
        });

        modelBuilder.Entity<Judicial_Document>(entity =>
        {
            entity.Property(e => e.Doc_Details).HasMaxLength(50);
            entity.Property(e => e.Doc_Type).HasMaxLength(50);
            entity.Property(e => e.Notes).HasMaxLength(50);

            entity.HasOne(d => d.Customers).WithMany(p => p.Judicial_Documents)
                .HasForeignKey(d => d.Customers_Id)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Judicial_Documents_Customers");
        });

        modelBuilder.Entity<Siting>(entity =>
        {
            entity.Property(e => e.Judge_Name).HasMaxLength(50);
            entity.Property(e => e.Notes).HasMaxLength(50);
            entity.Property(e => e.Siting_Notification).HasColumnType("timestamp without time zone");
            entity.Property(e => e.Siting_Time).HasColumnType("timestamp without time zone");
        });

        modelBuilder.Entity<User>(entity =>
        {
            entity.Property(e => e.Id).ValueGeneratedNever();
            entity.Property(e => e.Address).HasMaxLength(50);
            entity.Property(e => e.Full_Name).HasMaxLength(50);
            entity.Property(e => e.Job).HasMaxLength(50);
            entity.Property(e => e.Password).HasMaxLength(50);
            entity.Property(e => e.User_Name).HasMaxLength(50);
        });

        modelBuilder.Entity<TrustLedgerEntry>(entity =>
        {
            entity.ToTable("TrustLedgerEntries");

            entity.Property(e => e.EntryType).HasMaxLength(32);
            entity.Property(e => e.Description).HasMaxLength(1024);
            entity.Property(e => e.Reference).HasMaxLength(128);
            entity.Property(e => e.CreatedBy).HasMaxLength(256);
            entity.Property(e => e.CreatedAt).HasColumnType("timestamp without time zone");

            entity.HasOne(d => d.Customer).WithMany()
                .HasForeignKey(d => d.CustomerId)
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("FK_TrustLedgerEntries_Customers");

            entity.HasOne(d => d.Case).WithMany()
                .HasForeignKey(d => d.CaseCode)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("FK_TrustLedgerEntries_Cases");
        });

        modelBuilder.Entity<TrustReconciliation>(entity =>
        {
            entity.ToTable("TrustReconciliations");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Notes).HasMaxLength(1024);
            entity.Property(e => e.CreatedBy).HasMaxLength(256);
            entity.Property(e => e.CreatedAt).HasColumnType("timestamp without time zone");
        });

        modelBuilder.Entity<IntakeLead>(entity =>
        {
            entity.ToTable("IntakeLeads");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.FullName).HasMaxLength(120);
            entity.Property(e => e.Email).HasMaxLength(256);
            entity.Property(e => e.PhoneNumber).HasMaxLength(32);
            entity.Property(e => e.NationalId).HasMaxLength(32);
            entity.Property(e => e.Subject).HasMaxLength(200);
            entity.Property(e => e.Description).HasMaxLength(2000);
            entity.Property(e => e.DesiredCaseType).HasMaxLength(80);
            entity.Property(e => e.Status).HasMaxLength(32);
            entity.Property(e => e.QualificationNotes).HasMaxLength(1024);
            entity.Property(e => e.ConflictDetails).HasMaxLength(1024);
            entity.Property(e => e.AssignedAt).HasColumnType("timestamp without time zone");
            entity.Property(e => e.NextFollowUpAt).HasColumnType("timestamp without time zone");
            entity.Property(e => e.CreatedAt).HasColumnType("timestamp without time zone");
            entity.Property(e => e.UpdatedAt).HasColumnType("timestamp without time zone");
        });

        modelBuilder.Entity<__EFMigrationsHistory_Legacy>(entity =>
        {
            entity.HasKey(e => e.MigrationId);

            entity.ToTable("__EFMigrationsHistory_Legacy");

            entity.Property(e => e.MigrationId).HasMaxLength(150);
            entity.Property(e => e.ProductVersion).HasMaxLength(32);
        });

        ConfigureTenantEntity<AdminstrativeTask>(modelBuilder);
        ConfigureTenantEntity<AuditLog>(modelBuilder);
        ConfigureTenantEntity<Billing_Pay>(modelBuilder);
        ConfigureTenantEntity<Billing_Receipt>(modelBuilder);
        ConfigureTenantEntity<Case>(modelBuilder);
        ConfigureTenantEntity<CaseStatusHistory>(modelBuilder);
        ConfigureTenantEntity<Cases_Contender>(modelBuilder);
        ConfigureTenantEntity<Cases_Court>(modelBuilder);
        ConfigureTenantEntity<Cases_Employee>(modelBuilder);
        ConfigureTenantEntity<Cases_File>(modelBuilder);
        ConfigureTenantEntity<Cases_Siting>(modelBuilder);
        ConfigureTenantEntity<Con_Lawyers_Custmor>(modelBuilder);
        ConfigureTenantEntity<Consltitions_Custmor>(modelBuilder);
        ConfigureTenantEntity<Consulation>(modelBuilder);
        ConfigureTenantEntity<Consulations_Employee>(modelBuilder);
        ConfigureTenantEntity<Contender>(modelBuilder);
        ConfigureTenantEntity<Contenders_Custmor>(modelBuilder);
        ConfigureTenantEntity<Contenders_Lawyer>(modelBuilder);
        ConfigureTenantEntity<Court>(modelBuilder);
        ConfigureTenantEntity<Custmors_Case>(modelBuilder);
        ConfigureTenantEntity<Customer>(modelBuilder);
        ConfigureTenantEntity<ESignatureRequest>(modelBuilder);
        ConfigureTenantEntity<Employee>(modelBuilder);
        ConfigureTenantEntity<FileEntity>(modelBuilder);
        ConfigureTenantEntity<Governament>(modelBuilder);
        ConfigureTenantEntity<Judicial_Document>(modelBuilder);
        ConfigureTenantEntity<IntakeLead>(modelBuilder);
        ConfigureTenantEntity<Siting>(modelBuilder);
        ConfigureTenantEntity<TrustLedgerEntry>(modelBuilder);
        ConfigureTenantEntity<TrustReconciliation>(modelBuilder);
        ConfigureTenantEntity<User>(modelBuilder);

        OnModelCreatingPartial(modelBuilder);
    }

    private void ApplyFirmIdToAddedEntities()
    {
        var firmId = CurrentFirmId;
        foreach (var entry in ChangeTracker.Entries().Where(e => e.State == EntityState.Added))
        {
            var firmProperty = entry.Metadata.FindProperty("FirmId");
            if (firmProperty is null)
            {
                continue;
            }

            var current = entry.Property("FirmId").CurrentValue;
            if (current is null || (current is int intValue && intValue <= 0))
            {
                entry.Property("FirmId").CurrentValue = firmId;
            }
        }
    }

    private void ConfigureTenantEntity<TEntity>(ModelBuilder modelBuilder) where TEntity : class
    {
        modelBuilder.Entity<TEntity>().Property<int>("FirmId").HasDefaultValue(1);
        modelBuilder.Entity<TEntity>().HasIndex("FirmId");
        modelBuilder.Entity<TEntity>().HasQueryFilter(e => EF.Property<int>(e, "FirmId") == CurrentFirmId);
    }

    private List<PendingAuditEntry> CapturePendingAuditEntries()
    {
        ChangeTracker.DetectChanges();

        var now = DateTime.UtcNow;
        var httpContext = _httpContextAccessor?.HttpContext;
        var userId = httpContext?.User?.FindFirst("sub")?.Value
                     ?? httpContext?.User?.FindFirst("http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier")?.Value;
        var userName = httpContext?.User?.Identity?.Name;
        var requestPath = httpContext?.Request?.Path.Value;

        var list = new List<PendingAuditEntry>();
        foreach (var entry in ChangeTracker.Entries())
        {
            if (entry.State is EntityState.Detached or EntityState.Unchanged)
            {
                continue;
            }

            if (entry.Entity is AuditLog)
            {
                continue;
            }

            if (entry.State is not (EntityState.Added or EntityState.Modified or EntityState.Deleted))
            {
                continue;
            }

            var pending = new PendingAuditEntry
            {
                Entry = entry,
                EntityName = entry.Metadata.ClrType.Name,
                Action = entry.State switch
                {
                    EntityState.Added => "Create",
                    EntityState.Modified => "Update",
                    EntityState.Deleted => "Delete",
                    _ => "Unknown"
                },
                UserId = userId,
                UserName = userName,
                RequestPath = requestPath,
                Timestamp = now
            };

            foreach (var property in entry.Properties)
            {
                if (property.Metadata.IsPrimaryKey())
                {
                    if (property.IsTemporary)
                    {
                        pending.TemporaryProperties.Add(property);
                    }
                    else
                    {
                        pending.KeyValues[property.Metadata.Name] = property.CurrentValue;
                    }

                    continue;
                }

                var isSensitive = property.Metadata.Name.Contains("Password", StringComparison.OrdinalIgnoreCase);
                var originalValue = isSensitive ? "***" : property.OriginalValue;
                var currentValue = isSensitive ? "***" : property.CurrentValue;

                switch (entry.State)
                {
                    case EntityState.Added:
                        pending.NewValues[property.Metadata.Name] = currentValue;
                        break;
                    case EntityState.Deleted:
                        pending.OldValues[property.Metadata.Name] = originalValue;
                        break;
                    case EntityState.Modified:
                        if (!property.IsModified)
                        {
                            break;
                        }

                        pending.OldValues[property.Metadata.Name] = originalValue;
                        pending.NewValues[property.Metadata.Name] = currentValue;
                        break;
                }
            }

            list.Add(pending);
        }

        return list;
    }

    private List<AuditLog> FinalizeAuditEntries(IEnumerable<PendingAuditEntry> pendingEntries)
    {
        var logs = new List<AuditLog>();
        foreach (var pending in pendingEntries)
        {
            foreach (var prop in pending.TemporaryProperties)
            {
                if (prop.Metadata.IsPrimaryKey())
                {
                    pending.KeyValues[prop.Metadata.Name] = prop.CurrentValue;
                }
            }

            var entityId = pending.KeyValues.Count == 0
                ? null
                : string.Join(",", pending.KeyValues.Select(kv => $"{kv.Key}:{kv.Value}"));

            logs.Add(new AuditLog
            {
                EntityName = pending.EntityName,
                Action = pending.Action,
                EntityId = entityId,
                OldValues = pending.OldValues.Count == 0 ? null : JsonSerializer.Serialize(pending.OldValues),
                NewValues = pending.NewValues.Count == 0 ? null : JsonSerializer.Serialize(pending.NewValues),
                UserId = pending.UserId,
                UserName = pending.UserName,
                Timestamp = pending.Timestamp,
                RequestPath = pending.RequestPath
            });
        }

        return logs;
    }

    private sealed class PendingAuditEntry
    {
        public required EntityEntry Entry { get; init; }
        public required string EntityName { get; init; }
        public required string Action { get; init; }
        public string? UserId { get; init; }
        public string? UserName { get; init; }
        public string? RequestPath { get; init; }
        public DateTime Timestamp { get; init; }
        public Dictionary<string, object?> KeyValues { get; } = new();
        public Dictionary<string, object?> OldValues { get; } = new();
        public Dictionary<string, object?> NewValues { get; } = new();
        public List<PropertyEntry> TemporaryProperties { get; } = new();
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
