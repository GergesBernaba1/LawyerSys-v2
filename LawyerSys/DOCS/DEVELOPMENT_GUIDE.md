# LawyerSys-v2 — Development Guide

This document is a concise reference for developers working on the LawyerSys migration (ASP.NET Core + React). It explains the project layout, conventions, development tasks, commands you will need, and recommended practices (DDD + migrations + Identity migration). Use this as the single place to get started quickly and to follow the team's guidelines.

---

## Table of contents
- Project layout (recommended DDD split)
- Getting the environment running (local dev)
- Database-first workflow & EF Core scaffolding
- Baseline migrations and separate migration histories
- Identity migration & password reset strategy
- DDD migration plan (how to refactor scaffolded models into domain)
- Development rules: code + commit + tests + CI
- React ClientApp notes (dev and production builds)
- Useful commands

---

## Project layout (recommended phased DDD layout)

We follow a pragmatic DDD layout while keeping the current database-first approach during discovery and early development.

Top-level structure (src/):
- LawyerSys.Api — Controllers, DTOs, API-only surface (thin controllers that call Application services)
- LawyerSys.Application — Application services (use-cases), DTOs, validation, mapping
- LawyerSys.Domain — Domain entities, value objects, aggregates, domain logic, domain events
- LawyerSys.Infrastructure — EF Core DbContext(s), migrations, repositories, external integrations (file storage, email)
- ClientApp — React app (Vite / Create React App)
- tests — Unit and integration tests

We currently run an incremental strategy: scaffold models from the legacy DB (Data/ScaffoldedModels), keep a temporary LegacyDbContext while a final plan for domain & repackaging is created, then gradually move to the DDD layout above.

---

## Getting the environment running (local dev)

Requirements:
- Windows with .NET SDK 8.x installed; dotnet-ef tool available locally (or install with dotnet tool install --global dotnet-ef)
- SQL Server Express instance available locally — in our dev environment we used `.\SQLEXPRESS`.

Quick start (from the project root `LawyerSys-v2/LawyerSys`):

1) Restore and build:
```cmd
dotnet restore
dotnet build
```

2) Make sure the DB exists and contains legacy schema (see `DB/LawyerSys Script.sql` or run the SQL script in SSMS on your instance). The migration scripts expect the DB name `Lawer` in local dev; change `appsettings.Development.json` connection string if needed.

3) Run the API locally:
```cmd
dotnet run
```

4) Start the React client (see ClientApp/README.md)

---

## Database-first workflow & EF Core scaffolding

We use Database-First to accelerate model discovery and then progressively migrate to an EF Core-based domain model.

Scaffold selected tables into a temporary `LegacyDbContext`:
```cmd
dotnet ef dbcontext scaffold "Server=.\SQLEXPRESS;Database=Lawer;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True" Microsoft.EntityFrameworkCore.SqlServer --output-dir Data/ScaffoldedModels --context LegacyDbContext --context-dir Data --use-database-names --force --table Users --table Customers --table Cases --table Employees --table Files
```

Notes:
- The scaffold command generates POCOs in `Data/ScaffoldedModels` and a `LegacyDbContext` in `Data`.
- After scaffolding, inspect and adjust datatypes (e.g., SSN and Phone should be strings in many cases).
- Choose to keep LegacyDbContext or merge the DbSet<T> into the main `ApplicationDbContext` (recommended for a single DbContext in the app).

---

## Baseline migrations and separate migration histories

We adopt migrations going forward. Because we started from an existing DB, we create a baseline (no-op) migration to record the starting state — this prevents EF from trying to recreate the whole schema.

Strategy used in this project:
- Create a dedicated migrations history for LegacyDbContext (migrations table: `__EFMigrationsHistory_Legacy`).
- Create an initial no-op migration for the legacy context and apply it so the DB records the baseline state.
- Use the main ApplicationDbContext for Identity and for future code-first changes that we manage.

Commands (example used):
```cmd
# Create a no-op baseline migration for the LegacyDbContext
dotnet ef migrations add InitialLegacyBaseline --context LegacyDbContext --output-dir Data/Migrations/Legacy
# edit the generated migration file: remove or replace schema creation code with an empty Up() and Down()
dotnet ef database update --context LegacyDbContext

# For Identity & future migrations use ApplicationDbContext
dotnet ef migrations add InitialIdentity --context ApplicationDbContext --output-dir Data/Migrations/Identity
dotnet ef database update --context ApplicationDbContext
```

