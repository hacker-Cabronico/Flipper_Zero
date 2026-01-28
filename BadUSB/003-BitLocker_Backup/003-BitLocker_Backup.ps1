# =====================================================
# Export BitLocker Recovery Keys (Optional Base64)
# UTF-8 REAL (con BOM) para preservar tildes
# =====================================================

# Verificar permisos de administrador
$principal = New-Object Security.Principal.WindowsPrincipal `
    ([Security.Principal.WindowsIdentity]::GetCurrent())

if (-not $principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {

    Write-Host "Este script debe ejecutarse como Administrador." -ForegroundColor Red
    Exit 1
}

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host " EXPORTACION DE CLAVES DE RECUPERACION BITLOCKER" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "ADVERTENCIA:" -ForegroundColor Yellow
Write-Host "La Recovery Key permite acceso TOTAL a los datos."
Write-Host "Guardela fuera del equipo y en un lugar seguro."
Write-Host ""

$confirm = Read-Host "Desea continuar? (S / N)"
if ($confirm.ToUpper() -ne "S") {
    Write-Host "Operacion cancelada por el usuario." -ForegroundColor Red
    Exit 0
}

Write-Host ""
Write-Host "Seleccione el formato de exportacion:" -ForegroundColor Cyan
Write-Host "1 - Texto plano (LEGIBLE)"
Write-Host "2 - Base64 (OFUSCADO)"
Write-Host ""

$option = Read-Host "Opcion (1 o 2)"
if ($option -ne "1" -and $option -ne "2") {
    Write-Host "Opcion invalida." -ForegroundColor Red
    Exit 1
}

$useBase64 = ($option -eq "2")

# Ruta de salida
$timestamp  = Get-Date -Format "[yyyy-MM-dd_HH-mm-ss]"
$outputPath = Join-Path $env:USERPROFILE "Desktop\BitLocker_RecoveryKeys_$timestamp.txt"

# Preparar UTF-8 real con BOM (compatible con Bloc de notas)
$utf8   = New-Object System.Text.UTF8Encoding($true)
$writer = New-Object System.IO.StreamWriter($outputPath, $false, $utf8)

try {
    $formatText = if ($useBase64) { "BASE64 (OFUSCADO)" } else { "TEXTO PLANO" }

    # Encabezado
    $writer.WriteLine("BITLOCKER RECOVERY KEYS EXPORT")
    $writer.WriteLine("Fecha: $(Get-Date)")
    $writer.WriteLine("Equipo: $env:COMPUTERNAME")
    $writer.WriteLine("Usuario: $env:USERNAME")
    $writer.WriteLine("Formato: $formatText")
    $writer.WriteLine("=================================================")
    $writer.WriteLine("")

    # Obtener volúmenes BitLocker
    $volumes = Get-BitLockerVolume

    foreach ($vol in $volumes) {

        $writer.WriteLine("Unidad: $($vol.MountPoint)")
        $writer.WriteLine("Estado cifrado: $($vol.VolumeStatus)")
        $writer.WriteLine("Protección: $($vol.ProtectionStatus)")

        $recoveryProtectors = $vol.KeyProtector |
            Where-Object { $_.KeyProtectorType -eq "RecoveryPassword" }

        if ($recoveryProtectors) {
            foreach ($kp in $recoveryProtectors) {

                $writer.WriteLine("Recovery Key ID: $($kp.KeyProtectorId)")

                if ($useBase64) {
                    $bytes  = [System.Text.Encoding]::UTF8.GetBytes($kp.RecoveryPassword)
                    $base64 = [Convert]::ToBase64String($bytes)
                    $writer.WriteLine("Recovery Password (Base64):")
                    $writer.WriteLine($base64)
                }
                else {
                    $writer.WriteLine("Recovery Password:")
                    $writer.WriteLine($kp.RecoveryPassword)
                }
            }
        }
        else {
            $writer.WriteLine("No se encontró Recovery Key para esta unidad.")
        }

        $writer.WriteLine("-------------------------------------------------")
        $writer.WriteLine("")
    }
}
finally {
    # Cerrar correctamente el archivo
    $writer.Close()
}

Write-Host ''
Write-Host 'Exportacion completada correctamente.' -ForegroundColor Green
Write-Host 'Archivo generado:' -ForegroundColor Green
Write-Host $outputPath -ForegroundColor Yellow
Write-Host ''
Write-Host 'RECOMENDACION:' -ForegroundColor Red
Write-Host '- Copie el archivo a USB o nube segura.'
Write-Host '- Elimine el archivo del escritorio luego.'
