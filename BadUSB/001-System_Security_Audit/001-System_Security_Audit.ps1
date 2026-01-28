# ==========================================
# System Security Audit (Read-Only)
# NIST / OWASP inspired
# ==========================================

# 0. Check for Administrative Privileges
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "CRITICAL ERROR: This script must be run as Administrator." -ForegroundColor Red
    Write-Host "Please restart PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit
}

$Mode = "AUDITORIA"            # DEMO | AUDITORIA
$ExportCSV = $true
$ExportPath = "$env:TEMP\system_security_audit.csv"

# Use Generic List for better performance than array +=
$results = New-Object System.Collections.Generic.List[PSCustomObject]

function Add-Result {
    param($Category, $Status, $Score, $Details)
    $script:results.Add([pscustomobject]@{
        Category = $Category
        Status   = $Status
        Score    = $Score
        Details  = $Details
    })
}

Write-Host "====================================" -ForegroundColor Cyan
Write-Host " System Security Audit ($Mode)" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

# ------------------------------
# 1. Password Policy Audit
# ------------------------------
try {
    $policy = net accounts | Out-String
    
    # Robust parsing for both English and Spanish (and others) using Regex
    # English: Minimum password length: 12  /  Maximum password age (days): 42
    # Spanish: Longitud mínima de contraseña: 12 / Edad máxima de contraseña (días): 42
    
    $minLenMatch = $policy | Select-String -Pattern '(?i)(?:Minimum password length|Longitud mínima.*):\s*(\d+)'
    $maxAgeMatch = $policy | Select-String -Pattern '(?i)(?:Maximum password age|Edad máxima.*):\s*(\d+|unlimited|ilimitado)'
    
    $minLen = if ($minLenMatch) { $minLenMatch.Matches.Groups[1].Value } else { "0" }
    $maxAge = if ($maxAgeMatch) { $maxAgeMatch.Matches.Groups[1].Value } else { "Unknown" }

    $score = 5
    if ([int]$minLen -ge 12) { $score += 3 }
    if ($maxAge -notmatch '(?i)(unlimited|ilimitado)') { $score += 2 }
    if ($score -gt 10) { $score = 10 }

    Add-Result "Password Policy" "OK" $score "MinLength=$minLen, MaxAge=$maxAge"
}
catch {
    Add-Result "Password Policy" "Unknown" 3 "Unable to read policy: $($_.Exception.Message)"
}

# ------------------------------
# 2. Antivirus Audit (Defender + 3rd Party)
# ------------------------------
try {
    $avNames = New-Object System.Collections.Generic.List[string]
    $isActive = $false
    $details = ""

    # Check Windows Defender first
    $def = Get-MpComputerStatus
    if ($def.AntivirusEnabled) {
        $avNames.Add("Microsoft Defender")
        if ($def.RealTimeProtectionEnabled) { $isActive = $true }
    }

    # Check 3rd Party via WMI (SecurityCenter2)
    $wmiAV = Get-CimInstance -Namespace "root\SecurityCenter2" -ClassName "AntiVirusProduct" -ErrorAction SilentlyContinue
    foreach ($av in $wmiAV) {
        if ($av.displayName -ne "Windows Defender") {
            $avNames.Add($av.displayName)
            # productState is a bitmask. Converting to hex and checking the middle digits
            # usually indicates "Enabled" (e.g. 0x1100 or 0x1000)
            $stateHex = $av.productState.ToString("X")
            if ($stateHex.Length -ge 4 -and $stateHex.Substring($stateHex.Length-4, 2) -eq "10" -or $stateHex.Substring($stateHex.Length-4, 2) -eq "11") {
                $isActive = $true
            }
        }
    }

    if ($avNames.Count -eq 0) {
        Add-Result "Antivirus" "None" 2 "No antivirus detected"
    } else {
        $foundList = $avNames -join ", "
        if ($isActive) {
            Add-Result "Antivirus" "Active" 9 "Detected active: $foundList"
        } else {
            Add-Result "Antivirus" "Inactive" 4 "Detected INACTIVE: $foundList"
        }
    }
}
catch {
    Add-Result "Antivirus" "Unknown" 3 "AV status check failed: $($_.Exception.Message)"
}