This allows you to continue making incremental migrations safely, with separate history tables for any contexts that need them.

---

## Identity migration & password-reset strategy

We chose Option A: ASP.NET Identity and a pragmatic migration plan.

Key points:
- Identity (AspNetUsers, AspNetRoles, etc.) is created via migrations into the same DB used by the legacy data.
- Because legacy passwords are not compatible with Identity hashing, we copy user accounts from the legacy `Users` table into `AspNetUsers` but we do not copy passwords.
- Users created by the migration are marked with a flag `RequiresPasswordReset = true` (column added to AspNetUsers). The application will require users to reset their password on first login.

Migration approach summary:
1) Create Identity migrations and apply them.
2) Add a migration that adds `RequiresPasswordReset` column to AspNetUsers and seeds AspNetUsers from legacy `Users` (migration includes SQL that inserts AspNetUsers rows with placeholder email and sets RequiresPasswordReset true).
3) Implement change-password / reset endpoints (AccountController has request-password-reset and reset-password endpoints and enforces the RequiresPasswordReset flag on login).

Notes & safety:
- Always back up DB before running migrations.
- The migration should be reviewed and tested in a staging environment as it inserts user rows.

---

## DDD migration plan — moving scaffolded models into domain

We recommend an incremental approach:

Phase 1: Stabilize endpoints
- Scaffold the tables you need and add controllers that call application services. Keep the scaffolding models in `Data/ScaffoldedModels` and use `LegacyDbContext` for CRUD while you test.

Phase 2: Create Domain and Application layers
- Design aggregate roots for major concepts (Case aggregate, Customer aggregate, Billing aggregate).
- Create domain entities and value objects (in `LawyerSys.Domain`) that model business invariants.
- Create repository interfaces in Domain and EF repository implementations in Infrastructure that map to the scaffolded models.

Phase 3: Replace controllers with use-cases
- Controllers should call Application services (use-cases) that orchestrate domain operations and persist via repositories. This keeps controllers thin and domain logic in the domain layer.

Phase 4: Clean up persistence model
- Remove or adapt scaffolded EF types after domain models are in place and all tests pass. Keep migrations and repository implementations to maintain DB mapping.

---

## Development rules & best practices

- Always run the full test suite locally before pushing changes.
- Add migration files to source control and ensure they are reviewed before applying to shared environments.
- Keep controllers thin; place business rules in domain/application layers.
- Add unit tests for domain logic and integration tests for API endpoints and migrations.
- Avoid committing files under `.vs` or other workspace-private files (the repo currently contains some `.vs` changes — keep these excluded from PRs).

---

## React ClientApp notes

Development
```cmd
cd ClientApp
npm install
npm run dev
```

Production build
```cmd
npm run build
# Host files from ASP.NET via the built-in static files middleware or a CDN / static hosting.
```

Authentication
- The SPA should authenticate against `api/Account/login` and store the returned JWT in memory or secure storage (e.g., HttpOnly cookie via the backend in some flows). For testing, storing in localStorage is acceptable, but consider security for production.

---

## Useful commands summary

- Install ef tooling:
  - dotnet tool install --global dotnet-ef --version 8.*
- Scaffold DB-first models (example for tables):
  - dotnet ef dbcontext scaffold "<connection-string>" Microsoft.EntityFrameworkCore.SqlServer --output-dir Data/ScaffoldedModels --context LegacyDbContext --context-dir Data --use-database-names --force --table Users --table Customers --table Cases --table Employees --table Files
- Create migrations for a context:
  - dotnet ef migrations add MyMigrationName --context ApplicationDbContext --output-dir Data/Migrations/Identity
- Apply migrations:
  - dotnet ef database update --context ApplicationDbContext

---

## Next immediate tasks for devs

1) Review `Data/ScaffoldedModels/*` and decide which EF classes to keep and which to convert into domain models.
2) Finish Identity/Account work: implement a secure email workflow for password resets and ensure users are required to reset password on first login.
3) Start implementing domain-layer `Case` and `Customer` aggregates & unit tests.

---

If you want, I can now:
- A) Commit DEVELOPMENT_GUIDE.md and set up a DDD folder skeleton (Application + Domain + Infrastructure projects) as a template, or
- B) Continue by converting one scaffolded table (Cases) into a domain aggregate and add repository + tests.

Tell me which next step you prefer and I'll continue. ✅
