using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace LawyerSys.Infrastructure.Data.Migrations.Legacy
{
    /// <inheritdoc />
    public partial class AddCourtAutomationPersistence : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "CourtAutomationPacks",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Key = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    NameEn = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    NameAr = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    DescriptionEn = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: false),
                    DescriptionAr = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: false),
                    JurisdictionCode = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    FirmId = table.Column<int>(type: "integer", nullable: false, defaultValue: 1)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CourtAutomationPacks", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "CourtAutomationFilingSubmissions",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    SubmissionId = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    PackKey = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    FormKey = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    FilingChannel = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    CaseCode = table.Column<int>(type: "integer", nullable: true),
                    CourtId = table.Column<int>(type: "integer", nullable: true),
                    DueDate = table.Column<DateOnly>(type: "date", nullable: true),
                    Status = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false),
                    Message = table.Column<string>(type: "character varying(1024)", maxLength: 1024, nullable: false),
                    ExternalReference = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: false),
                    SubmittedAt = table.Column<DateTime>(type: "timestamp without time zone", nullable: false),
                    LastStatusAt = table.Column<DateTime>(type: "timestamp without time zone", nullable: true),
                    NextCheckAt = table.Column<DateTime>(type: "timestamp without time zone", nullable: true),
                    Notes = table.Column<string>(type: "character varying(2048)", maxLength: 2048, nullable: true),
                    FirmId = table.Column<int>(type: "integer", nullable: false, defaultValue: 1)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CourtAutomationFilingSubmissions", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "CourtAutomationDeadlineRules",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    PackId = table.Column<int>(type: "integer", nullable: false),
                    Key = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    NameEn = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    NameAr = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    DescriptionEn = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: false),
                    DescriptionAr = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: false),
                    OffsetDays = table.Column<int>(type: "integer", nullable: false),
                    Anchor = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    FirmId = table.Column<int>(type: "integer", nullable: false, defaultValue: 1)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CourtAutomationDeadlineRules", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CourtAutomationDeadlineRules_Packs",
                        column: x => x.PackId,
                        principalTable: "CourtAutomationPacks",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "CourtAutomationFilingChannels",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    PackId = table.Column<int>(type: "integer", nullable: false),
                    ChannelCode = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    DisplayNameEn = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    DisplayNameAr = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    FirmId = table.Column<int>(type: "integer", nullable: false, defaultValue: 1)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CourtAutomationFilingChannels", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CourtAutomationFilingChannels_Packs",
                        column: x => x.PackId,
                        principalTable: "CourtAutomationPacks",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "CourtAutomationFormTemplates",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    PackId = table.Column<int>(type: "integer", nullable: false),
                    Key = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    NameEn = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    NameAr = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    DescriptionEn = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: false),
                    DescriptionAr = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: false),
                    BodyEn = table.Column<string>(type: "character varying(8000)", maxLength: 8000, nullable: false),
                    BodyAr = table.Column<string>(type: "character varying(8000)", maxLength: 8000, nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    FirmId = table.Column<int>(type: "integer", nullable: false, defaultValue: 1)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CourtAutomationFormTemplates", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CourtAutomationFormTemplates_Packs",
                        column: x => x.PackId,
                        principalTable: "CourtAutomationPacks",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_CourtAutomationPacks_FirmId",
                table: "CourtAutomationPacks",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_CourtAutomationPacks_Key_FirmId",
                table: "CourtAutomationPacks",
                columns: new[] { "Key", "FirmId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_CourtAutomationFormTemplates_FirmId",
                table: "CourtAutomationFormTemplates",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_CourtAutomationFormTemplates_PackId_Key",
                table: "CourtAutomationFormTemplates",
                columns: new[] { "PackId", "Key" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_CourtAutomationDeadlineRules_FirmId",
                table: "CourtAutomationDeadlineRules",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_CourtAutomationDeadlineRules_PackId_Key",
                table: "CourtAutomationDeadlineRules",
                columns: new[] { "PackId", "Key" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_CourtAutomationFilingChannels_FirmId",
                table: "CourtAutomationFilingChannels",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_CourtAutomationFilingChannels_PackId_ChannelCode",
                table: "CourtAutomationFilingChannels",
                columns: new[] { "PackId", "ChannelCode" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_CourtAutomationFilingSubmissions_FirmId",
                table: "CourtAutomationFilingSubmissions",
                column: "FirmId");

            migrationBuilder.CreateIndex(
                name: "IX_CourtAutomationFilingSubmissions_PackKey_CaseCode",
                table: "CourtAutomationFilingSubmissions",
                columns: new[] { "PackKey", "CaseCode" });

            migrationBuilder.CreateIndex(
                name: "IX_CourtAutomationFilingSubmissions_SubmissionId",
                table: "CourtAutomationFilingSubmissions",
                column: "SubmissionId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_CourtAutomationFilingSubmissions_SubmittedAt",
                table: "CourtAutomationFilingSubmissions",
                column: "SubmittedAt");

            migrationBuilder.Sql("""
INSERT INTO "CourtAutomationPacks" ("Id","Key","NameEn","NameAr","DescriptionEn","DescriptionAr","JurisdictionCode","IsActive","FirmId")
VALUES
    (1001,'sa-commercial-first-instance','Saudi Commercial Court - First Instance','المحكمة التجارية السعودية - الدرجة الأولى','Commercial litigation filing pack with default timelines.','حزمة إجراءات القضايا التجارية مع جداول زمنية افتراضية.','SA-COMMERCIAL',TRUE,1),
    (1002,'sa-labor-disputes','Saudi Labor Disputes Pack','حزمة المنازعات العمالية السعودية','Labor claim filings and response timelines.','نماذج الدعاوى العمالية ومهل الرد.','SA-LABOR',TRUE,1),
    (1003,'sa-personal-status','Saudi Personal Status Pack','حزمة الأحوال الشخصية السعودية','Family/personal status filing templates and date automation.','نماذج قضايا الأحوال الشخصية مع أتمتة المواعيد.','SA-PERSONAL-STATUS',TRUE,1);
""");

            migrationBuilder.Sql("""
INSERT INTO "CourtAutomationFormTemplates" ("Id","PackId","Key","NameEn","NameAr","DescriptionEn","DescriptionAr","BodyEn","BodyAr","IsActive","FirmId")
VALUES
    (2001,1001,'statement-of-claim','Statement Of Claim','صحيفة الدعوى','Initial claim form for commercial disputes.','نموذج افتتاحي لرفع دعوى تجارية.',
     'STATEMENT OF CLAIM\n\nCourt: {{CourtName}}\nCase Code: {{CaseCode}}\nClient: {{CustomerName}}\nDate: {{Today}}\n\nSubject:\n{{Subject}}\n\nFacts:\n{{Facts}}\n\nRequests:\n{{Requests}}\n',
     'صحيفة دعوى\n\nالمحكمة: {{CourtName}}\nرقم القضية: {{CaseCode}}\nالعميل: {{CustomerName}}\nالتاريخ: {{Today}}\n\nالموضوع:\n{{Subject}}\n\nالوقائع:\n{{Facts}}\n\nالطلبات:\n{{Requests}}\n',
     TRUE,1),
    (2002,1001,'urgent-motion','Urgent Motion','طلب مستعجل','Urgent procedural motion template.','نموذج طلب إجرائي مستعجل.',
     'URGENT MOTION\n\nCourt: {{CourtName}}\nCase Code: {{CaseCode}}\nFiled On: {{Today}}\n\nGrounds:\n{{Grounds}}\n\nRequested Order:\n{{Requests}}\n',
     'طلب مستعجل\n\nالمحكمة: {{CourtName}}\nرقم القضية: {{CaseCode}}\nتاريخ التقديم: {{Today}}\n\nالأسباب:\n{{Grounds}}\n\nالطلب:\n{{Requests}}\n',
     TRUE,1),
    (2003,1001,'execution-request','Execution Request','طلب تنفيذ','Execution follow-up request template.','نموذج طلب متابعة التنفيذ.',
     'EXECUTION REQUEST\n\nCourt: {{CourtName}}\nCase Code: {{CaseCode}}\nDate: {{Today}}\n\nJudgment/Order Reference:\n{{Reference}}\n\nExecution Scope:\n{{Scope}}\n',
     'طلب تنفيذ\n\nالمحكمة: {{CourtName}}\nرقم القضية: {{CaseCode}}\nالتاريخ: {{Today}}\n\nمرجع الحكم/القرار:\n{{Reference}}\n\nنطاق التنفيذ:\n{{Scope}}\n',
     TRUE,1),
    (2101,1002,'labor-claim','Labor Claim Form','نموذج دعوى عمالية','Core filing for labor claim initiation.','النموذج الأساسي لبدء الدعوى العمالية.',
     'LABOR CLAIM\n\nCourt: {{CourtName}}\nCase Code: {{CaseCode}}\nEmployee/Claimant: {{CustomerName}}\nDate: {{Today}}\n\nClaim Summary:\n{{Subject}}\n\nClaim Details:\n{{Facts}}\n',
     'دعوى عمالية\n\nالجهة: {{CourtName}}\nرقم القضية: {{CaseCode}}\nالمدعي: {{CustomerName}}\nالتاريخ: {{Today}}\n\nملخص الدعوى:\n{{Subject}}\n\nتفاصيل الدعوى:\n{{Facts}}\n',
     TRUE,1),
    (2102,1002,'labor-appeal','Labor Appeal Memo','مذكرة استئناف عمالي','Appeal memo template for labor decisions.','نموذج مذكرة استئناف للقرارات العمالية.',
     'LABOR APPEAL MEMO\n\nCourt: {{CourtName}}\nCase Code: {{CaseCode}}\nDate: {{Today}}\n\nAppeal Grounds:\n{{Grounds}}\n\nRequested Relief:\n{{Requests}}\n',
     'مذكرة استئناف عمالي\n\nالجهة: {{CourtName}}\nرقم القضية: {{CaseCode}}\nالتاريخ: {{Today}}\n\nأسباب الاستئناف:\n{{Grounds}}\n\nالطلبات:\n{{Requests}}\n',
     TRUE,1),
    (2201,1003,'custody-petition','Custody Petition','صحيفة حضانة','Petition template for custody matters.','نموذج صحيفة دعوى حضانة.',
     'CUSTODY PETITION\n\nCourt: {{CourtName}}\nCase Code: {{CaseCode}}\nPetitioner: {{CustomerName}}\nDate: {{Today}}\n\nPetition Summary:\n{{Subject}}\n\nSupporting Facts:\n{{Facts}}\n',
     'صحيفة حضانة\n\nالمحكمة: {{CourtName}}\nرقم القضية: {{CaseCode}}\nمقدم الطلب: {{CustomerName}}\nالتاريخ: {{Today}}\n\nموضوع الطلب:\n{{Subject}}\n\nالوقائع المؤيدة:\n{{Facts}}\n',
     TRUE,1),
    (2202,1003,'maintenance-motion','Maintenance Motion','طلب نفقة','Maintenance/alimony request form.','نموذج طلب نفقة.',
     'MAINTENANCE MOTION\n\nCourt: {{CourtName}}\nCase Code: {{CaseCode}}\nDate: {{Today}}\n\nRequested Maintenance:\n{{Requests}}\n\nFinancial Context:\n{{Facts}}\n',
     'طلب نفقة\n\nالمحكمة: {{CourtName}}\nرقم القضية: {{CaseCode}}\nالتاريخ: {{Today}}\n\nالنفقة المطلوبة:\n{{Requests}}\n\nالوضع المالي:\n{{Facts}}\n',
     TRUE,1);
""");

            migrationBuilder.Sql("""
INSERT INTO "CourtAutomationDeadlineRules" ("Id","PackId","Key","NameEn","NameAr","DescriptionEn","DescriptionAr","OffsetDays","Anchor","IsActive","FirmId")
VALUES
    (3001,1001,'initial-filing','Initial Filing','قيد الدعوى','File initial claim package.','تقديم صحيفة الدعوى.',2,'TriggerDate',TRUE,1),
    (3002,1001,'service-of-process','Service Of Process','تبليغ الخصوم','Serve notice and filing copy.','تبليغ الخصوم بنسخة الدعوى.',5,'TriggerDate',TRUE,1),
    (3003,1001,'evidence-memo','Evidence Memo','مذكرة الأدلة','Prepare and submit evidence memo.','إعداد مذكرة الأدلة.',-3,'HearingDate',TRUE,1),
    (3004,1001,'hearing-prep','Hearing Prep Checklist','قائمة تحضير الجلسة','Finalize hearing folder and arguments.','استكمال ملف الجلسة والمرافعة.',-1,'HearingDate',TRUE,1),
    (3101,1002,'claim-filing','Claim Filing','تسجيل الدعوى','Submit labor claim form.','تقديم نموذج الدعوى العمالية.',3,'TriggerDate',TRUE,1),
    (3102,1002,'settlement-brief','Settlement Brief','مذكرة التسوية','Prepare settlement position brief.','إعداد مذكرة موقف التسوية.',7,'TriggerDate',TRUE,1),
    (3103,1002,'hearing-bundle','Hearing Bundle','ملف الجلسة','Compile exhibits and hearing bundle.','تجهيز مستندات الجلسة.',-2,'HearingDate',TRUE,1),
    (3201,1003,'petition-filing','Petition Filing','تقديم الصحيفة','File personal status petition.','تقديم صحيفة الدعوى.',2,'TriggerDate',TRUE,1),
    (3202,1003,'social-report','Social Report Request','طلب تقرير اجتماعي','Request social assessment/report.','طلب التقرير الاجتماعي.',5,'TriggerDate',TRUE,1),
    (3203,1003,'final-submissions','Final Submissions','المذكرات الختامية','Prepare final submissions before hearing.','إعداد المذكرات الختامية قبل الجلسة.',-2,'HearingDate',TRUE,1);
""");

            migrationBuilder.Sql("""
INSERT INTO "CourtAutomationFilingChannels" ("Id","PackId","ChannelCode","DisplayNameEn","DisplayNameAr","IsActive","FirmId")
VALUES
    (4001,1001,'Najez','Najez','ناجز',TRUE,1),
    (4002,1001,'CourtEPortal','Court E-Portal','بوابة المحكمة',TRUE,1),
    (4003,1001,'EmailGateway','Email Gateway','بوابة البريد الإلكتروني',TRUE,1),
    (4101,1002,'LaborPortal','Labor Portal','بوابة العمل',TRUE,1),
    (4102,1002,'Najez','Najez','ناجز',TRUE,1),
    (4103,1002,'EmailGateway','Email Gateway','بوابة البريد الإلكتروني',TRUE,1),
    (4201,1003,'Najez','Najez','ناجز',TRUE,1),
    (4202,1003,'FamilyCourtPortal','Family Court Portal','بوابة محكمة الأحوال',TRUE,1),
    (4203,1003,'EmailGateway','Email Gateway','بوابة البريد الإلكتروني',TRUE,1);
""");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "CourtAutomationDeadlineRules");

            migrationBuilder.DropTable(
                name: "CourtAutomationFilingChannels");

            migrationBuilder.DropTable(
                name: "CourtAutomationFilingSubmissions");

            migrationBuilder.DropTable(
                name: "CourtAutomationFormTemplates");

            migrationBuilder.DropTable(
                name: "CourtAutomationPacks");
        }
    }
}