# ------------------------------
# 3. Firewall Audit
# ------------------------------
try {
    $fw = Get-NetFirewallProfile
    if ($fw.Enabled -notcontains $false) {
        Add-Result "Firewall" "Enabled" 9 "All profiles enabled"
    } else {
        Add-Result "Firewall" "Partial" 4 "One or more profiles disabled"
    }
}
catch {
    Add-Result "Firewall" "Unknown" 3 "Cannot query firewall"
}

# ------------------------------
# 4. Insecure Services
# ------------------------------
$issues = New-Object System.Collections.Generic.List[string]
try {
    if ((Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -ErrorAction SilentlyContinue).State -eq "Enabled") {
        $issues.Add("SMBv1")
    }
} catch {}

if (Get-Service Telnet -ErrorAction SilentlyContinue) {
    $issues.Add("Telnet")
}

$rdpPath = "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
$nla = Get-ItemProperty -Path $rdpPath -Name "UserAuthentication" -ErrorAction SilentlyContinue
if ($nla -and $nla.UserAuthentication -eq 0) {
    $issues.Add("RDP without NLA")
}

if ($issues.Count -eq 0) {
    Add-Result "Insecure Services" "None" 9 "No insecure services detected"
} else {
    Add-Result "Insecure Services" "Detected" 3 ($issues -join ", ")
}

# ------------------------------
# 5. BitLocker Audit
# ------------------------------
try {
    $bl = Get-BitLockerVolume -MountPoint "C:" -ErrorAction Stop
    if ($bl.ProtectionStatus -eq "On") {
        Add-Result "BitLocker" "Enabled" 9 "Disk encrypted"
    } else {
        Add-Result "BitLocker" "Disabled" 2 "Disk not encrypted"
    }
}
catch {
    Add-Result "BitLocker" "Unknown" 3 "BitLocker not available or accessible"
}

# ------------------------------
# 6. Backup Audit
# ------------------------------
try {
    $fh = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\FileHistory" -ErrorAction Stop
    Add-Result "Backups" "Configured" 7 "File History configured"
}
catch {
    Add-Result "Backups" "NotConfigured" 3 "No backup configuration detected"
}

# ------------------------------
# 7. Inventory (Read-only)
# ------------------------------
try {
    $os = Get-CimInstance Win32_OperatingSystem
    $uptime = (New-TimeSpan -Start $os.LastBootUpTime).Days
    Add-Result "Inventory" "Info" 10 "Host=$env:COMPUTERNAME, User=$env:USERNAME, Uptime=${uptime}d"
} catch {
    Add-Result "Inventory" "Error" 0 "Failed to retrieve system info"
}

# ------------------------------
# 8. Patch Audit
# ------------------------------
try {
    $hotfix = Get-HotFix | Sort-Object InstalledOn -Descending -ErrorAction Stop | Select-Object -First 1
    Add-Result "Patching" "OK" 8 "Last patch: $($hotfix.InstalledOn.ToShortDateString())"
}
catch {
    Add-Result "Patching" "Unknown" 3 "Cannot read patches"
}

# ------------------------------
# 9. UAC Status Audit
# ------------------------------
try {
    $uacPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
    $lua = Get-ItemProperty -Path $uacPath -Name "EnableLUA" -ErrorAction SilentlyContinue
    $consent = Get-ItemProperty -Path $uacPath -Name "ConsentPromptBehaviorAdmin" -ErrorAction SilentlyContinue
    
    if ($lua.EnableLUA -eq 1 -and $consent.ConsentPromptBehaviorAdmin -ge 2) {
        Add-Result "UAC Status" "Secure" 9 "UAC Enabled (Level: $($consent.ConsentPromptBehaviorAdmin))"
    } else {
        Add-Result "UAC Status" "Weak" 3 "UAC disabled or low level"
    }
} catch {
    Add-Result "UAC Status" "Unknown" 3 "Cannot read UAC registry"
}

# ------------------------------
# 11. Local Admins Audit
# ------------------------------
try {
    $adminGroup = Get-LocalGroup -SID "S-1-5-32-544" # Standard SID for Administrators
    $members = Get-LocalGroupMember -Group $adminGroup.Name | Select-Object -ExpandProperty Name
    $memberList = $members -join ", "
    Add-Result "Local Admins" "Review" 7 "Current Admins: $memberList"
} catch {
    Add-Result "Local Admins" "Unknown" 3 "Cannot read local groups"
}

