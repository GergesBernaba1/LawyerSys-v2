# First-phase scaffold & Identity wiring (step-by-step)

This file contains exact commands and guidance to scaffold the first-phase tables (Users, Customers, Cases, Employees, Files) from your existing SQL Server instance and to create Identity schema + migrations.

Important notes before running anything locally:
- These commands assume DB available at Server=GERGES-YOUSSEF\\SQLEXPRESS with Database=LawyerSys and that you have local access.
- The environment where these commands are executed must have .NET SDK 8.x and dotnet-ef tool installed.
- Running Identity migrations will add the AspNet* tables to your existing DB; make a backup before applying migrations to production.

1) Install EF CLI (one-time)

```cmd
dotnet tool install --global dotnet-ef --version 8.*
```

2) Scaffold the first-phase tables into a separate context so we avoid overwriting our Identity-enabled ApplicationDbContext.

Run this from the `LawyerSys` project folder:

```cmd
dotnet ef dbcontext scaffold "Server=GERGES-YOUSSEF\\SQLEXPRESS;Database=LawyerSys;Trusted_Connection=True;MultipleActiveResultSets=true" Microsoft.EntityFrameworkCore.SqlServer --output-dir Data/ScaffoldedModels --context LegacyDbContext --context-dir Data --use-database-names --force --table Users --table Customers --table Cases --table Employees --table Files
```

This creates `Data/LegacyDbContext.cs` and entity types under `Data/ScaffoldedModels`.

3) Inspect the generated models (adjust datatypes if needed)
- Review `Data/ScaffoldedModels/Users.cs` and other files. Consider changing SSN/Phone from int -> string.

4) Merge scaffold into `ApplicationDbContext` or keep separate contexts.
- Option A: Merge the DbSet<T> and Fluent API into `ApplicationDbContext` so both Identity and application tables live in one context. This gives simpler DB transactions and allows Identity to use the same DB.
- Option B: Keep a separate `LegacyDbContext` and use two contexts in the app. This is cleaner for automation but more complex at runtime for transactions.

If you want Option A (recommended): open `Data/LegacyDbContext.cs`, copy DbSet properties and OnModelCreating mapping into `Data/ApplicationDbContext.cs` then remove the `LegacyDbContext` file.

5) Add Identity migrations (if ApplicationDbContext already includes your merged tables)

```cmd
dotnet ef migrations add InitialIdentity --project . -s . -o Data/Migrations
dotnet ef database update
```

6) If you prefer to keep both contexts, instead create Identity migrations for ApplicationDbContext only (this creates AspNet* tables in DB). Then scaffold legacy models separately and use the LegacyDbContext for CRUD.

7) Users/password migration (Option A) — priorities and tradeoffs
- If the existing `Users.Password` values are plain-text or use a non-ASP.NET Identity hash, we cannot automatically preserve passwords in Identity. Typical approach:
  - Create Identity users without passwords and force password reset emails for users, or
  - If you can provide the hashing algorithm and salts used in the old system, write a custom IPasswordHasher that can validate old hashes then re-hash into Identity format on first successful login.

Recommendation: if you don't have password hash compatibility info, accept forced password resets and continue.

8) After scaffolding and migrations
- Create API controllers and services for the first-phase domain models (Users/Customers/Cases/Employees/Files) and test via Swagger and the React client.
