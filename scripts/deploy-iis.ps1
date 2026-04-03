param(
    [Parameter(Mandatory = $true)]
    [string]$ApiPublishDir,

    [Parameter(Mandatory = $true)]
    [string]$ApiDeployPath,

    [Parameter(Mandatory = $true)]
    [string]$ApiIisName,

    [Parameter(Mandatory = $true)]
    [string]$ClientSourceRoot,

    [Parameter(Mandatory = $true)]
    [string]$ClientDeployPath,

    [Parameter(Mandatory = $true)]
    [string]$ClientIisName,

    [Parameter(Mandatory = $false)]
    [string]$ClientStartRelativePath = "start.bat",

    [Parameter(Mandatory = $false)]
    [string]$ClientBackendUrl = "",

    [Parameter(Mandatory = $false)]
    [string]$ClientSiteUrl = ""
)

$ErrorActionPreference = "Stop"

function Ensure-Directory {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Sync-Directory {
    param(
        [string]$Source,
        [string]$Target
    )

    Ensure-Directory -Path $Target
    $null = robocopy $Source $Target /MIR /R:2 /W:2 /NFL /NDL /NP /NJH /NJS
    if ($LASTEXITCODE -ge 8) {
        throw "robocopy failed from '$Source' to '$Target' (exit code $LASTEXITCODE)."
    }
}

function Restart-IisTarget {
    param([string]$Name)

    Import-Module WebAdministration

    if (Test-Path "IIS:\AppPools\$Name") {
        Write-Host "Restarting IIS app pool: $Name"
        Restart-WebAppPool -Name $Name
        return
    }

    if (Test-Path "IIS:\Sites\$Name") {
        Write-Host "Restarting IIS site: $Name"
        Stop-Website -Name $Name
        Start-Website -Name $Name
        return
    }

    Write-Warning "IIS target '$Name' was not found as app pool or site."
}

function Stop-ClientNodeProcess {
    param([string]$ClientPath)

    $normalizedPath = [IO.Path]::GetFullPath($ClientPath)
    $escapedPath = [Regex]::Escape($normalizedPath)

    $nodeProcesses = Get-CimInstance Win32_Process -Filter "Name = 'node.exe'" | Where-Object {
        $_.CommandLine -match $escapedPath
    }

    foreach ($proc in $nodeProcesses) {
        Write-Host "Stopping existing client process PID=$($proc.ProcessId)"
        Stop-Process -Id $proc.ProcessId -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "Deploying API..."
Sync-Directory -Source $ApiPublishDir -Target $ApiDeployPath
Restart-IisTarget -Name $ApiIisName

Write-Host "Deploying ClientApp..."
$clientDeploySource = Join-Path $ClientSourceRoot "deploy"
Sync-Directory -Source $clientDeploySource -Target $ClientDeployPath

$clientNextSource = Join-Path $ClientSourceRoot ".next"
$clientNextTarget = Join-Path $ClientDeployPath ".next"
if (Test-Path -LiteralPath $clientNextSource) {
    Sync-Directory -Source $clientNextSource -Target $clientNextTarget
}

$clientPublicSource = Join-Path $ClientSourceRoot "public"
$clientPublicTarget = Join-Path $ClientDeployPath "public"
if (Test-Path -LiteralPath $clientPublicSource) {
    Sync-Directory -Source $clientPublicSource -Target $clientPublicTarget
}

if (Test-Path -LiteralPath (Join-Path $ClientDeployPath "package.json")) {
    Write-Host "Installing client runtime dependencies..."
    Push-Location $ClientDeployPath
    try {
        npm install --omit=dev
    }
    finally {
        Pop-Location
    }
}

Restart-IisTarget -Name $ClientIisName

Stop-ClientNodeProcess -ClientPath $ClientDeployPath

$clientStartPath = Join-Path $ClientDeployPath $ClientStartRelativePath
if (-not (Test-Path -LiteralPath $clientStartPath)) {
    throw "Client start file not found: $clientStartPath"
}

Write-Host "Starting client from: $clientStartPath"
$startCommand = @()
if (-not [string]::IsNullOrWhiteSpace($ClientBackendUrl)) {
    $startCommand += "set NEXT_PUBLIC_BACKEND_URL=$ClientBackendUrl"
    $startCommand += "set NEXT_PUBLIC_API_BASE_URL=$ClientBackendUrl"
}
if (-not [string]::IsNullOrWhiteSpace($ClientSiteUrl)) {
    $startCommand += "set NEXT_PUBLIC_SITE_URL=$ClientSiteUrl"
}
$startCommand += "`"$clientStartPath`""

Start-Process -FilePath "cmd.exe" -ArgumentList "/c $($startCommand -join ' && ')" -WorkingDirectory $ClientDeployPath -WindowStyle Hidden

Write-Host "IIS deployment completed successfully."
