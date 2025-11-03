# Push-UniFiVLANs.ps1 - API-based VLAN/DHCP push to controller (provisions to USG)
param(
    [string]$Controller = "your-controller-ip:8443",  # e.g., "192.168.1.100:8443"
    [string]$Site = "default",
    [string]$Username = "ubnt",
    [string]$Password = "yourpassword",
    [string]$PayloadFile = "usg-10vlan-api-payload.json"  # Defaults to ../configs/
)

# Normalize path (from scripts/ to configs/)
$ScriptDir = Split-Path -Parent $PSScriptRoot
$ResolvedPayload = Resolve-Path (Join-Path $ScriptDir "configs\$PayloadFile") -ErrorAction Stop
$payload = Get-Content $ResolvedPayload -Raw | ConvertFrom-Json

$creds = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$Username`:$Password"))

Invoke-RestMethod -Uri "https://$Controller/api/s/$Site/rest/networkconf" -Method Post -Headers @{ Authorization = "Basic $creds"; "Content-Type" = "application/json" } -Body ($payload | ConvertTo-Json -Depth 3) -SkipCertificateCheck
Write-Host "VLANs pushed from $ResolvedPayload! Provision USG in controller (Devices > USG > Actions > Provision)."