using System;
using System.Collections.Generic;
using LawyerSys.Data.ScaffoldedModels;
using Microsoft.EntityFrameworkCore;
using FileEntity = LawyerSys.Data.ScaffoldedModels.File;

namespace LawyerSys.Data;

public partial class LegacyDbContext : DbContext
{
    public LegacyDbContext(DbContextOptions<LegacyDbContext> options)
        : base(options)
    {
    }

    public virtual DbSet<AdminstrativeTask> AdminstrativeTasks { get; set; }

    public virtual DbSet<App_Page> App_Pages { get; set; }

    public virtual DbSet<App_Sitting> App_Sittings { get; set; }

    public virtual DbSet<AspNetRole> AspNetRoles { get; set; }

    public virtual DbSet<AspNetRoleClaim> AspNetRoleClaims { get; set; }

    public virtual DbSet<AspNetUser> AspNetUsers { get; set; }

    public virtual DbSet<AspNetUserClaim> AspNetUserClaims { get; set; }

    public virtual DbSet<AspNetUserLogin> AspNetUserLogins { get; set; }

    public virtual DbSet<AspNetUserToken> AspNetUserTokens { get; set; }

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

    public virtual DbSet<Employee> Employees { get; set; }

    public virtual DbSet<FileEntity> Files { get; set; }

    public virtual DbSet<Governament> Governaments { get; set; }

    public virtual DbSet<Judicial_Document> Judicial_Documents { get; set; }

    public virtual DbSet<Siting> Sitings { get; set; }

    public virtual DbSet<User> Users { get; set; }

    public virtual DbSet<__EFMigrationsHistory_Legacy> __EFMigrationsHistory_Legacies { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<AdminstrativeTask>(entity =>
        {
            entity.Property(e => e.Notes).HasMaxLength(50);
            entity.Property(e => e.Task_Name).HasMaxLength(50);
            entity.Property(e => e.Task_Reminder_Date).HasColumnType("datetime");
            entity.Property(e => e.Type).HasMaxLength(50);

            entity.HasOne(d => d.employee).WithMany(p => p.AdminstrativeTasks)
                .HasForeignKey(d => d.employee_Id)
                .HasConstraintName("FK_AdminstrativeTasks_AdminstrativeTasks");
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

        modelBuilder.Entity<AspNetRole>(entity =>
        {
            entity.HasIndex(e => e.NormalizedName, "RoleNameIndex")
                .IsUnique()
                .HasFilter("([NormalizedName] IS NOT NULL)");

            entity.Property(e => e.Name).HasMaxLength(256);
            entity.Property(e => e.NormalizedName).HasMaxLength(256);
        });

        modelBuilder.Entity<AspNetRoleClaim>(entity =>
        {
            entity.HasIndex(e => e.RoleId, "IX_AspNetRoleClaims_RoleId");

            entity.HasOne(d => d.Role).WithMany(p => p.AspNetRoleClaims).HasForeignKey(d => d.RoleId);
        });

        modelBuilder.Entity<AspNetUser>(entity =>
        {
            entity.HasIndex(e => e.NormalizedEmail, "EmailIndex");

            entity.HasIndex(e => e.NormalizedUserName, "UserNameIndex")
                .IsUnique()
                .HasFilter("([NormalizedUserName] IS NOT NULL)");

            entity.Property(e => e.Email).HasMaxLength(256);
            entity.Property(e => e.NormalizedEmail).HasMaxLength(256);
            entity.Property(e => e.NormalizedUserName).HasMaxLength(256);
            entity.Property(e => e.UserName).HasMaxLength(256);

            entity.HasMany(d => d.Roles).WithMany(p => p.Users)
                .UsingEntity<Dictionary<string, object>>(
                    "AspNetUserRole",
                    r => r.HasOne<AspNetRole>().WithMany().HasForeignKey("RoleId"),
                    l => l.HasOne<AspNetUser>().WithMany().HasForeignKey("UserId"),
                    j =>
                    {
                        j.HasKey("UserId", "RoleId");
                        j.ToTable("AspNetUserRoles");
                        j.HasIndex(new[] { "RoleId" }, "IX_AspNetUserRoles_RoleId");
                    });
        });

        modelBuilder.Entity<AspNetUserClaim>(entity =>
        {
            entity.HasIndex(e => e.UserId, "IX_AspNetUserClaims_UserId");

            entity.HasOne(d => d.User).WithMany(p => p.AspNetUserClaims).HasForeignKey(d => d.UserId);
        });

        modelBuilder.Entity<AspNetUserLogin>(entity =>
        {
            entity.HasKey(e => new { e.LoginProvider, e.ProviderKey });

            entity.HasIndex(e => e.UserId, "IX_AspNetUserLogins_UserId");

            entity.HasOne(d => d.User).WithMany(p => p.AspNetUserLogins).HasForeignKey(d => d.UserId);
        });

        modelBuilder.Entity<AspNetUserToken>(entity =>
        {
            entity.HasKey(e => new { e.UserId, e.LoginProvider, e.Name });

            entity.HasOne(d => d.User).WithMany(p => p.AspNetUserTokens).HasForeignKey(d => d.UserId);
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
            entity.Property(e => e.ChangedAt).HasColumnType("datetime");
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
            entity.Property(e => e.Date_time).HasColumnType("datetime");
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
            entity.Property(e => e.Siting_Notification).HasColumnType("datetime");
            entity.Property(e => e.Siting_Time).HasColumnType("datetime");
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

        modelBuilder.Entity<__EFMigrationsHistory_Legacy>(entity =>
        {
            entity.HasKey(e => e.MigrationId);

            entity.ToTable("__EFMigrationsHistory_Legacy");

            entity.Property(e => e.MigrationId).HasMaxLength(150);
            entity.Property(e => e.ProductVersion).HasMaxLength(32);
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
