# =========================================
# WiFi Security Audit - DEMO / AUDITORIA
# CyberRedPanda | Metrics Only | Ethical
# Ultima actualización, 7 de Enero 2026
# =========================================

# ===== CONFIGURACION =====
$MaskChars = 3
$ShowRecommendations = $true
$Mode = "DEMO"      # DEMO | AUDITORIA
$ExportPath = "$env:TEMP\wifi_security_metrics.csv"

# ===== CONTENEDORES =====
$results = @()
$totalScore = 0
$count = 0
$worst = @{ SSID=""; Score=10 }

# ===== PERFILES (multi-idioma + únicos) =====
$profiles = netsh wlan show profile |
    Select-String "All User Profile|Perfil de todos los usuarios" |
    ForEach-Object { ($_ -split ":\s*", 2)[1].Trim() } |
    Sort-Object -Unique

# ===== CABECERA =====
Write-Host "====================================" -ForegroundColor Cyan
Write-Host " WiFi Security Audit ($Mode)" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

# ===== ANALISIS =====
foreach ($ssid in $profiles) {

    $raw = netsh wlan show profile name="$ssid" key=clear
    $line = $raw | Select-String "Contenido de la clave|Key Content"

    if ($line) {

        # --- PARSING ROBUSTO DE CLAVE ---
        $pwd = ($line -replace '.*?:\s*', '').Trim()

        if ([string]::IsNullOrWhiteSpace($pwd)) {
            $pwd = ""
        }

        # --- ENMASCARADO ---
        if ($pwd.Length -gt $MaskChars) {
            $masked = $pwd.Substring(0, $pwd.Length - $MaskChars) + ("*" * $MaskChars)
        } else {
            $masked = ("*" * $MaskChars)
        }

        # --- SCORING (NIST / OWASP inspired) ---
        $score = 0
        if ($pwd.Length -ge 8)  { $score += 2 }
        if ($pwd.Length -ge 12) { $score += 3 }
        if ($pwd.Length -ge 16) { $score += 1 }
        if ($pwd -match "[a-z]") { $score += 1 }
        if ($pwd -match "[A-Z]") { $score += 1 }
        if ($pwd -match "\d")    { $score += 1 }
        if ($pwd -match "[^a-zA-Z0-9]") { $score += 1 }
        if ($pwd.Length -lt 8) { $score -= 2 }
        if ($pwd -match "^[a-zA-Z]+$" -or $pwd -match "^\d+$") { $score -= 1 }

        if ($score -lt 0)  { $score = 0 }
        if ($score -gt 10) { $score = 10 }

        # --- NIVEL ---
        if ($score -le 2) {
            $level = "Nula"; $color = "Red"
        }
        elseif ($score -le 4) {
            $level = "Baja"; $color = "DarkRed"
        }
        elseif ($score -le 7) {
            $level = "Media"; $color = "Yellow"
        }
        else {
            $level = "Alta"; $color = "Green"
        }

        Write-Host ($ssid.PadRight(20)) ":" $masked "[Nivel:" $level "| Score:" $score "/10]" -ForegroundColor $color

        if ($ShowRecommendations -and $score -lt 8) {
            Write-Host "  -> Recomendacion: >=12 caracteres, may/min, numeros y simbolos" -ForegroundColor DarkYellow
        }

        # --- METRICAS ---
        $results += [pscustomobject]@{
            SSID  = $ssid
            Score = $score
            Level = $level
        }

        $totalScore += $score
        $count++

        if ($score -lt $worst.Score) {
            $worst.SSID  = $ssid
            $worst.Score = $score
        }

    } else {

        Write-Host ($ssid.PadRight(20)) ": (sin clave) [Nivel: Nula | Score: 0/10]" -ForegroundColor Red

        $results += [pscustomobject]@{
            SSID  = $ssid
            Score = 0
            Level = "Nula"
        }

        $count++
    }
}

# ===== RESUMEN =====
$avg = if ($count -gt 0) { [math]::Round($totalScore / $count, 2) } else { 0 }

Write-Host "------------------------------------" -ForegroundColor Cyan
Write-Host " Resumen" -ForegroundColor Cyan
Write-Host " Promedio de seguridad: $avg / 10"
Write-Host " Peor red: $($worst.SSID) (Score $($worst.Score)/10)"

# ===== EXPORTACION =====
if ($Mode -eq "AUDITORIA") {
    $results | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
    Write-Host " Metric as exportadas a: $ExportPath" -ForegroundColor Cyan
}
