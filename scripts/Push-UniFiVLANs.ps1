# Push-UniFiVLANs.ps1 - API-based VLAN/DHCP push to controller (provisions to USG)
param(
    [string]$Controller = "your-controller-ip:8443",
    [string]$Site = "default",
    [string]$Username = "ubnt",
    [string]$Password = "yourpassword",
    [string]$PayloadFile = "usg-10vlan-api-payload.json",
    [switch]$CloudHosted = $false  # Set $true for cloud.ui.com (no /proxy/network)
)

# Normalize path
$ScriptDir = Split-Path -Parent $PSScriptRoot
$ResolvedPayload = Resolve-Path (Join-Path $ScriptDir "configs\$PayloadFile") -ErrorAction Stop
$payload = Get-Content $ResolvedPayload -Raw | ConvertFrom-Json

$creds = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$Username`:$Password"))

# Pre-flight: Test connectivity (port 8443)
$ip = $Controller.Split(':')[0]
$port = 8443
$connTest = Test-NetConnection -ComputerName $ip -Port $port
if (-not $connTest.TcpTestSucceeded) {
    Write-Error "Connectivity failed to $Controller on port $port. Check firewall/IP."
    return
}
Write-Host "Connectivity OK to $Controller on port $port."

# Get sites to validate $Site (helps debug 404s)
$proto = "https"
$siteUri = "$proto`://$Controller"
if (-not $CloudHosted) { $siteUri += "/proxy/network" }
$siteUri += "/api/s/$Site/self/sites"
try {
    $sitesResponse = Invoke-RestMethod -Uri $siteUri -Method Get -Headers @{ Authorization = "Basic $creds" } -SkipCertificateCheck:$false
    Write-Host "Site '$Site' valid. Available sites: $($sitesResponse.data.desc)"
} catch {
    Write-Warning "Site check failed ($($_.Exception.Message)). Assuming '$Site' is correct—proceed?"
}

# Temp cert bypass
$originalCallback = [System.Net.ServicePointManager]::ServerCertificateValidationCallback
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

try {
    $uri = "$proto`://$Controller"
    if (-not $CloudHosted) { $uri += "/proxy/network" }
    $uri += "/api/s/$Site/rest/networkconf"
    $response = Invoke-RestMethod -Uri $uri -Method Post -Headers @{ Authorization = "Basic $creds"; "Content-Type" = "application/json" } -Body ($payload | ConvertTo-Json -Depth 3)
    Write-Host "VLANs pushed successfully!"
    Write-Host "Response: $($response | ConvertTo-Json -Compress)"
} catch {
    Write-Error "API push failed: $($_.Exception.Message)"
    Write-Host "Common fixes: 401 (creds), 404 (site/prefix—try -CloudHosted if cloud.ui.com), 400 (JSON/subnet)."
    if ($_.Exception.Response) {
        $status = $_.Exception.Response.StatusCode
        Write-Host "HTTP Status: $status"
    }
} finally {
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $originalCallback
}

Write-Host "Provision USG in controller to apply 10.0.5.x."