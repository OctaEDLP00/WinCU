# =========================
# 1. Configuración Inicial
# =========================
Add-Type -AssemblyName PresentationFramework, System.Drawing, System.Windows.Forms

$version = "1.0.0"
$author = "OctaEDLP00"

# =========================
# 2. Definición de la Interfaz (XAML)
# =========================
[xml]$xaml = @"
<Window
  xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
  xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
  Title="WinCU UI | Windows Command Utility v${version}"
  Height="500" Width="700"
  WindowStartupLocation="CenterScreen"
  Background="#1E1E1E" Foreground="#FFFFFF"
  FontFamily="Segoe UI"
>
  <Window.Resources>
    <Style TargetType="Button">
      <Setter
        Property="Background"
        Value="#018574"
      />
      <Setter
        Property="Foreground"
        Value="#FFFFFF"
      />
      <Setter
        Property="FontWeight"
        Value="Bold"
      />
      <Setter
        Property="Padding"
        Value="10,5"
      />
      <Setter
        Property="Margin"
        Value="5"
      />
      <Setter
        Property="Template"
      >
        <Setter.Value>
          <ControlTemplate
            TargetType="Button"
          >
            <Border
              Background="{TemplateBinding Background}"
              CornerRadius="5"
            >
              <ContentPresenter
                HorizontalAlignment="Center"
                VerticalAlignment="Center"
              />
            </Border>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style TargetType="ComboBox">
      <Setter
        Property="Padding"
        Value="5"
      />
    </Style>
  </Window.Resources>
  <Grid Margin="20">
    <Grid.RowDefinitions>
      <RowDefinition
        Height="Auto"
      />
      <RowDefinition
        Height="Auto"
      />
      <RowDefinition
        Height="Auto"
      />
      <RowDefinition
        Height="*"
      />
      <RowDefinition
        Height="Auto"
      />
    </Grid.RowDefinitions>
    <TextBlock
      Grid.Row="0"
      Text="WinCU - Mantenimiento del Sistema"
      FontSize="20"
      FontWeight="Bold"
      Foreground="#018574"
      HorizontalAlignment="Center"
      Margin="0,0,0,20"
    />
    <StackPanel
      Grid.Row="1"
      Orientation="Vertical"
      HorizontalAlignment="Center"
    >
      <TextBlock
        Text="Selecciona una acción:"
        Foreground="LightGray"
        Margin="0,0,0,5"
      />
      <ComboBox
        x:Name="CmbActions"
        Width="400"
        Height="35"
        FontSize="14"
      >
        <ComboBoxItem
          Content="Selecciona una opción..."
          Tag="None" IsSelected="True"
          Foreground="Gray"
        />
        <ComboBoxItem
          Content="Eliminar Copilot (Anti-Bloat)"
          Tag="Copilot"
        />
        <ComboBoxItem
          Content="GPU Cleaner (Cache)"
          Tag="GPU"
        />
        <ComboBoxItem
          Content="Revertir Sistema (Timers/MPO/Mem)"
          Tag="Revert"
        />
      </ComboBox>
      <CheckBox
        x:Name="ChkGameBar"
        Content="Incluir eliminación de Xbox Game Bar"
        Foreground="#018574"
        Margin="0,10,0,0"
        IsChecked="False"
        Visibility="Collapsed"
      />
    </StackPanel>
    <Button
      x:Name="BtnRun"
      Grid.Row="2"
      Content="EJECUTAR TAREA"
      Width="200"
      Height="40"
      Margin="0,20,0,10"
      Cursor="Hand"
    />
    <Border
      Grid.Row="3"
      BorderBrush="#333333"
      BorderThickness="1"
      Background="#111111"
      CornerRadius="5"
    >
      <ScrollViewer
        x:Name="LogScroller"
        VerticalScrollBarVisibility="Auto"
      >
        <TextBlock
          x:Name="TxtLog"
          TextWrapping="Wrap"
          Padding="10"
          FontFamily="Consolas"
          FontSize="12"
        />
      </ScrollViewer>
    </Border>
    <TextBlock
      Grid.Row="4"
      Foreground="Gray"
      FontSize="10"
      HorizontalAlignment="Right"
      Margin="0,5,0,0"
    >
      <Run Text="Developed by " />
      <Hyperlink
        x:Name="AuthorLink"
        NavigateUri="https://github.com/$author"
      >
        <Run Text="${author}" />
      </Hyperlink>
    </TextBlock>
  </Grid>
</Window>
"@

# =========================
# 3. Carga del XAML
# =========================
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Mapeo automático de variables (CmbActions, BtnRun, TxtLog, etc.)
$xaml.SelectNodes("//*[@Name]") | ForEach-Object {
  Set-Variable -Name $_.Name -Value $window.FindName($_.Name) -Scope Script
}

