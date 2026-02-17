using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LawyerSys.Data.Migrations.Legacy
{
    /// <inheritdoc />
    public partial class AddCaseStatusAndHistory : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "Status",
                table: "Cases",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateTable(
                name: "__EFMigrationsHistory_Legacy",
                columns: table => new
                {
                    MigrationId = table.Column<string>(type: "nvarchar(150)", maxLength: 150, nullable: false),
                    ProductVersion = table.Column<string>(type: "nvarchar(32)", maxLength: 32, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK___EFMigrationsHistory_Legacy", x => x.MigrationId);
                });

            migrationBuilder.CreateTable(
                name: "AdminstrativeTasks",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Task_Name = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Type = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Task_Date = table.Column<DateOnly>(type: "date", nullable: false),
                    Task_Reminder_Date = table.Column<DateTime>(type: "datetime", nullable: false),
                    Notes = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    employee_Id = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AdminstrativeTasks", x => x.Id);
                    table.ForeignKey(
                        name: "FK_AdminstrativeTasks_AdminstrativeTasks",
                        column: x => x.employee_Id,
                        principalTable: "Employees",
                        principalColumn: "id");
                });

            migrationBuilder.CreateTable(
                name: "App_Pages",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Page_Name = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_App_Pages", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "AspNetRoles",
                columns: table => new
                {
                    Id = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    Name = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: true),
                    NormalizedName = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: true),
                    ConcurrencyStamp = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AspNetRoles", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "AspNetUsers",
                columns: table => new
                {
                    Id = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    UserName = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: true),
                    NormalizedUserName = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: true),
                    Email = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: true),
                    NormalizedEmail = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: true),
                    EmailConfirmed = table.Column<bool>(type: "bit", nullable: false),
                    PasswordHash = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    SecurityStamp = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    ConcurrencyStamp = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    PhoneNumber = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    PhoneNumberConfirmed = table.Column<bool>(type: "bit", nullable: false),
                    TwoFactorEnabled = table.Column<bool>(type: "bit", nullable: false),
                    LockoutEnd = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true),
                    LockoutEnabled = table.Column<bool>(type: "bit", nullable: false),
                    AccessFailedCount = table.Column<int>(type: "int", nullable: false),
                    RequiresPasswordReset = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AspNetUsers", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Billing_Pay",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Amount = table.Column<double>(type: "float", nullable: false),
                    Date_Of_Opreation = table.Column<DateOnly>(type: "date", nullable: false),
                    Notes = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Custmor_Id = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Billing_Pay", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Billing_Pay_Customers",
                        column: x => x.Custmor_Id,
                        principalTable: "Customers",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "Billing_Receipt",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Amount = table.Column<double>(type: "float", nullable: false),
                    Date_Of_Opreation = table.Column<DateOnly>(type: "date", nullable: false),
                    Notes = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Employee_Id = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Billing_Receipt", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Billing_Receipt_Customers",
                        column: x => x.Employee_Id,
                        principalTable: "Customers",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "Cases_Employees",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Case_Code = table.Column<int>(type: "int", nullable: false),
                    Employee_Id = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Cases_Employees", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Cases_Employees_Employees",
                        column: x => x.Employee_Id,
                        principalTable: "Employees",
                        principalColumn: "id");
                });

            migrationBuilder.CreateTable(
                name: "Cases_Files",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Case_Id = table.Column<int>(type: "int", nullable: false),
                    File_Id = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Cases_Files", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Cases_Files_Cases",
                        column: x => x.Case_Id,
                        principalTable: "Cases",
                        principalColumn: "Code");
                    table.ForeignKey(
                        name: "FK_Cases_Files_Files",
                        column: x => x.File_Id,
                        principalTable: "Files",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "CaseStatusHistory",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Case_Id = table.Column<int>(type: "int", nullable: false),
                    OldStatus = table.Column<int>(type: "int", nullable: false),
                    NewStatus = table.Column<int>(type: "int", nullable: false),
                    ChangedBy = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    ChangedAt = table.Column<DateTime>(type: "datetime", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CaseStatusHistory", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CaseStatusHistory_Cases",
                        column: x => x.Case_Id,
                        principalTable: "Cases",
                        principalColumn: "Code",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Consulations",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Consultion_State = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Type = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Subject = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Descraption = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Feedback = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Notes = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Date_time = table.Column<DateTime>(type: "datetime", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Consulations", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Consulations_Employee",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Consl_ID = table.Column<int>(type: "int", nullable: false),
                    Employee_Id = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Consulations_Employee", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Consulations_Employee_Employees",
                        column: x => x.Employee_Id,
                        principalTable: "Employees",
                        principalColumn: "id");
                });

            migrationBuilder.CreateTable(
                name: "Contenders",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Full_Name = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    SSN = table.Column<int>(type: "int", nullable: false),
                    BirthDate = table.Column<DateOnly>(type: "date", nullable: false),
                    Type = table.Column<bool>(type: "bit", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Contenders", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Custmors_Cases",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Case_Id = table.Column<int>(type: "int", nullable: false),
                    Custmors_Id = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Custmors_Cases", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Custmors_Cases_Cases",
                        column: x => x.Case_Id,
                        principalTable: "Cases",
                        principalColumn: "Code");
                    table.ForeignKey(
                        name: "FK_Custmors_Cases_Customers",
                        column: x => x.Custmors_Id,
                        principalTable: "Customers",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "Governaments",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false),
                    Gov_Name = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Governaments", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Judicial_Documents",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Doc_Type = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Doc_Num = table.Column<int>(type: "int", nullable: false),
                    Doc_Details = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Notes = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Num_Of_Agent = table.Column<int>(type: "int", nullable: false),
                    Customers_Id = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Judicial_Documents", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Judicial_Documents_Customers",
                        column: x => x.Customers_Id,
                        principalTable: "Customers",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "Sitings",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Siting_Time = table.Column<DateTime>(type: "datetime", nullable: false),
                    Siting_Date = table.Column<DateOnly>(type: "date", nullable: false),
                    Siting_Notification = table.Column<DateTime>(type: "datetime", nullable: false),
                    Judge_Name = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Notes = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Sitings", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "App_Sitting",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    User_Id = table.Column<int>(type: "int", nullable: false),
                    App_PageID = table.Column<int>(type: "int", nullable: false),
                    IsVaild = table.Column<bool>(type: "bit", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_App_Sitting", x => x.Id);
                    table.ForeignKey(
                        name: "FK_App_Sitting_App_Pages",
                        column: x => x.App_PageID,
                        principalTable: "App_Pages",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_App_Sitting_Users",
                        column: x => x.User_Id,
                        principalTable: "Users",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "AspNetRoleClaims",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    RoleId = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    ClaimType = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    ClaimValue = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AspNetRoleClaims", x => x.Id);
                    table.ForeignKey(
                        name: "FK_AspNetRoleClaims_AspNetRoles_RoleId",
                        column: x => x.RoleId,
                        principalTable: "AspNetRoles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "AspNetUserClaims",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserId = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    ClaimType = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    ClaimValue = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AspNetUserClaims", x => x.Id);
                    table.ForeignKey(
                        name: "FK_AspNetUserClaims_AspNetUsers_UserId",
                        column: x => x.UserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "AspNetUserLogins",
                columns: table => new
                {
                    LoginProvider = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    ProviderKey = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    ProviderDisplayName = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    UserId = table.Column<string>(type: "nvarchar(450)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AspNetUserLogins", x => new { x.LoginProvider, x.ProviderKey });
                    table.ForeignKey(
                        name: "FK_AspNetUserLogins_AspNetUsers_UserId",
                        column: x => x.UserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "AspNetUserRoles",
                columns: table => new
                {
                    UserId = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    RoleId = table.Column<string>(type: "nvarchar(450)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AspNetUserRoles", x => new { x.UserId, x.RoleId });
                    table.ForeignKey(
                        name: "FK_AspNetUserRoles_AspNetRoles_RoleId",
                        column: x => x.RoleId,
                        principalTable: "AspNetRoles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_AspNetUserRoles_AspNetUsers_UserId",
                        column: x => x.UserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "AspNetUserTokens",
                columns: table => new
                {
                    UserId = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    LoginProvider = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    Name = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    Value = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AspNetUserTokens", x => new { x.UserId, x.LoginProvider, x.Name });
                    table.ForeignKey(
                        name: "FK_AspNetUserTokens_AspNetUsers_UserId",
                        column: x => x.UserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Consltitions_Custmors",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Customer_Id = table.Column<int>(type: "int", nullable: false),
                    Consl_Id = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Consltitions_Custmors", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Consltitions_Custmors_Consulations",
                        column: x => x.Consl_Id,
                        principalTable: "Consulations",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_Consltitions_Custmors_Customers",
                        column: x => x.Customer_Id,
                        principalTable: "Customers",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "Cases_Contenders",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Case_Id = table.Column<int>(type: "int", nullable: false),
                    Contender_Id = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Cases_Contenders", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Cases_Contenders_Cases",
                        column: x => x.Case_Id,
                        principalTable: "Cases",
                        principalColumn: "Code");
                    table.ForeignKey(
                        name: "FK_Cases_Contenders_Contenders",
                        column: x => x.Contender_Id,
                        principalTable: "Contenders",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "Contenders_Lawyers",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Contender_Id = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Contenders_Lawyers", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Contenders_Lawyers_Contenders",
                        column: x => x.Contender_Id,
                        principalTable: "Contenders",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "Courts",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Address = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Telephone = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Notes = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Gov_Id = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Courts", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Courts_Governaments",
                        column: x => x.Gov_Id,
                        principalTable: "Governaments",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "Cases_Sitings",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Case_Code = table.Column<int>(type: "int", nullable: false),
                    Siting_Id = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Cases_Sitings", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Cases_Sitings_Cases",
                        column: x => x.Case_Code,
                        principalTable: "Cases",
                        principalColumn: "Code");
                    table.ForeignKey(
                        name: "FK_Cases_Sitings_Sitings",
                        column: x => x.Siting_Id,
                        principalTable: "Sitings",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "Con_Lawyers_Custmors",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Con_Custmor_Id = table.Column<int>(type: "int", nullable: false),
                    Con_Lawyer_Id = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Con_Lawyers_Custmors", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Con_Lawyers_Custmors_Contenders_Lawyers",
                        column: x => x.Con_Lawyer_Id,
                        principalTable: "Contenders_Lawyers",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "Contenders_Custmors",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Con_Lawyer_ID = table.Column<int>(type: "int", nullable: true),
                    Con_Id = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Contenders_Custmors", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Contenders_Custmors_Contenders",
                        column: x => x.Con_Id,
                        principalTable: "Contenders",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_Contenders_Custmors_Contenders_Lawyers",
                        column: x => x.Con_Lawyer_ID,
                        principalTable: "Contenders_Lawyers",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "Cases_Courts",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Court_Id = table.Column<int>(type: "int", nullable: false),
                    Case_Code = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Cases_Courts", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Cases_Courts_Cases",
                        column: x => x.Case_Code,
                        principalTable: "Cases",
                        principalColumn: "Code");
                    table.ForeignKey(
                        name: "FK_Cases_Courts_Courts",
                        column: x => x.Court_Id,
                        principalTable: "Courts",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateIndex(
                name: "IX_AdminstrativeTasks_employee_Id",
                table: "AdminstrativeTasks",
                column: "employee_Id");

            migrationBuilder.CreateIndex(
                name: "IX_App_Sitting_App_PageID",
                table: "App_Sitting",
                column: "App_PageID");

            migrationBuilder.CreateIndex(
                name: "IX_App_Sitting_User_Id",
                table: "App_Sitting",
                column: "User_Id");

            migrationBuilder.CreateIndex(
                name: "IX_AspNetRoleClaims_RoleId",
                table: "AspNetRoleClaims",
                column: "RoleId");

            migrationBuilder.CreateIndex(
                name: "RoleNameIndex",
                table: "AspNetRoles",
                column: "NormalizedName",
                unique: true,
                filter: "([NormalizedName] IS NOT NULL)");

            migrationBuilder.CreateIndex(
                name: "IX_AspNetUserClaims_UserId",
                table: "AspNetUserClaims",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_AspNetUserLogins_UserId",
                table: "AspNetUserLogins",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_AspNetUserRoles_RoleId",
                table: "AspNetUserRoles",
                column: "RoleId");

            migrationBuilder.CreateIndex(
                name: "EmailIndex",
                table: "AspNetUsers",
                column: "NormalizedEmail");

            migrationBuilder.CreateIndex(
                name: "UserNameIndex",
                table: "AspNetUsers",
                column: "NormalizedUserName",
                unique: true,
                filter: "([NormalizedUserName] IS NOT NULL)");

            migrationBuilder.CreateIndex(
                name: "IX_Billing_Pay_Custmor_Id",
                table: "Billing_Pay",
                column: "Custmor_Id");

            migrationBuilder.CreateIndex(
                name: "IX_Billing_Receipt_Employee_Id",
                table: "Billing_Receipt",
                column: "Employee_Id");

            migrationBuilder.CreateIndex(
                name: "IX_Cases_Contenders_Case_Id",
                table: "Cases_Contenders",
                column: "Case_Id");

            migrationBuilder.CreateIndex(
                name: "IX_Cases_Contenders_Contender_Id",
                table: "Cases_Contenders",
                column: "Contender_Id");

            migrationBuilder.CreateIndex(
                name: "IX_Cases_Courts_Case_Code",
                table: "Cases_Courts",
                column: "Case_Code");

            migrationBuilder.CreateIndex(
                name: "IX_Cases_Courts_Court_Id",
                table: "Cases_Courts",
                column: "Court_Id");

            migrationBuilder.CreateIndex(
                name: "IX_Cases_Employees_Employee_Id",
                table: "Cases_Employees",
                column: "Employee_Id");

            migrationBuilder.CreateIndex(
                name: "IX_Cases_Files_Case_Id",
                table: "Cases_Files",
                column: "Case_Id");

            migrationBuilder.CreateIndex(
                name: "IX_Cases_Files_File_Id",
                table: "Cases_Files",
                column: "File_Id");

            migrationBuilder.CreateIndex(
                name: "IX_Cases_Sitings_Case_Code",
                table: "Cases_Sitings",
                column: "Case_Code");

            migrationBuilder.CreateIndex(
                name: "IX_Cases_Sitings_Siting_Id",
                table: "Cases_Sitings",
                column: "Siting_Id");

            migrationBuilder.CreateIndex(
                name: "IX_CaseStatusHistory_Case_Id",
                table: "CaseStatusHistory",
                column: "Case_Id");

            migrationBuilder.CreateIndex(
                name: "IX_Con_Lawyers_Custmors_Con_Lawyer_Id",
                table: "Con_Lawyers_Custmors",
                column: "Con_Lawyer_Id");

            migrationBuilder.CreateIndex(
                name: "IX_Consltitions_Custmors_Consl_Id",
                table: "Consltitions_Custmors",
                column: "Consl_Id");

            migrationBuilder.CreateIndex(
                name: "IX_Consltitions_Custmors_Customer_Id",
                table: "Consltitions_Custmors",
                column: "Customer_Id");

            migrationBuilder.CreateIndex(
                name: "IX_Consulations_Employee_Employee_Id",
                table: "Consulations_Employee",
                column: "Employee_Id");

            migrationBuilder.CreateIndex(
                name: "IX_Contenders_Custmors_Con_Id",
                table: "Contenders_Custmors",
                column: "Con_Id");

            migrationBuilder.CreateIndex(
                name: "IX_Contenders_Custmors_Con_Lawyer_ID",
                table: "Contenders_Custmors",
                column: "Con_Lawyer_ID");

            migrationBuilder.CreateIndex(
                name: "IX_Contenders_Lawyers_Contender_Id",
                table: "Contenders_Lawyers",
                column: "Contender_Id");

            migrationBuilder.CreateIndex(
                name: "IX_Courts_Gov_Id",
                table: "Courts",
                column: "Gov_Id");

            migrationBuilder.CreateIndex(
                name: "IX_Custmors_Cases_Case_Id",
                table: "Custmors_Cases",
                column: "Case_Id");

            migrationBuilder.CreateIndex(
                name: "IX_Custmors_Cases_Custmors_Id",
                table: "Custmors_Cases",
                column: "Custmors_Id");

            migrationBuilder.CreateIndex(
                name: "IX_Judicial_Documents_Customers_Id",
                table: "Judicial_Documents",
                column: "Customers_Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "__EFMigrationsHistory_Legacy");

            migrationBuilder.DropTable(
                name: "AdminstrativeTasks");

            migrationBuilder.DropTable(
                name: "App_Sitting");

            migrationBuilder.DropTable(
                name: "AspNetRoleClaims");

            migrationBuilder.DropTable(
                name: "AspNetUserClaims");

            migrationBuilder.DropTable(
                name: "AspNetUserLogins");

            migrationBuilder.DropTable(
                name: "AspNetUserRoles");

            migrationBuilder.DropTable(
                name: "AspNetUserTokens");

            migrationBuilder.DropTable(
                name: "Billing_Pay");

            migrationBuilder.DropTable(
                name: "Billing_Receipt");

            migrationBuilder.DropTable(
                name: "Cases_Contenders");

            migrationBuilder.DropTable(
                name: "Cases_Courts");

            migrationBuilder.DropTable(
                name: "Cases_Employees");

            migrationBuilder.DropTable(
                name: "Cases_Files");

            migrationBuilder.DropTable(
                name: "Cases_Sitings");

            migrationBuilder.DropTable(
                name: "CaseStatusHistory");

            migrationBuilder.DropTable(
                name: "Con_Lawyers_Custmors");

            migrationBuilder.DropTable(
                name: "Consltitions_Custmors");

            migrationBuilder.DropTable(
                name: "Consulations_Employee");

            migrationBuilder.DropTable(
                name: "Contenders_Custmors");

            migrationBuilder.DropTable(
                name: "Custmors_Cases");

            migrationBuilder.DropTable(
                name: "Judicial_Documents");

            migrationBuilder.DropTable(
                name: "App_Pages");

            migrationBuilder.DropTable(
                name: "AspNetRoles");

            migrationBuilder.DropTable(
                name: "AspNetUsers");

            migrationBuilder.DropTable(
                name: "Courts");

            migrationBuilder.DropTable(
                name: "Sitings");

            migrationBuilder.DropTable(
                name: "Consulations");

            migrationBuilder.DropTable(
                name: "Contenders_Lawyers");

            migrationBuilder.DropTable(
                name: "Governaments");

            migrationBuilder.DropTable(
                name: "Contenders");

            migrationBuilder.DropColumn(
                name: "Status",
                table: "Cases");
        }
    }
}
