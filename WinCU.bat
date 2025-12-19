<# :
@echo off
:: =========================================================
::            DON PAQUITO TV
:: =========================================================
title SYSTEM UNLOCKER - INICIANDO...
color 0b
cd /d "%~dp0"

:: 1. COMPROBAR SI SOMOS ADMIN
net session >nul 2>&1
if %errorLevel% neq 0 (
  echo [!] SOLICITANDO PERMISOS DE ADMINISTRADOR...
  powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  if %errorLevel% neq 0 (
    color 0c
    echo.
    echo [X] ERROR: NO SE PUDIERON OBTENER PERMISOS O CANCELASTE.
    echo.
    pause
  )
  exit /b
)

:: 2. PREPARAR EL SCRIPT H�BRIDO
echo [*] CARGANDO MODULO POWERSHELL...
set "PS_SCRIPT=%temp%\temp_script_%random%.ps1"
copy /y "%~f0" "%PS_SCRIPT%" >nul

:: 3. EJECUTAR (CON PAUSA SI FALLA)
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"

:: SI LLEGA AQUI Y HUBO ERROR, AVISAR
if %errorLevel% neq 0 (
  color 0c
  echo.
  echo [!] EL SCRIPT FALLO CON ERROR %errorLevel%.
  echo.
  pause
)

:: 4. LIMPIEZA
del "%PS_SCRIPT%" >nul 2>&1
exit /b
#>

# ========================
# Colores para mensajes
# ========================
# Yellow -> Question
# Green -> Success
# Red -> Error
# Gray -> Text/Msg
# Blue -> Info
# ========================

# =========================================================
# ZONA SEGURA DE POWERSHELL
# =========================================================

