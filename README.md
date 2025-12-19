# Script Selector -- WINCU (Windows Cleanup Utility)

Script en PowerShell para **eliminar utilidades de windows**
de forma controlada, con verificación de dependencias, opciones
interactivas y reinicio condicional.

## ⚠️ Requisitos

-  Windows 11
-  PowerShell 5.1 o superior __(Recomendado Powershell 7+)__
-  **Ejecutar como Administrador**
-  Conexión a internet (solo la primera vez, para instalar módulos)

## 📦 Dependencias

El script verifica e instala automáticamente los siguientes módulos:

-   `PSWriteColor` → salida coloreada en consola

No necesitás instalarlos manualmente.

## ▶️ Cómo ejecutar el script

1.  Abrí PowerShell **como Administrador**

2.  Si es necesario, habilitá la ejecución de scripts:

    ``` powershell
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    ```

3.  Ejecutá el script:

    ``` powershell
    .\WinCU.ps1
    ```

## 🧭 Opciones del menú

### **0 -- Salir**

Cierra el script sin hacer cambios.

### **1 -- Eliminar Copilot (y opcionalmente Xbox Game Bar)**

Esta opción realiza:

-   Eliminación de **Windows Copilot** (todas sus variantes)
-   Aplicación de **políticas de registro** para evitar reinstalación
-   Opción para eliminar **Xbox Game Bar**
    -   Cierra procesos activos (`GameBar.exe`, `GameBarFT.exe`)
    -   Limpia caché residual
-   Pregunta si querés **reiniciar ahora o más tarde**
    -   Solo se pregunta si hubo cambios reales

## 🔐 Qué cambios realiza el script

### Registro de Windows

Se agregan claves de política a nivel usuario y sistema para **bloquear
Copilot permanentemente** y evitar que vuelva tras actualizaciones de
Windows.

## 🔄 Reinicio del sistema

-   El script **NO reinicia automáticamente**
-   Solo pregunta si hubo cambios reales
-   Podés elegir reiniciar ahora o hacerlo más tarde

## ⚠️ Advertencias importantes

-   Algunas apps UWP no se pueden eliminar si están en uso
-   Se fuerzan cierres de procesos antes de desinstalar
-   Siempre es recomendable crear un punto de restauración

## ❗ Responsabilidad

Usar bajo tu propio criterio.
