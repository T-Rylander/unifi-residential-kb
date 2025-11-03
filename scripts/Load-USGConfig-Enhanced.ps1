# Load-USGConfig.ps1
# Enhanced script to SCP and apply USG config snippet via SSH with error handling
# Purpose: Automate loading VyOS CLI snippets (e.g., VLAN setups) onto UniFi USG.
# Repo: https://github.com/T-Rylander/unifi-residential-kb
# Usage: .\scripts\Load-USGConfig.ps1 -USG_IP "192.168.1.1" -ConfigFile ".\configs\usg-vlan-full-setup.conf"
# Prereqs: Posh-SSH module (Install-Module Posh-SSH -Scope CurrentUser); OpenSSH for testing.

param(
    [Parameter(Mandatory=$true)]
    [string]$USG_IP,  # e.g., "192.168.1.1"

    [Parameter(Mandatory=$true)]
    [string]$ConfigFile,  # Local path to your config snippet (e.g., "./configs/usg-vlan-full-setup.conf")

    [Parameter(Mandatory=$false)]
    [string]$Username = "ubnt"  # Default USG user
)

# Validate config file exists and format (VyOS CLI: multi-line 'set' commands)
if (-not (Test-Path $ConfigFile)) {
    Write-Error "Config file not found: $ConfigFile"
    exit 1
}
$ConfigLines = Get-Content $ConfigFile
$SetLineCount = ($ConfigLines | Select-String '^set ' -Quiet).Count
if ($SetLineCount -eq 0) {
    Write-Warning "No 'set' commands detected in $ConfigFile. Ensure VyOS CLI format (multi-line 'set ...'). Proceeding anyway."
}

# Secure password prompt
$SecurePassword = Read-Host "Enter USG password" -AsSecureString
$Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword))

# Step 1: Upload config via Posh-SSH (avoids scp password issues; uses echo for small files)
Import-Module Posh-SSH -ErrorAction Stop
$Credential = New-Object System.Management.Automation.PSCredential ($Username, (ConvertTo-SecureString $Password -AsPlainText -Force))
$Session = New-SSHSession -ComputerName $USG_IP -Credential $Credential -AcceptKey -Port 22

if (-not $Session) {
    Write-Error "SSH connection failed. Test manually: ssh $Username@$USG_IP"
    exit 1
}

Write-Host "Uploading $ConfigFile to USG:/tmp/usg-config.cfg..."
$ConfigContent = Get-Content $ConfigFile -Raw -Encoding UTF8  # Handle any special chars
# Escape single quotes in content for echo (simple; for complex, use base64)
$EscapedContent = $ConfigContent -replace "'", "'\"'\"'"
Invoke-SSHCommand -SessionId $Session.SessionId -Command "echo '$EscapedContent' > /tmp/usg-config.cfg" -ErrorAction Stop
$UploadOutput = (Invoke-SSHCommand -SessionId $Session.SessionId -Command "ls -la /tmp/usg-config.cfg").Output
if ($UploadOutput -notmatch "usg-config.cfg") {
    Write-Error "Upload failed. Output: $UploadOutput"
    Remove-SSHSession -SessionId $Session.SessionId
    exit 1
}
Write-Host "Upload successful: $($UploadOutput | Out-String)"

# Step 2: Apply config with error handling and verification
Write-Host "Connected to USG. Applying config..."
$Commands = @(
    @{Cmd="configure"; Expect="edit"; Desc="Entering config mode"},
    @{Cmd="load /tmp/usg-config.cfg"; Expect="success|loaded"; Desc="Loading config"},
    @{Cmd="commit"; Expect="[Oo]k|success|applied"; Desc="Committing changes" },  # Flexible for 'ok' or 'All configuration items reviewed'
    @{Cmd="save"; Expect="saved|Saved"; Desc="Saving config"},
    @{Cmd="show | compare"; Expect=""; Desc="Verifying changes (diff)"},
    @{Cmd="exit"; Expect=""; Desc="Exiting config mode"},
    @{Cmd="rm /tmp/usg-config.cfg"; Expect=""; Desc="Cleanup"},
    @{Cmd="show log | last 10"; Expect=""; Desc="Recent logs for verification"}
)

foreach ($Step in $Commands) {
    $Output = (Invoke-SSHCommand -SessionId $Session.SessionId -Command $Step.Cmd).Output
    Write-Host "[$($Step.Desc)] Output:`n$Output`n"
    if ($Step.Expect -and $Output -notmatch $Step.Expect) {
        Write-Error "Command '$($Step.Cmd)' failed. Expected pattern '$($Step.Expect)', got: $Output"
        Remove-SSHSession -SessionId $Session.SessionId
        exit 1
    }
}

Remove-SSHSession -SessionId $Session.SessionId
Write-Host "Config loaded, committed, and verified successfully! Review logs above for issues (e.g., interface changes)."
Write-Host "Next: Reboot USG if needed (e.g., 'ssh $Username@$USG_IP reboot') and re-adopt in UniFi Controller."

# Clear sensitive vars
$Password = $null
$SecurePassword.Dispose()