# Funcionalidad de WriteColor sacada de https://github.com/EvotecIT/PSWriteColor
function Write-Color {
  [alias('Write-Colour')]
  [CmdletBinding()]
  param (
      [alias ('T')] [String[]]$Text,
      [alias ('C', 'ForegroundColor', 'FGC')] [ConsoleColor[]]$Color = [ConsoleColor]::White,
      [alias ('B', 'BGC')] [ConsoleColor[]]$BackGroundColor = $null,
      [alias ('Indent')][int] $StartTab = 0,
      [int] $LinesBefore = 0,
      [int] $LinesAfter = 0,
      [int] $StartSpaces = 0,
      [alias ('L')] [string] $LogFile = '',
      [Alias('DateFormat', 'TimeFormat')][string] $DateTimeFormat = 'yyyy-MM-dd HH:mm:ss',
      [alias ('LogTimeStamp')][bool] $LogTime = $true,
      [int] $LogRetry = 2,
      [ValidateSet('unknown', 'string', 'unicode', 'bigendianunicode', 'utf8', 'utf7', 'utf32', 'ascii', 'default', 'oem')][string]$Encoding = 'Unicode',
      [switch] $ShowTime,
      [switch] $NoNewLine,
      [switch] $HorizontalCenter,
      [alias('HideConsole')][switch] $NoConsoleOutput
  )
  if (-not $NoConsoleOutput) {
    $DefaultColor = $Color[0]
    if ($null -ne $BackGroundColor -and $BackGroundColor.Count -ne $Color.Count) {
      Write-Error "Colors, BackGroundColors parameters count doesn't match. Terminated."
      return
    }
    if ($LinesBefore -ne 0) { for ($i = 0; $i -lt $LinesBefore; $i++) { Write-Host -Object "`n" -NoNewline } } # Add empty line before
    if ($HorizontalCenter) {
      $MessageLength = 0
      foreach ($Value in $Text) {
        $MessageLength += $Value.Length
      }

      $WindowWidth = $Host.UI.RawUI.BufferSize.Width
      $CenterPosition = [Math]::Max(0, $WindowWidth / 2 - [Math]::Floor($MessageLength / 2))

      # Only write spaces to the console if window width is greater than the message length
      if ($WindowWidth -ge $MessageLength) {
        Write-Host ("{0}" -f (' ' * $CenterPosition)) -NoNewline
      }
    } # Center the line horizontally according to the powershell window size
    if ($StartTab -ne 0) { for ($i = 0; $i -lt $StartTab; $i++) { Write-Host -Object "`t" -NoNewline } }  # Add TABS before text
    if ($StartSpaces -ne 0) { for ($i = 0; $i -lt $StartSpaces; $i++) { Write-Host -Object ' ' -NoNewline } }  # Add SPACES before text
    if ($ShowTime) { Write-Host -Object "[$([datetime]::Now.ToString($DateTimeFormat))] " -NoNewline } # Add Time before output
    if ($Text.Count -ne 0) {
      if ($Color.Count -ge $Text.Count) {
        # the real deal coloring
        if ($null -eq $BackGroundColor) {
          for ($i = 0; $i -lt $Text.Length; $i++) { Write-Host -Object $Text[$i] -ForegroundColor $Color[$i] -NoNewline }
        } else {
          for ($i = 0; $i -lt $Text.Length; $i++) { Write-Host -Object $Text[$i] -ForegroundColor $Color[$i] -BackgroundColor $BackGroundColor[$i] -NoNewline }
        }
      } else {
        if ($null -eq $BackGroundColor) {
          for ($i = 0; $i -lt $Color.Length ; $i++) { Write-Host -Object $Text[$i] -ForegroundColor $Color[$i] -NoNewline }
          for ($i = $Color.Length; $i -lt $Text.Length; $i++) { Write-Host -Object $Text[$i] -ForegroundColor $DefaultColor -NoNewline }
        } else {
          for ($i = 0; $i -lt $Color.Length ; $i++) { Write-Host -Object $Text[$i] -ForegroundColor $Color[$i] -BackgroundColor $BackGroundColor[$i] -NoNewline }
          for ($i = $Color.Length; $i -lt $Text.Length; $i++) { Write-Host -Object $Text[$i] -ForegroundColor $DefaultColor -BackgroundColor $BackGroundColor[0] -NoNewline }
        }
      }
    }
    if ($NoNewLine -eq $true) { Write-Host -NoNewline } else { Write-Host } # Support for no new line
    if ($LinesAfter -ne 0) { for ($i = 0; $i -lt $LinesAfter; $i++) { Write-Host -Object "`n" -NoNewline } }  # Add empty line after
  }
  if ($Text.Count -and $LogFile) {
    # Save to file
    $TextToFile = ""
    for ($i = 0; $i -lt $Text.Length; $i++) {
      $TextToFile += $Text[$i]
    }
    $Saved = $false
    $Retry = 0
    do {
      $Retry++
      try {
        if ($LogTime) {
          "[$([datetime]::Now.ToString($DateTimeFormat))] $TextToFile" | Out-File -FilePath $LogFile -Encoding $Encoding -Append -ErrorAction Stop -WhatIf:$false
        } else {
          "$TextToFile" | Out-File -FilePath $LogFile -Encoding $Encoding -Append -ErrorAction Stop -WhatIf:$false
        }
        $Saved = $true
      } catch {
        if ($Saved -eq $false -and $Retry -eq $LogRetry) {
          Write-Warning "Write-Color - Couldn't write to log file $($_.Exception.Message). Tried ($Retry/$LogRetry))"
        } else {
          Write-Warning "Write-Color - Couldn't write to log file $($_.Exception.Message). Retrying... ($Retry/$LogRetry)"
        }
      }
    } until ($Saved -eq $true -or $Retry -ge $LogRetry)
  }
}

# =========================
# Utilidades
# =========================
$line = '========================================================='

function Invoke-Reboot {
  param (
    [bool]$NeedsReboot
  )

  if (-not $NeedsReboot) {
    Write-Color "`nNo se requieren cambios criticos. Reinicio no necesario." -Color Gray -LinesAfter 1
    Start-Sleep 1
    return
  }

  Write-Color $line -Color Yellow -LinesBefore 1
  Write-Color 'WinCU - OCTAEDLP (Windows Cleanup Utility)' -Color Cyan -StartTab 1
  Write-Color "ES NECESARIO REINICIAR PARA APLICAR CAMBIOS" -Color Yellow -StartTab 1
  Write-Color $line -Color Yellow
  Write-Color ' 1', ' - ', 'Reiniciar ahora' -Color Yellow, White, Green
  Write-Color ' 2', ' - ', 'Reiniciar más tarde' -Color Yellow, White, Green
  Write-Color $line -Color Yellow

  $choice = Read-Host 'Selecciona una opcion'

  switch ($choice) {
    '1' {
      Write-Color "Reiniciando..." -Color Blue
      Start-Sleep 2
      Restart-Computer -Force
    }
    '2' {
      Write-Color "`nReinicio omitido. Puedes hacerlo más tarde." -Color Blue -LinesAfter 1
      Start-Sleep 1
      Exit
    }
    default {
      Write-Color 'Opción ', "$choice", ' inválida.' -Color Red, Yellow, Red -LinesBefore 1
      if (-not ($choice -eq '1' -or $choice -eq '2')) {
        Invoke-Reboot -NeedsReboot $true
      }
      [void][System.Console]::ReadKey($true)
    }
  }
}

