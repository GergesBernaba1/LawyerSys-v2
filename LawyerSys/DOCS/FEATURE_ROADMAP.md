# LawyerSys-v2 — Feature Roadmap

> Generated: February 16, 2026
> Status tracking: ✅ Done | 🔄 In Progress | ❌ Not Started

---

## System Overview

**LawyerSys-v2** is a lawyer office management system (Arabic-first, RTL) built with:
- **Backend:** ASP.NET Core 8, EF Core, SQL Server Express, JWT Auth, ASP.NET Identity
- **Frontend:** Next.js 14, React 18, MUI 7, TypeScript, i18next (AR/EN)
- **Database:** 34 tables — dual DbContext (ApplicationDbContext for Identity + LegacyDbContext for business data)
- **Entities:** Cases, Customers, Employees, Courts, Governorates, Contenders, Hearings (Sitings), Consultations, Judicial Documents, Admin Tasks, Billing (Payments/Receipts), Files, Legacy Users
- **Relationships:** Cases link to Customers, Contenders, Courts, Employees, Sitings, Files via 6 junction tables

---

## Key Gaps Identified

| Area | Issue |
|---|---|
| **Authorization** | `[Authorize]` exists but **no role checks** — any logged-in user can do everything |
| **Pagination** | All endpoints return full data (`ToListAsync()`) — will fail at scale |
| **Validation** | No `[Required]`/`[MaxLength]` on DTOs — invalid data passes through |
| **Customer CRUD** | No PUT/DELETE endpoints on CustomersController |
| **Dashboard stats** | "+12% this month" is hardcoded, not computed |
| **Unused relations** | Consultation↔Customer, Consultation↔Employee, Contender↔Lawyer — tables exist but no API |
| **Dead code** | `src/client/` legacy SPA components, `#if false` blocks in controllers |
| **Security** | JWT key + SMTP password in appsettings.json, legacy plaintext passwords, reset token in response |
| **Testing** | Playwright configured but 0 tests written |

---

## Phase 1 — Critical Fixes & Core Improvements

| # | Feature | Impact | Effort | Status |
|---|---|---|---|---|
| 1 | **Role-based access control** — Admin sees everything, Employee sees assigned cases only, Customer sees own cases/billing only | High | Medium | ✅ |
| 2 | **Server-side pagination + search** — Add `?page=1&pageSize=20&search=` to all list endpoints (Cases page implemented) | High | Medium | 🔄 |
| 3 | **Customer update/delete** — Expose PUT/DELETE on CustomersController (service already exists) | High | Low | ❌ |
| 4 | **DTO validation** — Add `[Required]`, `[MaxLength]`, `[Range]` annotations to all DTOs | Medium | Low | ❌ |
| 5 | **Clean up dead code** — Remove `src/client/`, `#if false` blocks, legacy `App.tsx` | Low | Low | ❌ |

---

## Phase 2 — Missing Business Features

| # | Feature | Description | Status |
|---|---|---|---|
| 6 | **Case Status Tracking** | Add a `Status` field to cases (New → In Progress → Awaiting Hearing → Closed → Won → Lost) with status history log | ❌ |
| 7 | **Consultation ↔ Customer/Employee linking** | Wire the existing junction tables (`Consltitions_Custmor`, `Consulations_Employee`) with API endpoints + UI, so consultations can be assigned to specific clients and lawyers | ❌ |
| 8 | **Hearing Notifications/Reminders** | `Siting.Siting_Notification` exists but is unused — add a background job (Hangfire/Quartz) to send email/push reminders before hearing dates | ❌ |
| 9 | **Task Reminders** | Similar to hearings — `AdminstrativeTask.Task_Reminder_Date` should trigger email notifications | ❌ |
| 10 | **File Attachments on Cases** | Currently files are linked to cases via junction table, but the upload flow is separate. Add drag-and-drop file upload directly from the case detail page | ❌ |

---

## Phase 3 — Analytics & Reporting

| # | Feature | Description | Status |
|---|---|---|---|
| 11 | **Real Dashboard Analytics** | Replace hardcoded "+12%" with actual computed trends — cases opened this month vs last, revenue from billing, upcoming hearings count, overdue tasks | ❌ |
| 12 | **Financial Reports** | Generate PDF/Excel reports: monthly billing summary (payments vs receipts), per-customer billing history, outstanding balances | ❌ |
| 13 | **Case Timeline** | Visual timeline view per case showing: creation → hearings → documents → status changes → billing events | ❌ |
| 14 | **Calendar View** | Full calendar (FullCalendar or MUI Date Calendar) showing hearings, task deadlines, and reminders in a monthly/weekly view | ❌ |

---

## Phase 4 — Advanced Features

| # | Feature | Description | Status |
|---|---|---|---|
| 15 | **Document Generation** | Auto-generate legal documents (power of attorney, contracts, court filings) from templates with client/case data merged in (using a DOCX template engine) | ❌ |
| 16 | **Client Portal** | Separate customer-facing view where clients can: check case status, view hearings, download documents, see billing — using the `Customer` role | ❌ |
| 17 | **Audit Log** | Track who changed what and when — create an `AuditLog` table recording all create/update/delete operations with user ID, timestamp, entity, old/new values | ❌ |
| 18 | **Multi-tenancy** | Support multiple law firms on one instance — add a `FirmId` column to scope all data per firm | ❌ |
| 19 | **WhatsApp/SMS Integration** | Send hearing reminders and case updates via WhatsApp Business API or SMS (common in MENA region law offices) | ❌ |
| 20 | **Mobile App (PWA)** | Convert to a Progressive Web App with offline capability — lawyers need quick access in courtrooms where connectivity is poor | ❌ |

---

## Phase 5 — Quality & DevOps

| # | Feature | Description | Status |
|---|---|---|---|
| 21 | **E2E Tests** | Write Playwright tests for login flow, case creation, billing, and all CRUD pages (config already exists) | ❌ |
| 22 | **API Rate Limiting** | Add `AspNetCoreRateLimit` to prevent abuse on public endpoints | ❌ |
| 23 | **Structured Logging** | Replace `Console.WriteLine` with Serilog + sink to file/Seq/Application Insights | ❌ |
| 24 | **CI/CD Pipeline** | GitHub Actions workflow: build → test → deploy (backend to Azure App Service, frontend to Vercel/Azure Static Web Apps) | ❌ |
| 25 | **Secrets Management** | Move JWT key, SMTP credentials, connection strings to Azure Key Vault or `dotnet user-secrets` | ❌ |

---

## Recommended Implementation Order

```
Phase 1:  1 → 2 → 3 → 4 → 5
Phase 2:  6 → 7 → 8 → 9 → 10
Phase 3: 11 → 14 → 13 → 12
Phase 4: 17 → 15 → 16 → 19 → 20 → 18
Phase 5: 25 → 23 → 21 → 22 → 24
```

**Highest priority path:** 1 (RBAC) → 2 (Pagination) → 3 (Customer CRUD) → 6 (Case Status) → 11 (Dashboard Analytics) → 14 (Calendar) → 7 (Consultation Linking) → 8 (Reminders) → 15 (Doc Generation) → 16 (Client Portal)
