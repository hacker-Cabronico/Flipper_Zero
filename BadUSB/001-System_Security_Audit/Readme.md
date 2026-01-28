# 001 System Security Audit
![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue?logo=powershell)
![Windows](https://img.shields.io/badge/Windows-10%2F11-lightgrey?logo=windows)
![License: MIT](https://img.shields.io/badge/License-MIT-green)
![Security](https://img.shields.io/badge/Security-NIST%2FOWASP-critical?logo=microsoft)

---

## 🐼 Autor

CyberRedPanda / Hacker-Cabrónico.

> Proyecto para concienciación, pentesting defensivo y formación.
---

## 📌 Descripción

Auditoría local y de solo lectura inspirada en NIST y OWASP, diseñada para evaluar el estado de seguridad de un sistema Windows.El script genera un score de seguridad (0–10) por categoría y un promedio general, además de exportar métricas a CSV.

> ⚠️ **Uso ético únicamente**. Ejecutar solo en equipos propios o con autorización explícita.

---

## 📁 Estructura del proyecto

001-System_Security_Audit/

├── 001-System_Security_Audit.ps1 # Script principal de auditoría

├─── 001-System_Security_Audit.txt # Script BadUSB instalado en un dispositvo (Flipper Zero)

└── README.md # Este archivo

---

## 🧠 ¿Qué hace el script PowerShell?

El script realiza una auditoría completa en las siguientes áreas:

- Password Policy → Evalúa longitud mínima y edad máxima de contraseñas
- Antivirus → Detecta Microsoft Defender y antivirus de terceros, estado activo/inactivo
- Firewall → Verifica si todos los perfiles están habilitados
- Insecure Services → Detecta SMBv1, Telnet y RDP sin NLA
- BitLocker → Comprueba si el disco C: está cifrado
- Backups → Revisa configuración de File History
- Inventory → Muestra información del host, usuario y uptime
- Patch Audit → Fecha del último hotfix instalado
- UAC Status → Nivel de seguridad de UAC
- Local Admins → Lista de miembros del grupo Administradores
- Guest Account → Estado de la cuenta invitado
- Windows Update → Configuración de actualizaciones automáticas
- PS Execution Policy → Nivel de restricción de ejecución de scripts

Unquoted Service Paths → Detecta servicios vulnerables a LPE
✔ Compatible con **Windows 10 y 11**  
✔ Soporta **idiomas inglés y español**  
✔ No modifica configuración del sistema  

---

## ⚙️ Configuración (`wifi_audit.ps1`)

Parámetros editables al inicio del script:

```powershell
$Mode = "AUDITORIA"            # DEMO | AUDITORIA 
$ExportCSV = $true 
$ExportPath = "$env:TEMP\\system_security_audit.csv"

```

### Modos
- DEMO: solo muestra resultados en pantalla
- AUDITORIA: exporta métricas a CSV (sin claves)

---

## 🐬 Uso con Flipper Zero (BadUSB)

El archivo 001-System_Security_Audit.txt está diseñado para:
1. Abrir cmd
2. Descargar el script desde GitHub (raw)
3. Ejecutarlo con PowerShell y mostrar en pantalla
4. Eliminar el archivo descargado

---

## 🛡️ Consideraciones de seguridad

Algunos antivirus pueden marcar el script por:
-> Uso de netsh
-> Ejecución remota
-> Comportamiento tipo auditoría

Esto es esperado en herramientas defensivas.
No hay persistencia, exfiltración ni modificación del sistema.

---

## ⚠️ Disclaimer legal

Este proyecto es educativo y defensivo.
El autor no se hace responsable del uso indebido.

Ejecutar únicamente:
- En equipos propios
- En entornos de laboratorio
- Con autorización explícita