# =========================
# 4. Funciones de Utilidad UI
# =========================

# Función para escribir en el TextBox de la GUI en lugar de la consola
function Write-GuiLog {
  param(
    [string]$Message,
    [string]$Color = "White", # White, Green, Yellow, Red
    [switch]$Bold
  )

  # Necesitamos usar el Dispatcher para actualizar la UI desde hilos si fuera necesario
  $window.Dispatcher.Invoke({
      $run = New-Object System.Windows.Documents.Run
      $run.Text = "$([DateTime]::Now.ToString('HH:mm:ss')) > $Message`n"

      switch ($Color) {
        "Green" {
          $run.Foreground = [System.Windows.Media.Brushes]::LightGreen
        }
        "Yellow" {
          $run.Foreground = [System.Windows.Media.Brushes]::Gold
        }
        "Red" {
          $run.Foreground = [System.Windows.Media.Brushes]::Tomato
        }
        "Cyan" {
          $run.Foreground = [System.Windows.Media.Brushes]::Cyan
        }
        default {
          $run.Foreground = [System.Windows.Media.Brushes]::LightGray
        }
      }

      if ($Bold) {
        $run.FontWeight = "Bold"
      }

      $TxtLog.Inlines.Add($run)
      $LogScroller.ScrollToBottom()
    })
  # Pequeña pausa para que la UI no se congele visualmente en bucles rápidos
  [System.Windows.Forms.Application]::DoEvents()
}

# Función para solicitar reinicio estilo Windows
function Request-Reboot {
  $result = [System.Windows.MessageBox]::Show("Se requieren cambios críticos.`n¿Desea reiniciar el sistema ahora?", "Reinicio Requerido", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
  if ($result -eq 'Yes') {
    Write-GuiLog "Reiniciando sistema..." "Red" -Bold
    Start-Sleep 2
    Restart-Computer -Force
  }
  else {
    Write-GuiLog "Reinicio pospuesto por el usuario." "Yellow"
  }
}

# =========================
# 5. Lógica de Negocio (Adaptada de WinCU.ps1)
# =========================

function Invoke-SystemRevert {
  Write-GuiLog "=== Iniciando Reversión del Sistema ===" "Cyan" -Bold
  $needsReboot = $false

  # MPO
  $mpoKey = 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm'
  if (Test-Path $mpoKey) {
    try {
      Remove-ItemProperty -Path $mpoKey -Name 'OverlayTestMode' -ErrorAction Stop
      Write-GuiLog "MPO restaurado a valores por defecto." "Green"
      $needsReboot = $true
    }
    catch {
      Write-GuiLog "MPO ya estaba en default."
    }
  }

  # BCD
  Write-GuiLog "Limpiando BCD Timers..."
  $bcdActions = @(
    @{ Val = 'useplatformtick'; Label = 'PlatformTick eliminado' },
    @{ Val = 'disabledynamictick'; Label = 'DynamicTick restaurado' },
    @{ Val = 'tscsyncpolicy'; Label = 'TSCSyncPolicy restaurado' }
  )

  foreach ($item in $bcdActions) {
    bcdedit /deletevalue $item.Val 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
      Write-GuiLog $item.Label "Green"
      $needsReboot = $true
    }
  }

  # Memory
  try {
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'DisablePagingExecutive' -Value 0 -Force
    Write-GuiLog "Paging Executive reactivado (0)." "Green"
    $needsReboot = $true
  }
  catch {
    Write-GuiLog "Error accediendo al registro de memoria." "Red"
  }

  if ($needsReboot) {
    Request-Reboot
  }
  else {
    Write-GuiLog "No se requieren reinicios." "Green"
  }
}

