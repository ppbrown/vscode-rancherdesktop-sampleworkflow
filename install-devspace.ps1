#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

$dir = Join-Path $HOME '.local\bin'
$url = 'https://github.com/loft-sh/devspace/releases/latest/download/devspace-windows-amd64.exe'

# Ensure directory exists
if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir | Out-Null
    Write-Host "Created $dir"
}

# Ensure it's on the persistent user PATH (exact-entry match, trailing slashes ignored)
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$entries  = @($userPath -split ';' | Where-Object { $_ })
$onPath   = $entries | Where-Object { $_.TrimEnd('\') -ieq $dir.TrimEnd('\') }

if (-not $onPath) {
    $newPath = (($entries + $dir) -join ';')
    [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
    Write-Host "Added $dir to user PATH (open a new terminal to pick it up)"
}

# Make it available in this session too
if (($env:Path -split ';' | ForEach-Object { $_.TrimEnd('\') }) -inotcontains $dir.TrimEnd('\')) {
    $env:Path += ";$dir"
}

# Download the binary
$dest = Join-Path $dir 'devspace.exe'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
Write-Host "Installed $dest"

& $dest --version