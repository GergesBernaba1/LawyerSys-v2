# Secrets Setup

LawyerSys no longer stores runtime secrets in `appsettings*.json`.
Use **user-secrets** for local development and environment variables/secret store in deployment.

## Local Development (dotnet user-secrets)

From `LawyerSys/`:

```powershell
dotnet user-secrets init
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "Server=.\\SQLEXPRESS;Database=Lawer;Trusted_Connection=True;TrustServerCertificate=True"
dotnet user-secrets set "Jwt:Key" "your-very-long-random-jwt-signing-key-at-least-32-chars"
dotnet user-secrets set "Email:User" "smtp-user@example.com"
dotnet user-secrets set "Email:Password" "smtp-password"
dotnet user-secrets set "Email:From" "noreply@example.com"
```

Optional seed admin password:

```powershell
dotnet user-secrets set "AdminSeed:Password" "ChangeThisAdminPassword!"
```

## CI/CD / Production

Set equivalent environment variables or use your secret provider:

- `ConnectionStrings__DefaultConnection`
- `Jwt__Key`
- `Email__User`
- `Email__Password`
- `Email__From`
- `AdminSeed__Password` (optional)

For cloud deployments, prefer managed secret stores (Azure Key Vault, GitHub Actions encrypted secrets, etc.).
