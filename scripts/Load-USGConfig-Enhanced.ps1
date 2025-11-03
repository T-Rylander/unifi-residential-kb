# Load-USGConfig-Enhanced.ps1
# Enhanced script to upload and apply USG config snippet via SSH with robust error handling
# Purpose: Automate loading VyOS CLI snippets (e.g., VLAN setups) onto UniFi USG.
# Repo: https://github.com/T-Rylander/unifi-residential-kb
# Usage: .\scripts\Load-USGConfig-Enhanced.ps1 -USG_IP "192.168.1.1" -ConfigFile ".\configs\usg-vlan-full-setup.conf"
# Prereqs: Posh-SSH module (Install-Module Posh-SSH -Scope CurrentUser); OpenSSH for testing.

param(
    [Parameter(Mandatory=$true)]
    [string]$USG_IP,  # e.g., "192.168.1.1"

    [Parameter(Mandatory=$true)]
    [string]$ConfigFile,  # Local path to your config snippet (e.g., "./configs/usg-vlan-full-setup.conf")

    [Parameter(Mandatory=$false)]
    [string]$Username = "ubnt",  # Default USG user

    [Parameter(Mandatory=$false)]
    [int]$Port = 22  # SSH port
)

# Validate config file exists
if (-not (Test-Path $ConfigFile)) {
    Write-Error "Config file not found: $ConfigFile"
    exit 1
}

# Validate VyOS CLI format (check for 'set' commands)
$ConfigLines = @(Get-Content $ConfigFile)
$SetLineCount = @($ConfigLines | Select-String '^set ' | Measure-Object).Count
if ($SetLineCount -eq 0) {
    Write-Warning "No 'set' commands detected in $ConfigFile. Ensure VyOS CLI format (lines starting with '
