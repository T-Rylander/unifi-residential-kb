# Push-UniFiVLANs.ps1 - API-based VLAN/DHCP push to controller (provisions to USG)
param(
    [string]$Controller = "your-controller-ip:8443",
    [string]$Site = "default",
    [string]$Username = "ubnt",
    [string]$Password = "yourpassword",
    [string]$PayloadFile = "usg-10vlan-api-payload.json",
    [switch]$UseHTTP = $false  # Fallback to HTTP 8080 if HTTPS fails
)

# Normalize path
$ScriptDir = Split-Path -Parent $PSScriptRoot
$ResolvedPayload = Resolve-Path (Join-Path $ScriptDir "configs\$PayloadFile") -ErrorAction Stop
$payload = Get-Content $ResolvedPayload -Raw | ConvertFrom-Json

$creds = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$Username`:$Password"))

# Pre-flight: Test connectivity
$port = if ($UseHTTP) { 8080 } else { 8443 }
$proto = if ($UseHTTP) { "http" } else { "https" }
$connTest = Test-NetConnection -ComputerName $Controller.Split(':')[0] -Port $port
if (-not $connTest.TcpTestSucceeded) {
    Write-Error "Connectivity failed to $Controller ($proto`://$Controller/api/s/$Site). Check: Controller running? Firewall allows $port TCP? Correct IP?"
    Write-Host "Tip: Run 'Test-NetConnection -ComputerName <ip> -Port $port' manually."
    return
}

Write-Host "Connectivity OK to $Controller on port $port."

# Temp cert bypass (HTTPS only)
if (-not $UseHTTP) {
    $originalCallback = [System.Net.ServicePointManager]::ServerCertificateValidationCallback
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
}

try {
    $uri = "$proto`://$Controller/api/s/$Site/rest/networkconf"
    $response = Invoke-RestMethod -Uri $uri -Method Post -Headers @{ Authorization = "Basic $creds"; "Content-Type" = "application/json" } -Body ($payload | ConvertTo-Json -Depth 3)
    Write-Host "VLANs pushed successfully!"
    Write-Host "Response: $($response | ConvertTo-Json -Compress)"
} catch {
    Write-Error "API push failed: $($_.Exception.Message)"
    Write-Host "Check creds/site/JSON. Common: 401 (auth), 400 (invalid subnet), 404 (bad site)."
    if ($_.Exception.Response) {
        $status = $_.Exception.Response.StatusCode
        Write-Host "HTTP Status: $status"
    }
} finally {
    if (-not $UseHTTP) {
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $originalCallback
    }
}

Write-Host "Provision USG in controller to apply 10.0.5.x."