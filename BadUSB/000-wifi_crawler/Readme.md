# 000 Wifi Crawler
![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue?logo=powershell)
![Windows](https://img.shields.io/badge/Windows-10%2F11-lightgrey?logo=windows)
![Security](https://img.shields.io/badge/Security-BitLocker-important?logo=microsoft)
![License: MIT](https://img.shields.io/badge/License-MIT-green)

---

## 🐼 Autor

CyberRedPanda / Hacker-Cabrónico.

Proyecto para concienciación, pentesting defensivo y formación.
---

## 📌 Descripción
Auditoría **local y de solo lectura** de perfiles WiFi almacenados en Windows, orientada a **concienciación de seguridad**, uso educativo y auditorías defensivas.

El proyecto consta de **dos componentes**:

1. Un script **PowerShell (`000-wifi_crawler.ps1`)** que analiza la fortaleza de claves WiFi guardadas.
2. Un script **BadUSB (`000-wifi_crawler.txt`)** para Flipper Zero que descarga, ejecuta y limpia el script de forma automática.

> ⚠️ **Uso ético únicamente**. Ejecutar solo en equipos propios o con autorización explícita.

---

## 📁 Estructura del proyecto

000-wifi_crawler/

├── 000-wifi_crawler.ps1 # Script principal de auditoría, se descarga del repositorio automaticamente por BadUSB

├── 000-wifi_crawler.txt # Script BadUSB instalado en un dispositvo (Flipper Zero)

└── README.md # Este archivo

---

## 🧠 ¿Qué hace el script PowerShell?

- Enumera **todos los perfiles WiFi guardados** en Windows
- Extrae la clave (si existe) usando `netsh`
- **Enmascara** la clave (nunca muestra el texto completo)
- Calcula un **score de seguridad (0–10)** basado en:
  - Longitud
  - Mayúsculas / minúsculas
  - Números
  - Símbolos
- Clasifica el nivel:
  - Nula
  - Baja
  - Media
  - Alta
- Muestra un **resumen final**
- Opcionalmente exporta métricas (modo auditoría)

✔ Compatible con **Windows 10 y 11**  
✔ Soporta **idiomas inglés y español**  
✔ No modifica configuración del sistema  

---

## ⚙️ Configuración (`wifi_audit.ps1`)

Parámetros editables al inicio del script:

```powershell
$MaskChars = 3              # Cantidad de caracteres enmascarados, minimo 1
$ShowRecommendations = $true
$Mode = "DEMO"              # DEMO | AUDITORIA
$ExportPath = "$env:TEMP\wifi_security_metrics.csv"
```

### Modos
- DEMO: solo muestra resultados en pantalla
- AUDITORIA: exporta métricas a CSV (sin claves)

---

## 🐬 Uso con Flipper Zero (BadUSB)

El archivo 000-wifi_crawler.txt está diseñado para:
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

