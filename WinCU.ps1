# =========================
# Verificación de módulo
# =========================

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

function Write-LogMessage {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [ValidateSet(
      'info',
      'Info',
      'INFO',
      'success',
      'Success',
      'SUCCESS',
      'error',
      'Error',
      'ERROR',
      'warning',
      'Warning',
      'WARNING',
      'question',
      'Question',
      'QUESTION'
    )]
    [string] $Type,

    [Parameter(Mandatory)]
    [object] $Message
  )

  $typeConfig = @{
    info     = @{
      Label        = 'INFO'
      BracketColor = 'DarkGray'
      LabelColor   = 'Cyan'
    }
    success  = @{
      Label        = 'SUCCESS'
      BracketColor = 'DarkGray'
      LabelColor   = 'Green'
    }
    error    = @{
      Label        = 'ERROR'
      BracketColor = 'DarkGray'
      LabelColor   = 'Red'
    }
    warning  = @{
      Label        = 'WARNING'
      BracketColor = 'DarkGray'
      LabelColor   = 'Yellow'
    }
    question = @{
      Label        = 'QUESTION'
      BracketColor = 'DarkGray'
      LabelColor   = 'Magenta'
    }
  }

  $cfg = $typeConfig[$Type]

  # Prefijo [ INFO ]
  Write-Color `
    -Text '[', $cfg.Label, ']' `
    -Color $cfg.BracketColor, $cfg.LabelColor, $cfg.BracketColor `
    -NoNewLine

  Write-Color -Text ' ' -NoNewLine

  # Mensaje
  if ($Message -is [array]) {
    Write-Color -Text $Message
  }
  else {
    Write-Color -Text $Message -Color White -LinesAfter 1
  }
}

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

function Invoke-SystemRevert {
  $needsReboot = $false

  Write-LogMessage -Type info -Message 'Iniciando protocolo de reversión del sistema...'

  # =========================
  # MPO (DWM)
  # =========================
  Write-LogMessage -Type info -Message 'Restaurando configuración DWM (MPO)...'

  $mpoKey = 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm'

  if (Test-Path $mpoKey) {
    try {
      Remove-ItemProperty -Path $mpoKey -Name 'OverlayTestMode' -ErrorAction Stop
      Write-LogMessage -Type success -Message 'MPO restaurado a valores por defecto.'
      $needsReboot = $true
    }
    catch {
      Write-LogMessage -Type info -Message 'No se encontró OverlayTestMode o ya estaba en default.'
    }
  }

  # =========================
  # BCD TIMERS
  # =========================
  Write-LogMessage -Type info -Message 'Limpiando BCD Timers...'

  function Remove-BcdValue {
    param (
      [string]$Value,
      [string]$Label
    )

    bcdedit /deletevalue $Value 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
      Write-LogMessage -Type success -Message $Label
      $script:needsReboot = $true
    }
  }

  Remove-BcdValue -Value 'useplatformtick'    -Label 'PlatformTick eliminado (Default).'
  Remove-BcdValue -Value 'disabledynamictick' -Label 'DynamicTick restaurado.'
  Remove-BcdValue -Value 'tscsyncpolicy'      -Label 'TSCSyncPolicy restaurado.'

  # =========================
  # MEMORY MANAGEMENT
  # =========================
  Write-LogMessage -Type info -Message 'Restaurando Memory Management...'

  $mmKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'

  try {
    New-ItemProperty `
      -Path $mmKey `
      -Name 'DisablePagingExecutive' `
      -PropertyType DWord `
      -Value 0 `
      -Force | Out-Null

    Write-LogMessage -Type success -Message 'Paging Executive reactivado (Default = 0).'
    $needsReboot = $true
  }
  catch {
    Write-LogMessage -Type error -Message 'Error restaurando Memory Management.'
  }

  Start-Sleep 1
  Invoke-Reboot -NeedsReboot $needsReboot
}