function Remove-CopilotGameBar {
  Write-GuiLog "=== Iniciando Limpieza Bloatware ===" "Cyan" -Bold
  $needsReboot = $false

  # Verificar Checkbox de la GUI para GameBar
  if ($ChkGameBar.IsChecked) {
    Write-GuiLog "Eliminando Xbox Game Bar..." "Yellow"
    taskkill /f /im GameBar.exe 2>$null
    taskkill /f /im GameBarFT.exe 2>$null

    Get-AppxPackage -AllUsers Microsoft.XboxGamingOverlay | Remove-AppxPackage -ErrorAction SilentlyContinue
    Get-AppxPackage XboxGamingOverlay | Reset-AppxPackage -ErrorAction SilentlyContinue

    # Reg keys
    reg add HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR /v AppCaptureEnabled /t REG_DWORD /d 0 /f | Out-Null

    Write-GuiLog "Xbox Game Bar eliminada/desactivada." "Green"
    $needsReboot = $true
  }

  # Copilot
  Write-GuiLog "Eliminando Copilot..."
  try {
    Get-AppxPackage -AllUsers Microsoft.Windows.Ai.Copilot.Provider | Remove-AppxPackage -ErrorAction Stop
    Write-GuiLog "Copilot Provider eliminado." "Green"
    $needsReboot = $true
  }
  catch {
    Write-GuiLog "Copilot Provider no encontrado, intentando barrido general..." "Yellow"
  }

  Get-AppxPackage -AllUsers *Copilot* | Remove-AppxPackage -ErrorAction SilentlyContinue
  Get-AppxPackage -AllUsers *BingChat* | Remove-AppxPackage -ErrorAction SilentlyContinue

  # Reg Policies
  Write-GuiLog "Aplicando políticas de bloqueo en registro..."
  reg add HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f | Out-Null
  reg add HKLM\Software\Policies\Microsoft\Windows\WindowsCopilot /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f | Out-Null

  Write-GuiLog "Proceso de limpieza finalizado." "Green" -Bold
  if ($needsReboot) {
    Request-Reboot
  }
}

function Invoke-GpuCacheCleanup {
  Write-GuiLog "=== Iniciando Limpieza de Caché GPU ===" "Cyan" -Bold

  $paths = @(
    Join-Path $env:LOCALAPPDATA 'D3DSCache'
    Join-Path $env:LOCALAPPDATA 'NVIDIA\GLCache'
    Join-Path $env:PROGRAMDATA 'NVIDIA Corporation\NV_Cache'
    Join-Path $env:LOCALAPPDATA 'AMD\DxCache'
  )

  foreach ($path in $paths) {
    if (Test-Path $path) {
      Write-GuiLog "Limpiando: $path"
      Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
      Write-GuiLog "Limpio." "Green"
    }
  }
  Write-GuiLog "Limpieza de caché finalizada." "Green" -Bold
}

# =========================
# 6. Eventos de la Interfaz
# =========================

$AuthorLink = $window.FindName("AuthorLink")
# $RepoLink = $window.FindName("RepoLink")
$BtnRun = $window.FindName("BtnRun")
$CmbActions = $window.FindName("CmbActions")
$ChkGameBar = $window.FindName("ChkGameBar")
$LogScroller = $window.FindName("LogScroller")
$TxtLog = $window.FindName("TxtLog")

# Write-Host $AuthorLink
$AuthorLink.Add_RequestNavigate({
    param($senderLink, $e)

    if ($e.Uri) {
      Start-Process $e.Uri.AbsoluteUri
      $e.Handled = $true
    }
  })
<#
$RepoLink.Add_RequestNavigate({
  param($senderLink, $e)

  if ($e.Uri) {
    Start-Process $e.Uri.AbsoluteUri
    $e.Handled = $true
  }
})
#>

# Evento: Cambio de selección en el ComboBox
# Write-Host $CmbActions
$CmbActions.Add_SelectionChanged({
    param($senderCombo, $e)
    if ($CmbActions.SelectedItem.Tag -eq "Copilot") {
      $ChkGameBar.Visibility = "Visible"
    }
    else {
      $ChkGameBar.Visibility = "Collapsed"
      $ChkGameBar.IsChecked = $false
    }
  })

# Evento: Click en el botón Ejecutar
# Write-Host $BtnRun
$BtnRun.Add_Click({
    $selectedItem = [System.Windows.Controls.ComboBoxItem]$CmbActions.SelectedItem
    $tag = $selectedItem.Tag

    # Validar si no hay selección O si la selección es el placeholder "None"
    if (-not $selectedItem -or $tag -eq "None") {
      Write-GuiLog "⚠ Por favor selecciona una opción válida del menú." "Yellow"
      return
    }

    # Deshabilitar botón para evitar doble click
    $BtnRun.IsEnabled = $false
    $BtnRun.Content = "Ejecutando..."

    # Ejecutar la lógica correspondiente
    switch ($tag) {
      "Copilot" {
        Remove-CopilotGameBar
      }
      "GPU" {
        Invoke-GpuCacheCleanup
      }
      "Revert" {
        Invoke-SystemRevert
      }
      default {
        Write-GuiLog "Opción no reconocida: $tag" "Red"
      }
    }

    # Reactivar botón
    $BtnRun.IsEnabled = $true
    $BtnRun.Content = "EJECUTAR TAREA"

  })

# =========================
# 7. Mostrar Ventana
# =========================
Write-Host "Cargando Interfaz WinCU..."
$window.ShowDialog() | Out-Null
