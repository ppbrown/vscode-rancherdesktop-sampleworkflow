#Requires -Version 5.1
# Install Rancher Desktop on Windows and start it with the settings k-app expects:
#   - container engine: dockerd (moby), so the docker CLI works
#   - Kubernetes enabled
# Counterpart of install-rancher.sh for Linux.
$ErrorActionPreference = 'Stop'

# Run a native command quietly and return its exit code. PowerShell 5.1 turns a
# native program's stderr into errors under 'Stop', so relax that locally.
function Test-Native([scriptblock]$cmd) {
    $ErrorActionPreference = 'Continue'
    & $cmd *> $null
    return $LASTEXITCODE
}

# --- WSL2 is required by Rancher Desktop on Windows ----------------------
if ((Test-Native { wsl.exe --status }) -ne 0) {
    Write-Host 'WSL is not installed. Rancher Desktop needs it.'
    Write-Host 'Run this in an *Administrator* PowerShell, reboot, then rerun this script:'
    Write-Host '    wsl --install --no-distribution'
    exit 1
}

# --- Install via winget (skipped if already installed) -------------------
if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
    throw 'winget not found. Install "App Installer" from the Microsoft Store, then rerun.'
}

$id = 'SUSE.RancherDesktop'
if ((Test-Native { winget.exe list --id $id -e --accept-source-agreements }) -eq 0) {
    Write-Host 'Rancher Desktop is already installed.'
} else {
    Write-Host 'Installing Rancher Desktop (Windows may ask for admin permission)...'
    & winget.exe install --id $id -e --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) { throw "winget install failed (exit code $LASTEXITCODE)" }
}

# --- Find rdctl (PATH isn't refreshed in this session after install) -----
$candidates = @(
    (Join-Path $env:ProgramFiles 'Rancher Desktop\resources\resources\win32\bin\rdctl.exe'),
    (Join-Path $env:LOCALAPPDATA 'Programs\Rancher Desktop\resources\resources\win32\bin\rdctl.exe')
)
$rdctl = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $rdctl) {
    throw "Installed, but rdctl.exe not found in: $($candidates -join ', ')"
}

# --- Start it (or update settings if already running) --------------------
Write-Host 'Starting Rancher Desktop with dockerd (moby) and Kubernetes enabled...'
& $rdctl start --container-engine.name=moby --kubernetes.enabled=true
if ($LASTEXITCODE -ne 0) { throw "rdctl start failed (exit code $LASTEXITCODE)" }

Write-Host ''
Write-Host 'Done. The first start downloads Kubernetes and can take a few minutes;'
Write-Host 'watch progress in the Rancher Desktop window. Open a new terminal so'
Write-Host 'docker, kubectl and rdctl are on your PATH.'