function Remove-CopilotGameBar {
  $needsReboot = $false
  # =========================
  # Xbox Game Bar (opcional)
  # =========================
  Write-LogMessage -Type question -Message @(
    'Quieres eliminar tambien la XBOX GAME BAR ',
    '[S,N]? '
  )

  cmd /c choice /c SN /n > $null
  $removeGameBar = $LASTEXITCODE

  if ($removeGameBar -eq 1) {
    Write-LogMessage -Type info -Message "Matando procesos de Game Bar..."

    taskkill /f /im GameBar.exe 2>$null
    taskkill /f /im GameBarFT.exe 2>$null

    Write-LogMessage -Type info -Message "Eliminando Xbox Game Bar..."
    Get-AppxPackage -AllUsers Microsoft.XboxGamingOverlay |
    Remove-AppxPackage -ErrorAction SilentlyContinue

    Get-AppxPackage XboxGamingOverlay |
    Reset-AppxPackage -ErrorAction SilentlyContinue

    reg add HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR /v AppCaptureEnabled /t REG_DWORD /d 0 /f  | Out-Null
    reg add HKEY_CURRENT_USER\System\GameConfigStore /v GameDVR_Enabled /t REG_DWORD /d 0 /f | Out-Null

    $needsReboot = $true
  }

  # =========================
  # Copilot
  # =========================
  Write-LogMessage -Type info -Message "Iniciando protocolo Anti Copilot..."

  try {
    Get-AppxPackage -AllUsers Microsoft.Windows.Ai.Copilot.Provider | Remove-AppxPackage -ErrorAction Stop
    Write-LogMessage -Type success -Message "Copilot Provider eliminado."
    $needsReboot = $true
  }
  catch {
    Write-LogMessage -Type info -Message (
      "Variante principal no encontrada.", "Probando barrido..."
    )
  }

  Get-AppxPackage -AllUsers *Copilot* |
  Remove-AppxPackage -ErrorAction SilentlyContinue

  Get-AppxPackage -AllUsers *BingChat* |
  Remove-AppxPackage -ErrorAction SilentlyContinue

  $needsReboot = $true

  # =========================
  # Políticas de bloqueo
  # =========================
  Write-LogMessage -Type info -Message 'Aplicando candado en Registro (Policy)...'

  reg add HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f | Out-Null
  reg add HKLM\Software\Policies\Microsoft\Windows\WindowsCopilot /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f | Out-Null

  Write-LogMessage -Type success -Message "Proceso terminado"

  $needsReboot = $true
  Start-Sleep 2
  Invoke-Reboot -NeedsReboot $needsReboot
}

function Invoke-GpuCacheCleanup {
  # --- LIMPIEZA DIRECTX ---
  Write-LogMessage -Type info -Message 'Limpiando cache DirectX...'

  $dxCache = Join-Path $env:LOCALAPPDATA 'D3DSCache'
  $nvidiaGl = Join-Path $env:LOCALAPPDATA 'NVIDIA\GLCache'
  $nvidiaNv = Join-Path $env:PROGRAMDATA 'NVIDIA Corporation\NV_Cache'
  $amdCache = Join-Path $env:LOCALAPPDATA 'AMD\DxCache'

  if (Test-Path $dxCache) {
    Get-ChildItem -Path $dxCache -Recurse -Force -ErrorAction SilentlyContinue |
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
  }

  # --- LIMPIEZA NVIDIA ---
  Write-LogMessage -Type info -Message 'Buscando cache Nvidia...'

  if (Test-Path $nvidiaGl) {
    Get-ChildItem $nvidiaGl -Recurse -Force -ErrorAction SilentlyContinue |
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
  }

  if (Test-Path $nvidiaNv) {
    Get-ChildItem $nvidiaNv -Recurse -Force -ErrorAction SilentlyContinue |
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
  }

  # --- LIMPIEZA AMD ---
  Write-LogMessage -Type info -Message 'Buscando cache AMD...'

  if (Test-Path $amdCache) {
    Get-ChildItem $amdCache -Recurse -Force -ErrorAction SilentlyContinue |
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
  }
}

# =========================
# Menú principal
# =========================
function Set-ScriptMain {
  do {
    Write-Color $line -Color Yellow -LinesBefore 1
    Write-Color 'WinCU - OCTAEDLP (Windows Cleanup Utility)' -Color Cyan -StartTab 1
    Write-Color $line -Color Yellow
    Write-Color ' 0', ' - ', 'Salir' -Color Yellow, White, Green
    Write-Color ' 1', ' - ', 'Eliminar Copilot (OPCIONAL GAMEBAR)' -Color Yellow, White, Green
    Write-Color ' 2', ' - ', 'GPU Cleaner' -Color Yellow, White, Green
    Write-Color ' 3', ' - ', 'Revertir Timers / MPO / Memory (DEFAULT)' -Color Yellow, White, Green
    Write-Color $line -Color Yellow

    $inputData = Read-Host 'Selecciona una opcion'

    switch ($inputData) {
      '0' {
        Write-Color "Saliendo..." -Color Gray
        Exit 0
      }
      '1' { Remove-CopilotGameBar }
      '2' { Invoke-GpuCacheCleanup }
      '3' { Invoke-SystemRevert }
      default {
        Write-Color 'Opción ', "$inputData", ' inválida.' -Color Red, Yellow, Red -LinesBefore 1
        [void][System.Console]::ReadKey($true)
        Exit -1
      }
    }
  } while ($true)
}

Set-ScriptMain
