# LawyerSys-v2

This folder is the start of the migration to ASP.NET Core + React (Database-first EF Core + JWT auth).

Quick overview:
- Backend: ASP.NET Core (net8.0) Web API hosting a React SPA
- Frontend: React (ClientApp)
- Database: SQL Server (Database-first EF Core) — your old DB script / instance will be used to scaffold models
- Auth: JWT + ASP.NET Identity (instructions included)

Important: this repository skeleton is intentionally minimal. It includes configuration and instructions you can run locally to finish the database-first scaffold (you asked to use SQL Server instance: `GERGES-YOUSSEF\\SQLEXPRESS`).

Getting started:

1) Ensure .NET SDK 8.0 (recommended LTS) or later is installed.

2) From the repo root, restore and build:

```sh
cd LawyerSys
dotnet restore
dotnet build
```

3) Create or restore the database using the included SQL script (if you haven't already). In SQL Server Management Studio, run `DB/LawyerSys Script.sql` against your SQL Server instance.

4) Scaffold EF Core models (Database-first):

Make sure dotnet-ef tool is installed:

```sh
dotnet tool install --global dotnet-ef
```

Scaffold the DB context and entities (run from the `LawyerSys` project directory). Replace `<SERVER>` with your SQL Server instance name:

```sh
dotnet ef dbcontext scaffold "Server=<SERVER>;Database=LawyerSys;Trusted_Connection=True;MultipleActiveResultSets=true" Microsoft.EntityFrameworkCore.SqlServer --output-dir Data/Models --context ApplicationDbContext --context-dir Data --force
```

This will generate the EF Core models into `Data/Models` and an `ApplicationDbContext` in `Data`.

5) Adjust `appsettings.Development.json` connection string and JWT settings then run the app:

```sh
dotnet run
```

6) Open `ClientApp` and run the React dev server (instructions will appear in `ClientApp/README.md`).

If you prefer separate backend + frontend projects or want additional setup steps (IIS hosting, Docker, CI), tell me and I will add them.