# ------------------------------
# 12. Guest Account Status
# ------------------------------
try {
    $guest = Get-LocalUser -SID "S-1-5-21-*-501" -ErrorAction SilentlyContinue # Standard SID pattern for Guest
    if (-not $guest) { $guest = Get-LocalUser -Name "Guest", "Invitado" -ErrorAction SilentlyContinue }
    
    if ($guest.Enabled) {
        Add-Result "Guest Account" "WARNING" 2 "Guest account is ENABLED"
    } else {
        Add-Result "Guest Account" "OK" 10 "Guest account is disabled"
    }
} catch {
    Add-Result "Guest Account" "Unknown" 3 "Cannot verify Guest account"
}

# ------------------------------
# 13. Windows Update Config
# ------------------------------
try {
    $auPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update"
    $auOpt = Get-ItemProperty -Path $auPath -Name "AUOptions" -ErrorAction SilentlyContinue
    # 4 = Auto download and install
    if ($auOpt.AUOptions -eq 4) {
        Add-Result "Win Update" "Auto" 9 "Automatic updates enabled (Level 4)"
    } else {
        Add-Result "Win Update" "Manual/Weak" 4 "Not set to automatic install"
    }
} catch {
    Add-Result "Win Update" "Unknown" 3 "Cannot read Update config"
}

# ------------------------------
# 14. PS Execution Policy
# ------------------------------
try {
    $policy = Get-ExecutionPolicy -Scope LocalMachine
    if ($policy -in @("Restricted", "AllSigned")) {
        Add-Result "PS Policy" "Secure" 9 "Policy: $policy"
    } elseif ($policy -eq "RemoteSigned") {
        Add-Result "PS Policy" "Moderate" 7 "Policy: $policy"
    } else {
        Add-Result "PS Policy" "Weak" 3 "Policy: $policy"
    }
} catch {
    Add-Result "PS Policy" "Unknown" 3 "Cannot read policy"
}

# ------------------------------
# Summary
# ------------------------------
Write-Host ""
Write-Host "--------- Summary ---------" -ForegroundColor Cyan
Write-Host ("{0,-18} | {1,-12} | {2,-6} | {3}" -f "Category", "Status", "Score", "Details") -ForegroundColor Gray
Write-Host ("{0,-18}-|-{1,-12}-|-{2,-6}-|-" -f ("-" * 18), ("-" * 12), ("-" * 6)) -ForegroundColor Gray

$results | ForEach-Object {
    $color = if ($_.Score -ge 8) { "Green" } elseif ($_.Score -ge 5) { "Yellow" } else { "Red" }
    $scoreDisplay = "$($_.Score)/10"
    Write-Host ("{0,-18} | {1,-12} | {2,-6} | {3}" -f $_.Category, $_.Status, $scoreDisplay, $_.Details) -ForegroundColor $color
}

$avg = [math]::Round(($results | Measure-Object Score -Average).Average, 2)
Write-Host ""
Write-Host "Overall Security Score: $avg / 10" -ForegroundColor Cyan

if ($ExportCSV -and $Mode -eq "AUDITORIA") {
    $results | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
    Write-Host "Metrics exported to $ExportPath" -ForegroundColor Cyan
}

# ------------------------------
# Final Critical Audit: Unquoted Service Paths (Post-Summary)
# ------------------------------
Write-Host ""
Write-Host ">>> SECURITY ALERT: UNQUOTED SERVICE PATHS <<<" -ForegroundColor Yellow
try {
    $services = Get-CimInstance Win32_Service | Where-Object { $_.PathName -notmatch '^"' -and $_.PathName -like '* *' }
    if ($services) {
        Write-Host "STATUS: VULNERABLE" -ForegroundColor Red
        Write-Host "DETAILS: Found services with spaces in paths that are not enclosed in quotes. This can be exploited for Local Privilege Escalation (LPE)." -ForegroundColor Yellow
        Write-Host "Affected Services:" -ForegroundColor Gray
        $services | ForEach-Object { Write-Host " - $($_.Name): $($_.PathName)" -ForegroundColor White }
    } else {
        Write-Host "STATUS: SECURE" -ForegroundColor Green
        Write-Host "DETAILS: No unquoted service paths detected. Windows services are correctly configured." -ForegroundColor Gray
    }
} catch {
    Write-Host "STATUS: UNKNOWN" -ForegroundColor Magenta
    Write-Host "DETAILS: Unable to audit system services." -ForegroundColor Gray
}
Write-Host ("=" * 60) -ForegroundColor Cyan

