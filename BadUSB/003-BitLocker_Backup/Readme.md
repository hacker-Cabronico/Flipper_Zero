# 003 - BitLocker Recovery Keys Backup

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

Este script en PowerShell permite exportar las claves de recuperación de BitLocker de todas las unidades cifradas del equipo.El usuario puede elegir entre dos formatos de salida:
- Texto plano (legible)
- Base64 (ofuscado)

El archivo generado se guarda en el Escritorio del usuario con un nombre único que incluye la fecha y hora de la exportación.

## 🛡️ Advertencia

- La Recovery Key otorga acceso TOTAL a los datos cifrados.
- Guarde el archivo en un lugar seguro (USB externo, nube confiable).
- Elimine el archivo del Escritorio después de copiarlo a un medio seguro.
- **No comparta este archivo públicamente.**

## 🛠️ Requisitos
- Windows con BitLocker habilitado en al menos una unidad.
- Permisos de Administrador para ejecutar el script.
- PowerShell 5.1 o superior.

## ▶️ Uso

- Descargue el archivo 003-BitLocker_Backup1.ps1.
- Ejecútelo en PowerShell como Administrador.
- Confirme la operación (S para continuar).
- Seleccione el formato de exportación:
 1 → Texto plano
 2 → Base64

El script generará un archivo en el Escritorio con el nombre:
- BitLocker_RecoveryKeys_[yyyy-MM-dd_HH-mm-ss].txt

✔ Compatible con **Windows 10 y 11**  
✔ Soporta **idiomas inglés y español**  
✔ No modifica configuración del sistema  

## 📂 Ejemplo de salida

BITLOCKER RECOVERY KEYS EXPORT

Fecha: 28/01/2026 11:53:00

Equipo: MI-PC

Usuario: Erick

Formato: TEXTO PLANO

--


Unidad: C:

Estado cifrado: FullyEncrypted

Protección: On

Recovery Key ID: {12345678-ABCD-1234-ABCD-1234567890AB}

Recovery Password:

123456-789012-345678-901234-567890-123456-789012-345678

-------------------------------------------------

## 🔒 Recomendaciones

- Copie el archivo generado a un medio externo seguro.
- No deje las claves en el mismo equipo cifrado.
- Considere almacenar las claves en un gestor de contraseñas confiable.

## 📜 Licencia
- Este script se distribuye bajo la licencia MIT.
- Úselo bajo su propia responsabilidad.

##⚠️ Disclaimer legal

Este proyecto es educativo y defensivo.
El autor no se hace responsable del uso indebido.

Ejecutar únicamente:
- En equipos propios
- En entornos de laboratorio
- Con autorización explícita

