using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LawyerSys.Data.Migrations.Legacy
{
    /// <inheritdoc />
    public partial class AddPhase4MultiTenancyAuditAndStatus : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "FirmId",
                table: "Users",
                type: "int",
                nullable: false,
                defaultValue: 1);

            migrationBuilder.AddColumn<int>(
                name: "FirmId",
                table: "Sitings",
                type: "int",
                nullable: false,
                defaultValue: 1);

            migrationBuilder.AddColumn<int>(
                name: "FirmId",
                table: "Judicial_Documents",
                type: "int",
                nullable: false,
                defaultValue: 1);

            migrationBuilder.AddColumn<int>(
                name: "FirmId",
                table: "Governaments",
                type: "int",
                nullable: false,
                defaultValue: 1);

            migrationBuilder.AddColumn<int>(
                name: "FirmId",
                table: "Files",
                type: "int",
                nullable: false,
                defaultValue: 1);

            migrationBuilder.AddColumn<int>(
                name: "FirmId",
                table: "Employees",
                type: "int",
                nullable: false,
                defaultValue: 1);

            migrationBuilder.AddColumn<int>(
                name: "FirmId",
                table: "Customers",
                type: "int",
                nullable: false,
                defaultValue: 1);

            migrationBuilder.AddColumn<int>(
                name: "FirmId",
                table: "Custmors_Cases",
                type: "int",
                nullable: false,
                defaultValue: 1);

            migrationBuilder.AddColumn<int>(
                name: "FirmId",
                table: "Courts",
                type: "int",
                nullable: false,
                defaultValue: 1);

            migrationBuilder.AddColumn<int>(
                name: "FirmId",
                table: "Contenders_Lawyers",
                type: "int",
                nullable: false,
                defaultValue: 1);

            migrationBuilder.AddColumn<int>(
                name: "FirmId",
                table: "Contenders_Custmors",
                type: "int",
                nullable: false,
                defaultValue: 1);

            migrationBuilder.AddColumn<int>(
                name: "FirmId",
                table: "Contenders",
                type: "int",
                nullable: false,
                defaultValue: 1);

            migrationBuilder.AddColumn<int>(
                name: "FirmId",
                table: "Consulations_Employee",
                type: "int",
                nullable: false,
                defaultValue: 1);

            migrationBuilder.AddColumn<int>(
                name: "FirmId",
                table: "Consulations",
                type: "int",
                nullable: false,
                defaultValue: 1);

            migrationBuilder.AddColumn<int>(
                name: "FirmId",
                table: "Consltitions_Custmors",
                type: "int",
                nullable: false,
                defaultValue: 1);

            migrationBuilder.AddColumn<int>(
                name: "FirmId",
                table: "Con_Lawyers_Custmors",
                type: "int",
                nullable: false,
                defaultValue: 1);

            migrationBuilder.AddColumn<int>(
                name: "FirmId",
                table: "CaseStatusHistory",
                type: "int",
                nullable: false,
                defaultValue: 1);

            migrationBuilder.AddColumn<int>(
                name: "FirmId",
                table: "Cases_Sitings",
                type: "int",
                nullable: false,
                defaultValue: 1);

            migrationBuilder.AddColumn<int>(
                name: "FirmId",
                table: "Cases_Files",
                type: "int",
                nullable: false,
                defaultValue: 1);

            migrationBuilder.AddColumn<int>(
                name: "FirmId",
                table: "Cases_Employees",
                type: "int",
                nullable: false,
                defaultValue: 1);

            migrationBuilder.AddColumn<int>(
                name: "FirmId",
                table: "Cases_Courts",
                type: "int",
                nullable: false,
                defaultValue: 1);

            migrationBuilder.AddColumn<int>(
                name: "FirmId",
                table: "Cases_Contenders",
                type: "int",
                nullable: false,
                defaultValue: 1);

            migrationBuilder.AddColumn<int>(
                name: "FirmId",
                table: "Cases",
                type: "int",
                nullable: false,
                defaultValue: 1);

            migrationBuilder.AddColumn<int>(
                name: "FirmId",
                table: "Billing_Receipt",
                type: "int",
                nullable: false,
                defaultValue: 1);

            migrationBuilder.AddColumn<int>(
                name: "FirmId",
                table: "Billing_Pay",
                type: "int",
                nullable: false,
                defaultValue: 1);

            migrationBuilder.AddColumn<int>(
                name: "FirmId",
                table: "AdminstrativeTasks",
                type: "int",
                nullable: false,
                defaultValue: 1);

            migrationBuilder.CreateTable(
                name: "AuditLogs",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    EntityName = table.Column<string>(type: "nvarchar(128)", maxLength: 128, nullable: false),
                    Action = table.Column<string>(type: "nvarchar(16)", maxLength: 16, nullable: false),
                    EntityId = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: true),
                    OldValues = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    NewValues = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    UserId = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: true),
                    UserName = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: true),
                    Timestamp = table.Column<DateTime>(type: "datetime2", nullable: false),
                    RequestPath = table.Column<string>(type: "nvarchar(512)", maxLength: 512, nullable: true),
                    FirmId = table.Column<int>(type: "int", nullable: false, defaultValue: 1)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AuditLogs", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Users_FirmId",
                table: "Users",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Sitings_FirmId",
                table: "Sitings",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Judicial_Documents_FirmId",
                table: "Judicial_Documents",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Governaments_FirmId",
                table: "Governaments",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Files_FirmId",
                table: "Files",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Employees_FirmId",
                table: "Employees",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Customers_FirmId",
                table: "Customers",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Custmors_Cases_FirmId",
                table: "Custmors_Cases",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Courts_FirmId",
                table: "Courts",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Contenders_Lawyers_FirmId",
                table: "Contenders_Lawyers",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Contenders_Custmors_FirmId",
                table: "Contenders_Custmors",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Contenders_FirmId",
                table: "Contenders",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Consulations_Employee_FirmId",
                table: "Consulations_Employee",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Consulations_FirmId",
                table: "Consulations",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Consltitions_Custmors_FirmId",
                table: "Consltitions_Custmors",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Con_Lawyers_Custmors_FirmId",
                table: "Con_Lawyers_Custmors",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_CaseStatusHistory_FirmId",
                table: "CaseStatusHistory",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Cases_Sitings_FirmId",
                table: "Cases_Sitings",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Cases_Files_FirmId",
                table: "Cases_Files",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Cases_Employees_FirmId",
                table: "Cases_Employees",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Cases_Courts_FirmId",
                table: "Cases_Courts",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Cases_Contenders_FirmId",
                table: "Cases_Contenders",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Cases_FirmId",
                table: "Cases",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Billing_Receipt_FirmId",
                table: "Billing_Receipt",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_Billing_Pay_FirmId",
                table: "Billing_Pay",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_AdminstrativeTasks_FirmId",
                table: "AdminstrativeTasks",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_AuditLogs_FirmId",
                table: "AuditLogs",
                column: "FirmId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "AuditLogs");

            migrationBuilder.DropIndex(
                name: "IX_Users_FirmId",
                table: "Users");

            migrationBuilder.DropIndex(
                name: "IX_Sitings_FirmId",
                table: "Sitings");

            migrationBuilder.DropIndex(
                name: "IX_Judicial_Documents_FirmId",
                table: "Judicial_Documents");

            migrationBuilder.DropIndex(
                name: "IX_Governaments_FirmId",
                table: "Governaments");

            migrationBuilder.DropIndex(
                name: "IX_Files_FirmId",
                table: "Files");

            migrationBuilder.DropIndex(
                name: "IX_Employees_FirmId",
                table: "Employees");

            migrationBuilder.DropIndex(
                name: "IX_Customers_FirmId",
                table: "Customers");

            migrationBuilder.DropIndex(
                name: "IX_Custmors_Cases_FirmId",
                table: "Custmors_Cases");

            migrationBuilder.DropIndex(
                name: "IX_Courts_FirmId",
                table: "Courts");

            migrationBuilder.DropIndex(
                name: "IX_Contenders_Lawyers_FirmId",
                table: "Contenders_Lawyers");

            migrationBuilder.DropIndex(
                name: "IX_Contenders_Custmors_FirmId",
                table: "Contenders_Custmors");

            migrationBuilder.DropIndex(
                name: "IX_Contenders_FirmId",
                table: "Contenders");

            migrationBuilder.DropIndex(
                name: "IX_Consulations_Employee_FirmId",
                table: "Consulations_Employee");

            migrationBuilder.DropIndex(
                name: "IX_Consulations_FirmId",
                table: "Consulations");

            migrationBuilder.DropIndex(
                name: "IX_Consltitions_Custmors_FirmId",
                table: "Consltitions_Custmors");

            migrationBuilder.DropIndex(
                name: "IX_Con_Lawyers_Custmors_FirmId",
                table: "Con_Lawyers_Custmors");

            migrationBuilder.DropIndex(
                name: "IX_CaseStatusHistory_FirmId",
                table: "CaseStatusHistory");

            migrationBuilder.DropIndex(
                name: "IX_Cases_Sitings_FirmId",
                table: "Cases_Sitings");

            migrationBuilder.DropIndex(
                name: "IX_Cases_Files_FirmId",
                table: "Cases_Files");

            migrationBuilder.DropIndex(
                name: "IX_Cases_Employees_FirmId",
                table: "Cases_Employees");

            migrationBuilder.DropIndex(
                name: "IX_Cases_Courts_FirmId",
                table: "Cases_Courts");

            migrationBuilder.DropIndex(
                name: "IX_Cases_Contenders_FirmId",
                table: "Cases_Contenders");

            migrationBuilder.DropIndex(
                name: "IX_Cases_FirmId",
                table: "Cases");

            migrationBuilder.DropIndex(
                name: "IX_Billing_Receipt_FirmId",
                table: "Billing_Receipt");

            migrationBuilder.DropIndex(
                name: "IX_Billing_Pay_FirmId",
                table: "Billing_Pay");

            migrationBuilder.DropIndex(
                name: "IX_AdminstrativeTasks_FirmId",
                table: "AdminstrativeTasks");

            migrationBuilder.DropColumn(
                name: "FirmId",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "FirmId",
                table: "Sitings");

            migrationBuilder.DropColumn(
                name: "FirmId",
                table: "Judicial_Documents");

            migrationBuilder.DropColumn(
                name: "FirmId",
                table: "Governaments");

            migrationBuilder.DropColumn(
                name: "FirmId",
                table: "Files");

            migrationBuilder.DropColumn(
                name: "FirmId",
                table: "Employees");

            migrationBuilder.DropColumn(
                name: "FirmId",
                table: "Customers");

            migrationBuilder.DropColumn(
                name: "FirmId",
                table: "Custmors_Cases");

            migrationBuilder.DropColumn(
                name: "FirmId",
                table: "Courts");

            migrationBuilder.DropColumn(
                name: "FirmId",
                table: "Contenders_Lawyers");

            migrationBuilder.DropColumn(
                name: "FirmId",
                table: "Contenders_Custmors");

            migrationBuilder.DropColumn(
                name: "FirmId",
                table: "Contenders");

            migrationBuilder.DropColumn(
                name: "FirmId",
                table: "Consulations_Employee");

            migrationBuilder.DropColumn(
                name: "FirmId",
                table: "Consulations");

            migrationBuilder.DropColumn(
                name: "FirmId",
                table: "Consltitions_Custmors");

            migrationBuilder.DropColumn(
                name: "FirmId",
                table: "Con_Lawyers_Custmors");

            migrationBuilder.DropColumn(
                name: "FirmId",
                table: "CaseStatusHistory");

            migrationBuilder.DropColumn(
                name: "FirmId",
                table: "Cases_Sitings");

            migrationBuilder.DropColumn(
                name: "FirmId",
                table: "Cases_Files");

            migrationBuilder.DropColumn(
                name: "FirmId",
                table: "Cases_Employees");

            migrationBuilder.DropColumn(
                name: "FirmId",
                table: "Cases_Courts");

            migrationBuilder.DropColumn(
                name: "FirmId",
                table: "Cases_Contenders");

            migrationBuilder.DropColumn(
                name: "FirmId",
                table: "Cases");

            migrationBuilder.DropColumn(
                name: "FirmId",
                table: "Billing_Receipt");

            migrationBuilder.DropColumn(
                name: "FirmId",
                table: "Billing_Pay");

            migrationBuilder.DropColumn(
                name: "FirmId",
                table: "AdminstrativeTasks");
        }
    }
}
