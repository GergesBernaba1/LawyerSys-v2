using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace LawyerSys.Infrastructure.Data.Migrations.Legacy
{
    /// <inheritdoc />
    public partial class InitialLegacyPostgresClean : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "__EFMigrationsHistory_Legacy",
                columns: table => new
                {
                    MigrationId = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: false),
                    ProductVersion = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK___EFMigrationsHistory_Legacy", x => x.MigrationId);
                });

            migrationBuilder.CreateTable(
                name: "App_Pages",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Page_Name = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_App_Pages", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "AuditLogs",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    EntityName = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: false),
                    Action = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: false),
                    EntityId = table.Column<string>(type: "character varying(256)", maxLength: 256, nullable: true),
                    OldValues = table.Column<string>(type: "text", nullable: true),
                    NewValues = table.Column<string>(type: "text", nullable: true),
                    UserId = table.Column<string>(type: "character varying(256)", maxLength: 256, nullable: true),
                    UserName = table.Column<string>(type: "character varying(256)", maxLength: 256, nullable: true),
                    Timestamp = table.Column<DateTime>(type: "timestamp without time zone", nullable: false),
                    RequestPath = table.Column<string>(type: "character varying(512)", maxLength: 512, nullable: true),
                    FirmId = table.Column<int>(type: "integer", nullable: false, defaultValue: 1)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AuditLogs", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Cases",
                columns: table => new
                {
                    Code = table.Column<int>(type: "integer", nullable: false),
                    Id = table.Column<int>(type: "integer", nullable: false),
                    Invitions_Statment = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Invition_Type = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Invition_Date = table.Column<DateOnly>(type: "date", nullable: false),
                    Total_Amount = table.Column<int>(type: "integer", nullable: false),
                    Notes = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Status = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    FirmId = table.Column<int>(type: "integer", nullable: false, defaultValue: 1)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Cases_1", x => x.Code);
                });

            migrationBuilder.CreateTable(
                name: "Consulations",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Consultion_State = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Type = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Subject = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Descraption = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Feedback = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Notes = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Date_time = table.Column<DateTime>(type: "timestamp without time zone", nullable: false),
                    FirmId = table.Column<int>(type: "integer", nullable: false, defaultValue: 1)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Consulations", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Contenders",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Full_Name = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    SSN = table.Column<int>(type: "integer", nullable: false),
                    BirthDate = table.Column<DateOnly>(type: "date", nullable: false),
                    Type = table.Column<bool>(type: "boolean", nullable: true),
                    FirmId = table.Column<int>(type: "integer", nullable: false, defaultValue: 1)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Contenders", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Files",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Path = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    Code = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    type = table.Column<bool>(type: "boolean", nullable: true),
                    FirmId = table.Column<int>(type: "integer", nullable: false, defaultValue: 1)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Files", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Governaments",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false),
                    Gov_Name = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    FirmId = table.Column<int>(type: "integer", nullable: false, defaultValue: 1)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Governaments", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Sitings",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Siting_Time = table.Column<DateTime>(type: "timestamp without time zone", nullable: false),
                    Siting_Date = table.Column<DateOnly>(type: "date", nullable: false),
                    Siting_Notification = table.Column<DateTime>(type: "timestamp without time zone", nullable: false),
                    Judge_Name = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Notes = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    FirmId = table.Column<int>(type: "integer", nullable: false, defaultValue: 1)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Sitings", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Users",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false),
                    Full_Name = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Address = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    Job = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Phon_Number = table.Column<int>(type: "integer", nullable: false),
                    Date_Of_Birth = table.Column<DateOnly>(type: "date", nullable: false),
                    SSN = table.Column<int>(type: "integer", nullable: false),
                    User_Name = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Password = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    FirmId = table.Column<int>(type: "integer", nullable: false, defaultValue: 1)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Users", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "CaseStatusHistory",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Case_Id = table.Column<int>(type: "integer", nullable: false),
                    OldStatus = table.Column<int>(type: "integer", nullable: false),
                    NewStatus = table.Column<int>(type: "integer", nullable: false),
                    ChangedBy = table.Column<string>(type: "text", nullable: true),
                    ChangedAt = table.Column<DateTime>(type: "timestamp without time zone", nullable: false),
                    FirmId = table.Column<int>(type: "integer", nullable: false, defaultValue: 1)
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
                name: "Cases_Contenders",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Case_Id = table.Column<int>(type: "integer", nullable: false),
                    Contender_Id = table.Column<int>(type: "integer", nullable: false),
                    FirmId = table.Column<int>(type: "integer", nullable: false, defaultValue: 1)
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
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Contender_Id = table.Column<int>(type: "integer", nullable: false),
                    FirmId = table.Column<int>(type: "integer", nullable: false, defaultValue: 1)
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
                name: "Cases_Files",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Case_Id = table.Column<int>(type: "integer", nullable: false),
                    File_Id = table.Column<int>(type: "integer", nullable: false),
                    FirmId = table.Column<int>(type: "integer", nullable: false, defaultValue: 1)
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
                name: "Courts",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Name = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Address = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Telephone = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Notes = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Gov_Id = table.Column<int>(type: "integer", nullable: false),
                    FirmId = table.Column<int>(type: "integer", nullable: false, defaultValue: 1)
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
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Case_Code = table.Column<int>(type: "integer", nullable: false),
                    Siting_Id = table.Column<int>(type: "integer", nullable: false),
                    FirmId = table.Column<int>(type: "integer", nullable: false, defaultValue: 1)
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
                name: "App_Sitting",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    User_Id = table.Column<int>(type: "integer", nullable: false),
                    App_PageID = table.Column<int>(type: "integer", nullable: false),
                    IsVaild = table.Column<bool>(type: "boolean", nullable: true)
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
                name: "Customers",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Users_Id = table.Column<int>(type: "integer", nullable: false),
                    FirmId = table.Column<int>(type: "integer", nullable: false, defaultValue: 1)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Customers", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Customers_Customers",
                        column: x => x.Users_Id,
                        principalTable: "Users",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "Employees",
                columns: table => new
                {
                    id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Salary = table.Column<int>(type: "integer", nullable: false),
                    Users_Id = table.Column<int>(type: "integer", nullable: false),
                    FirmId = table.Column<int>(type: "integer", nullable: false, defaultValue: 1)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Employees", x => x.id);
                    table.ForeignKey(
                        name: "FK_Employees_Users",
                        column: x => x.Users_Id,
                        principalTable: "Users",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "Con_Lawyers_Custmors",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Con_Custmor_Id = table.Column<int>(type: "integer", nullable: false),
                    Con_Lawyer_Id = table.Column<int>(type: "integer", nullable: false),
                    FirmId = table.Column<int>(type: "integer", nullable: false, defaultValue: 1)
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
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Con_Lawyer_ID = table.Column<int>(type: "integer", nullable: true),
                    Con_Id = table.Column<int>(type: "integer", nullable: true),
                    FirmId = table.Column<int>(type: "integer", nullable: false, defaultValue: 1)
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
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Court_Id = table.Column<int>(type: "integer", nullable: false),
                    Case_Code = table.Column<int>(type: "integer", nullable: false),
                    FirmId = table.Column<int>(type: "integer", nullable: false, defaultValue: 1)
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

            migrationBuilder.CreateTable(
                name: "Billing_Pay",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Amount = table.Column<double>(type: "double precision", nullable: false),
                    Date_Of_Opreation = table.Column<DateOnly>(type: "date", nullable: false),
                    Notes = table.Column<string>(type: "text", nullable: false),
                    Custmor_Id = table.Column<int>(type: "integer", nullable: false),
                    FirmId = table.Column<int>(type: "integer", nullable: false, defaultValue: 1)
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
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Amount = table.Column<double>(type: "double precision", nullable: false),
                    Date_Of_Opreation = table.Column<DateOnly>(type: "date", nullable: false),
                    Notes = table.Column<string>(type: "text", nullable: false),
                    Employee_Id = table.Column<int>(type: "integer", nullable: false),
                    FirmId = table.Column<int>(type: "integer", nullable: false, defaultValue: 1)
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
                name: "Consltitions_Custmors",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Customer_Id = table.Column<int>(type: "integer", nullable: false),
                    Consl_Id = table.Column<int>(type: "integer", nullable: false),
                    FirmId = table.Column<int>(type: "integer", nullable: false, defaultValue: 1)
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
                name: "Custmors_Cases",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Case_Id = table.Column<int>(type: "integer", nullable: false),
                    Custmors_Id = table.Column<int>(type: "integer", nullable: false),
                    FirmId = table.Column<int>(type: "integer", nullable: false, defaultValue: 1)
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
                name: "Judicial_Documents",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Doc_Type = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Doc_Num = table.Column<int>(type: "integer", nullable: false),
                    Doc_Details = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Notes = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Num_Of_Agent = table.Column<int>(type: "integer", nullable: false),
                    Customers_Id = table.Column<int>(type: "integer", nullable: false),
                    FirmId = table.Column<int>(type: "integer", nullable: false, defaultValue: 1)
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
                name: "AdminstrativeTasks",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Task_Name = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Type = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Task_Date = table.Column<DateOnly>(type: "date", nullable: false),
                    Task_Reminder_Date = table.Column<DateTime>(type: "timestamp without time zone", nullable: false),
                    Notes = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    employee_Id = table.Column<int>(type: "integer", nullable: true),
                    FirmId = table.Column<int>(type: "integer", nullable: false, defaultValue: 1)
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
                name: "Cases_Employees",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Case_Code = table.Column<int>(type: "integer", nullable: false),
                    Employee_Id = table.Column<int>(type: "integer", nullable: false),
                    FirmId = table.Column<int>(type: "integer", nullable: false, defaultValue: 1)
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
                name: "Consulations_Employee",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Consl_ID = table.Column<int>(type: "integer", nullable: false),
                    Employee_Id = table.Column<int>(type: "integer", nullable: false),
                    FirmId = table.Column<int>(type: "integer", nullable: false, defaultValue: 1)
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

            migrationBuilder.CreateIndex(
                name: "IX_AdminstrativeTasks_employee_Id",
                table: "AdminstrativeTasks",
                column: "employee_Id");

            migrationBuilder.CreateIndex(
                name: "IX_AdminstrativeTasks_FirmId",
                table: "AdminstrativeTasks",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_App_Sitting_App_PageID",
                table: "App_Sitting",
                column: "App_PageID");

            migrationBuilder.CreateIndex(
                name: "IX_App_Sitting_User_Id",
                table: "App_Sitting",
                column: "User_Id");

            migrationBuilder.CreateIndex(
                name: "IX_AuditLogs_FirmId",
                table: "AuditLogs",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Billing_Pay_Custmor_Id",
                table: "Billing_Pay",
                column: "Custmor_Id");

            migrationBuilder.CreateIndex(
                name: "IX_Billing_Pay_FirmId",
                table: "Billing_Pay",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Billing_Receipt_Employee_Id",
                table: "Billing_Receipt",
                column: "Employee_Id");

            migrationBuilder.CreateIndex(
                name: "IX_Billing_Receipt_FirmId",
                table: "Billing_Receipt",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Cases_FirmId",
                table: "Cases",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Cases_Contenders_Case_Id",
                table: "Cases_Contenders",
                column: "Case_Id");

            migrationBuilder.CreateIndex(
                name: "IX_Cases_Contenders_Contender_Id",
                table: "Cases_Contenders",
                column: "Contender_Id");

            migrationBuilder.CreateIndex(
                name: "IX_Cases_Contenders_FirmId",
                table: "Cases_Contenders",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Cases_Courts_Case_Code",
                table: "Cases_Courts",
                column: "Case_Code");

            migrationBuilder.CreateIndex(
                name: "IX_Cases_Courts_Court_Id",
                table: "Cases_Courts",
                column: "Court_Id");

            migrationBuilder.CreateIndex(
                name: "IX_Cases_Courts_FirmId",
                table: "Cases_Courts",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Cases_Employees_Employee_Id",
                table: "Cases_Employees",
                column: "Employee_Id");

            migrationBuilder.CreateIndex(
                name: "IX_Cases_Employees_FirmId",
                table: "Cases_Employees",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Cases_Files_Case_Id",
                table: "Cases_Files",
                column: "Case_Id");

            migrationBuilder.CreateIndex(
                name: "IX_Cases_Files_File_Id",
                table: "Cases_Files",
                column: "File_Id");

            migrationBuilder.CreateIndex(
                name: "IX_Cases_Files_FirmId",
                table: "Cases_Files",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Cases_Sitings_Case_Code",
                table: "Cases_Sitings",
                column: "Case_Code");

            migrationBuilder.CreateIndex(
                name: "IX_Cases_Sitings_FirmId",
                table: "Cases_Sitings",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Cases_Sitings_Siting_Id",
                table: "Cases_Sitings",
                column: "Siting_Id");

            migrationBuilder.CreateIndex(
                name: "IX_CaseStatusHistory_Case_Id",
                table: "CaseStatusHistory",
                column: "Case_Id");

            migrationBuilder.CreateIndex(
                name: "IX_CaseStatusHistory_FirmId",
                table: "CaseStatusHistory",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Con_Lawyers_Custmors_Con_Lawyer_Id",
                table: "Con_Lawyers_Custmors",
                column: "Con_Lawyer_Id");

            migrationBuilder.CreateIndex(
                name: "IX_Con_Lawyers_Custmors_FirmId",
                table: "Con_Lawyers_Custmors",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Consltitions_Custmors_Consl_Id",
                table: "Consltitions_Custmors",
                column: "Consl_Id");

            migrationBuilder.CreateIndex(
                name: "IX_Consltitions_Custmors_Customer_Id",
                table: "Consltitions_Custmors",
                column: "Customer_Id");

            migrationBuilder.CreateIndex(
                name: "IX_Consltitions_Custmors_FirmId",
                table: "Consltitions_Custmors",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Consulations_FirmId",
                table: "Consulations",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Consulations_Employee_Employee_Id",
                table: "Consulations_Employee",
                column: "Employee_Id");

            migrationBuilder.CreateIndex(
                name: "IX_Consulations_Employee_FirmId",
                table: "Consulations_Employee",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Contenders_FirmId",
                table: "Contenders",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Contenders_Custmors_Con_Id",
                table: "Contenders_Custmors",
                column: "Con_Id");

            migrationBuilder.CreateIndex(
                name: "IX_Contenders_Custmors_Con_Lawyer_ID",
                table: "Contenders_Custmors",
                column: "Con_Lawyer_ID");

            migrationBuilder.CreateIndex(
                name: "IX_Contenders_Custmors_FirmId",
                table: "Contenders_Custmors",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Contenders_Lawyers_Contender_Id",
                table: "Contenders_Lawyers",
                column: "Contender_Id");

            migrationBuilder.CreateIndex(
                name: "IX_Contenders_Lawyers_FirmId",
                table: "Contenders_Lawyers",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Courts_FirmId",
                table: "Courts",
                column: "FirmId");

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
                name: "IX_Custmors_Cases_FirmId",
                table: "Custmors_Cases",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Customers_FirmId",
                table: "Customers",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Customers_Users_Id",
                table: "Customers",
                column: "Users_Id");

            migrationBuilder.CreateIndex(
                name: "IX_Employees_FirmId",
                table: "Employees",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Employees_Users_Id",
                table: "Employees",
                column: "Users_Id");

            migrationBuilder.CreateIndex(
                name: "IX_Files_FirmId",
                table: "Files",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Governaments_FirmId",
                table: "Governaments",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Judicial_Documents_Customers_Id",
                table: "Judicial_Documents",
                column: "Customers_Id");

            migrationBuilder.CreateIndex(
                name: "IX_Judicial_Documents_FirmId",
                table: "Judicial_Documents",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Sitings_FirmId",
                table: "Sitings",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Users_FirmId",
                table: "Users",
                column: "FirmId");
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
                name: "AuditLogs");

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
                name: "Courts");

            migrationBuilder.DropTable(
                name: "Files");

            migrationBuilder.DropTable(
                name: "Sitings");

            migrationBuilder.DropTable(
                name: "Consulations");

            migrationBuilder.DropTable(
                name: "Employees");

            migrationBuilder.DropTable(
                name: "Contenders_Lawyers");

            migrationBuilder.DropTable(
                name: "Cases");

            migrationBuilder.DropTable(
                name: "Customers");

            migrationBuilder.DropTable(
                name: "Governaments");

            migrationBuilder.DropTable(
                name: "Contenders");

            migrationBuilder.DropTable(
                name: "Users");
        }
    }
}
