# =========================
# Verificación de módulo
# =========================

# ========================
# Colores para mensajes
# ========================
# Yellow -> Question
# Green -> Success
# Red -> Error
# Gray -> Text/Msg
# Blue -> Info
# ========================

$requiredModules = @(
  'PSWriteColor'
)

function Test-Modules {
  param (
    [string[]]$Modules
  )

  foreach ($module in $Modules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
      Write-Color "El módulo $module no está instalado. Instalando..." -Color Blue

      try {
        Install-Module -Name $module -Scope CurrentUser -Force -ErrorAction Stop
      }
      catch {
        Write-Color "Error instalando el módulo $module" -Color Red
        Write-Host $_.Exception.Message
        Exit 1
      }
    }

    Import-Module $module -Force
  }
}

Test-Modules -Modules $requiredModules

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