# =========================
# Funciones
# =========================

function Remove-CopilotGameBar {
  $needsReboot = $false
  # =========================
  # Xbox Game Bar (opcional)
  # =========================
  Write-Color "`nQuieres eliminar tambien la XBOX GAME BAR?", " (s/n)" -Color Yellow, Gray
  $removeGameBar = Read-Host

  if ($removeGameBar -eq 'y') {
    Write-Color "[*] Matando procesos de Game Bar..." -Color Yellow

    taskkill /f /im GameBar.exe 2>$null
    taskkill /f /im GameBarFT.exe 2>$null

    Write-Color "[-] Eliminando Xbox Game Bar..." -Color Green
    Get-AppxPackage -AllUsers Microsoft.XboxGamingOverlay |
    Remove-AppxPackage -ErrorAction SilentlyContinue

    Get-AppxPackage XboxGamingOverlay |
    Reset-AppxPackage -ErrorAction SilentlyContinue

    $needsReboot = $true
  }

  # =========================
  # Copilot
  # =========================
  Write-Color "`n[*] ", "Iniciando protocolo Anti Copilot..." -Color Cyan, Gray

  try {
    Get-AppxPackage -AllUsers Microsoft.Windows.Ai.Copilot.Provider | Remove-AppxPackage -ErrorAction Stop

    Write-Color "[OK] ", "Copilot Provider eliminado." -Color Green, Gray

    $needsReboot = $true
  }
  catch {
    Write-Color "[!]", "Variante principal no encontrada.", "Probando barrido...", -Color Red, Red, Gray
  }

  Get-AppxPackage -AllUsers *Copilot* |
  Remove-AppxPackage -ErrorAction SilentlyContinue

  Get-AppxPackage -AllUsers *BingChat* |
  Remove-AppxPackage -ErrorAction SilentlyContinue

  $needsReboot = $true

  # =========================
  # Políticas de bloqueo
  # =========================
  Write-Color '[*]', ' Aplicando candado en Registro (Policy)...' -Color Cyan, Gray

  reg add HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f | Out-Null
  reg add HKLM\Software\Policies\Microsoft\Windows\WindowsCopilot /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f | Out-Null

  Write-Color "`n[OK] ", "PROCESO TERMINADO." -Color Green, Gray

  $needsReboot = $true
  Start-Sleep 2
  Invoke-Reboot -NeedsReboot $needsReboot
}

# =========================
# Menú principal
# =========================
function Set-ScriptMain {
  do {
    Clear-Host
    Write-Color $line -Color Yellow -LinesBefore 1
    Write-Color 'WinCU - OCTAEDLP (Windows Cleanup Utility)' -Color Cyan -StartTab 1
    Write-Color $line -Color Yellow
    Write-Color ' 0', ' - ', 'Salir' -Color Yellow, White, Green
    Write-Color ' 1', ' - ', 'Eliminar Copilot (OPCIONAL GAMEBAR)' -Color Yellow, White, Green
    Write-Color $line -Color Yellow

    $inputData = Read-Host 'Selecciona una opcion'

    switch ($inputData) {
      '0' {
        Write-Color "Saliendo..." -Color Gray
        Exit 0
      }
      '1' { Remove-CopilotGameBar }
      default {
        Write-Color 'Opción ', "$inputData", ' inválida.' -Color Red, Yellow, Red -LinesBefore 1
        [void][System.Console]::ReadKey($true)
        Exit -1
      }
    }
  } while ($true)
}

Set-ScriptMain
