using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace LawyerSys.Infrastructure.Data.Migrations.Legacy
{
    /// <inheritdoc />
    public partial class AddDocumentGenerationTables : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "DocumentDrafts",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    TemplateType = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    CaseCode = table.Column<int>(type: "integer", nullable: true),
                    CustomerId = table.Column<int>(type: "integer", nullable: true),
                    Format = table.Column<string>(type: "character varying(10)", maxLength: 10, nullable: false),
                    Scope = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: true),
                    FeeTerms = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: true),
                    Subject = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    Statement = table.Column<string>(type: "character varying(4000)", maxLength: 4000, nullable: true),
                    AiInstructions = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: true),
                    PreviewContent = table.Column<string>(type: "text", nullable: true),
                    DocumentTitle = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: true),
                    DocumentReference = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    DocumentCategory = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    DocumentNotes = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    BrandingJson = table.Column<string>(type: "text", nullable: true),
                    PartiesJson = table.Column<string>(type: "text", nullable: true),
                    ClauseKeysJson = table.Column<string>(type: "text", nullable: true),
                    SaveToCase = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedBy = table.Column<string>(type: "character varying(256)", maxLength: 256, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp without time zone", nullable: false),
                    LastModifiedAt = table.Column<DateTime>(type: "timestamp without time zone", nullable: false),
                    DraftName = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: true),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false),
                    TenantId = table.Column<int>(type: "integer", nullable: true),
                    FirmId = table.Column<int>(type: "integer", nullable: false, defaultValue: 1)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DocumentDrafts", x => x.Id);
                    table.ForeignKey(
                        name: "FK_DocumentDrafts_Cases",
                        column: x => x.CaseCode,
                        principalTable: "Cases",
                        principalColumn: "Code",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_DocumentDrafts_Customers",
                        column: x => x.CustomerId,
                        principalTable: "Customers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "GeneratedDocuments",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    TemplateType = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    CaseCode = table.Column<int>(type: "integer", nullable: true),
                    CustomerId = table.Column<int>(type: "integer", nullable: true),
                    FileId = table.Column<int>(type: "integer", nullable: true),
                    Format = table.Column<string>(type: "character varying(10)", maxLength: 10, nullable: false),
                    DocumentTitle = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: true),
                    DocumentReference = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    DocumentCategory = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    DocumentNotes = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    BrandingJson = table.Column<string>(type: "text", nullable: true),
                    PartiesJson = table.Column<string>(type: "text", nullable: true),
                    ClauseKeysJson = table.Column<string>(type: "text", nullable: true),
                    GeneratedContent = table.Column<string>(type: "text", nullable: true),
                    GeneratedBy = table.Column<string>(type: "character varying(256)", maxLength: 256, nullable: false),
                    GeneratedAt = table.Column<DateTime>(type: "timestamp without time zone", nullable: false),
                    Version = table.Column<int>(type: "integer", nullable: false),
                    ParentDocumentId = table.Column<int>(type: "integer", nullable: true),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false),
                    TenantId = table.Column<int>(type: "integer", nullable: true),
                    FirmId = table.Column<int>(type: "integer", nullable: false, defaultValue: 1)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_GeneratedDocuments", x => x.Id);
                    table.ForeignKey(
                        name: "FK_GeneratedDocuments_Cases",
                        column: x => x.CaseCode,
                        principalTable: "Cases",
                        principalColumn: "Code",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_GeneratedDocuments_Customers",
                        column: x => x.CustomerId,
                        principalTable: "Customers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_GeneratedDocuments_Files",
                        column: x => x.FileId,
                        principalTable: "Files",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_GeneratedDocuments_ParentDocument",
                        column: x => x.ParentDocumentId,
                        principalTable: "GeneratedDocuments",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateIndex(
                name: "IX_DocumentDrafts_CaseCode",
                table: "DocumentDrafts",
                column: "CaseCode");

            migrationBuilder.CreateIndex(
                name: "IX_DocumentDrafts_CreatedAt",
                table: "DocumentDrafts",
                column: "CreatedAt");

            migrationBuilder.CreateIndex(
                name: "IX_DocumentDrafts_CreatedBy",
                table: "DocumentDrafts",
                column: "CreatedBy");

            migrationBuilder.CreateIndex(
                name: "IX_DocumentDrafts_CustomerId",
                table: "DocumentDrafts",
                column: "CustomerId");

            migrationBuilder.CreateIndex(
                name: "IX_DocumentDrafts_FirmId",
                table: "DocumentDrafts",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_GeneratedDocuments_CaseCode",
                table: "GeneratedDocuments",
                column: "CaseCode");

            migrationBuilder.CreateIndex(
                name: "IX_GeneratedDocuments_CustomerId",
                table: "GeneratedDocuments",
                column: "CustomerId");

            migrationBuilder.CreateIndex(
                name: "IX_GeneratedDocuments_FileId",
                table: "GeneratedDocuments",
                column: "FileId");

            migrationBuilder.CreateIndex(
                name: "IX_GeneratedDocuments_FirmId",
                table: "GeneratedDocuments",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_GeneratedDocuments_GeneratedAt",
                table: "GeneratedDocuments",
                column: "GeneratedAt");

            migrationBuilder.CreateIndex(
                name: "IX_GeneratedDocuments_GeneratedBy",
                table: "GeneratedDocuments",
                column: "GeneratedBy");

            migrationBuilder.CreateIndex(
                name: "IX_GeneratedDocuments_ParentDocumentId",
                table: "GeneratedDocuments",
                column: "ParentDocumentId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "DocumentDrafts");

            migrationBuilder.DropTable(
                name: "GeneratedDocuments");
        }
    }
}
