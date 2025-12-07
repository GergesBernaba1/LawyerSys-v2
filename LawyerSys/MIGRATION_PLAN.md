# Migration plan — ASP.NET Core + React (Database-first)

Goal: create an equivalent application in ASP.NET Core 8 + React, Database-first EF Core, JWT-auth using ASP.NET Identity, hosted on Windows / IIS. Full parity — move all pages, logic and reports.

Phases & high-level tasks
1) Prepare skeleton (done)
   - Create solution skeleton at `LawyerSys-v2/LawyerSys` with API and ClientApp (React)
   - Add local DB script and schema summary, appsettings, placeholder Program.cs

2) Database-first scaffolding
   - Ensure database is present on SQL Server instance: Server=GERGES-YOUSSEF\\SQLEXPRESS (you confirmed).
   - Scaffold `ApplicationDbContext` and entity classes using dotnet-ef

   Example (run from the `LawyerSys` project folder):

   ```cmd
   dotnet tool install --global dotnet-ef --version 8.*

   dotnet ef dbcontext scaffold "Server=GERGES-YOUSSEF\\SQLEXPRESS;Database=LawyerSys;Trusted_Connection=True;MultipleActiveResultSets=true" Microsoft.EntityFrameworkCore.SqlServer --output-dir Data/Models --context ApplicationDbContext --context-dir Data --use-database-names --force
   ```

   - Review generated models for datatype adjustments (phone, SSN), rename or add navigation properties if needed.

3) Authentication and user migration decisions (Important)
   - ASP.NET Identity requires its own schema (AspNetUsers, AspNetRoles, etc.). We have 3 options:
     A) Create Identity schema and migrate/seed existing users (password migration is only possible if the existing passwords are compatible / you provide hashing keys). Otherwise users will need to reset passwords.
     B) Keep current Users table and implement a custom JWT token generation logic using that table (quicker, but not using Identity stacks).
     C) Hybrid: create Identity schema and write a migration utility to copy users into `AspNetUsers` while forcing password reset.

   - Please confirm which option you prefer (A, B or C). If you pick A or C, confirm whether existing password hashes are compatible (or if a reset is acceptable).

4) Implement Identity + JWT
   - Install Identity packages, configure Identity store using ApplicationDbContext (Data + Identity tables), configure password rules, JWT token issuer.
   - Create AccountController for registration/login, token issuance and refresh logic.

5) Implement core APIs & services
   - Scaffold controllers for main domains (Users, Customers, Cases, Employees, Files, Sitings, Courts, Contenders, Consulations, Billing, AdminTasks) using scaffolded EF models
   - Create DTOs and AutoMapper profiles
   - Implement file upload endpoints and storage strategy (filesystem for parity, or blob storage later)

6) Build React UI feature-by-feature
   - Use Option A approach (single project serving SPA) or use separate dev server in `ClientApp` during development.
   - Start with Authentication, then Cases, Customers, Employees, Reports, Payments, Files, Sitings.
   - Keep exact routing and views to match the existing app for parity (we'll map old .aspx pages -> new React routes/components)

7) Reporting and PDF/print
   - Determine how reports are generated in the original project (server-side or Crystal Reports?), reproduce with server-side API or a reporting library (RDLC / client-side) depending on requirements.

8) Tests, CI and deployment
   - Unit tests for services and controllers
   - Create GitHub Actions workflow for build/tests
   - Prepare IIS deployment guide (Windows) and optional Dockerizations

9) Data migration & validation
   - Create scripts to migrate any special data/lookup tables and verify FK integrity
   - If migrating users to Identity, implement migration/resets

10) Final verification & cutover
   - QA testing: user flows, reporting, security review
   - Switch production DB (or set up new DB) and cutover

Questions for you before we continue implementing code:
1) Which approach to user auth/identity do you prefer? (A Identity & preserve users, B custom JWT using current Users table, C Identity + migration with reset)
2) Do you want me to scaffold the entire DB now (all tables) or start with the most important tables (Users/Customers/Cases/Employees) and incrementally add other areas? Choose "all" or a 1st-phase list.

You chose: Option A — ASP.NET Identity + preserve users (we still need to decide whether a password reset is acceptable or if you can provide existing password hash algorithm info). If you do NOT have compatible password hashes we should force users to reset passwords on first login.

After you confirm the password migration approach and the DB is available on `GERGES-YOUSSEF\\SQLEXPRESS`, I'll:
- run the EF Core scaffold command locally in the project (or provide the command for you to run if you prefer to run it locally against your SQL Express instance),
- add Identity wiring and a basic token endpoint (if you pick Identity),
- scaffold initial controllers for the top-priority tables and add a small React auth flow in ClientApp.
