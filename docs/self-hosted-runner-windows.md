# GitHub Self-Hosted Runner Setup (Windows IIS Server)

This guide is for setting up a GitHub Actions self-hosted runner on Windows for this repo.

- Repo: `https://github.com/GergesBernaba1/LawyerSys-v2`
- Workflow uses: `runs-on: [self-hosted, windows]`

If the runner is offline/not configured, deployment workflow will not run.

## 1. Prerequisites

- Windows Server with internet access to GitHub.
- Administrator access on server.
- Required tools installed:
  - `.NET SDK 8`
  - `Node.js 20 + npm`
  - IIS + WebAdministration module
- Open GitHub repo settings:
  - `Settings -> Actions -> Runners -> New self-hosted runner`

## 2. Create Runner Folder

### CMD
```bat
mkdir C:\actions-runner
cd C:\actions-runner
```

### PowerShell
```powershell
New-Item -ItemType Directory -Path C:\actions-runner -Force
Set-Location C:\actions-runner
```

## 3. Download Runner Package

Use the download URL/version shown by GitHub in `New self-hosted runner`.

### CMD (curl)
```bat
curl -L -o actions-runner-win-x64-2.333.1.zip https://github.com/actions/runner/releases/download/v2.333.1/actions-runner-win-x64-2.333.1.zip
```

### PowerShell
```powershell
Invoke-WebRequest -Uri "https://github.com/actions/runner/releases/download/v2.333.1/actions-runner-win-x64-2.333.1.zip" -OutFile "actions-runner-win-x64-2.333.1.zip"
```

## 4. Verify Checksum (Recommended)

Compare with checksum value from GitHub release page.

### CMD
```bat
certutil -hashfile actions-runner-win-x64-2.333.1.zip SHA256
```

### PowerShell
```powershell
(Get-FileHash -Path .\actions-runner-win-x64-2.333.1.zip -Algorithm SHA256).Hash
```

## 5. Extract Zip

### CMD
```bat
tar -xf actions-runner-win-x64-2.333.1.zip
```

### PowerShell
```powershell
Expand-Archive -Path .\actions-runner-win-x64-2.333.1.zip -DestinationPath . -Force
```

Confirm files exist:
- `config.cmd`
- `run.cmd`
- `svc.cmd`

## 6. Configure Runner

Get a **new** runner token from:
`Settings -> Actions -> Runners -> New self-hosted runner`

### CMD
```bat
cd C:\actions-runner
.\config.cmd --url https://github.com/GergesBernaba1/LawyerSys-v2 --token <NEW_TOKEN>
```

### PowerShell
```powershell
Set-Location C:\actions-runner
.\config.cmd --url https://github.com/GergesBernaba1/LawyerSys-v2 --token <NEW_TOKEN>
```

Suggested prompt values:
- Runner name: `iis-prod-runner`
- Labels: keep default (`self-hosted, windows, x64`)
- Work folder: `_work`

## 7. Start Runner (Temporary/Foreground)

### CMD
```bat
.\run.cmd
```

### PowerShell
```powershell
.\run.cmd
```

Keep terminal open in this mode.

## 8. Install Runner as Windows Service (Recommended)

### CMD
```bat
.\svc.cmd install
.\svc.cmd start
.\svc.cmd status
```

### PowerShell
```powershell
.\svc.cmd install
.\svc.cmd start
.\svc.cmd status
```

This allows auto-start after reboot.

## 9. Verify Runner Online

In GitHub:
- `Settings -> Actions -> Runners`
- Runner status must be **Online**.

## 10. Trigger Deployment

Push to `main`:
```bat
git add .
git commit -m "trigger deploy"
git push origin main
```

Then check:
- `Actions` tab for workflow run.

## 11. Common Errors

### `'svc' is not recognized`
Use `.\svc.cmd`, and run inside `C:\actions-runner`.

### `'Invoke-WebRequest' is not recognized`
You are in CMD. Use `curl` or run PowerShell command via `powershell -Command`.

### `Not configured. Run config.(sh/cmd)`
Run `.\config.cmd ...` first, then `.\run.cmd` or `.\svc.cmd start`.

### `'.' is not recognized`
In CMD, use `.\config.cmd` or `config.cmd` (not `./config.cmd`).

## 12. Security Notes

- Never share runner tokens/passwords in chat/screenshots.
- If exposed, revoke immediately and generate a new token.
- Prefer GitHub Secrets for sensitive deployment values.
