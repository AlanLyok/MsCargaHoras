[CmdletBinding()]
param(
  [Parameter(Position=0)]
  [string]$Configuration = 'Debug',
  [Parameter(Position=1)]
  [int]$Port = 58755,
  [switch]$OpenBrowser
)

$ErrorActionPreference = 'Stop'

$Configuration = if ([string]::IsNullOrWhiteSpace($Configuration)) { 'Debug' } else { $Configuration }
if ($Configuration -like '*;*') { $Configuration = ($Configuration.Split(';')[0]).Trim() }
if ($Configuration -notin @('Debug','Release')) { $Configuration = 'Debug' }

if (-not $PSBoundParameters.ContainsKey('OpenBrowser')) { $OpenBrowser = $true }

$root = $PSScriptRoot
$buildScript = Join-Path $root 'NuevoCodigo_MSCargaHoras\scripts\Build-Run-MsCargaHoras.ps1'
if (-not (Test-Path -LiteralPath $buildScript)) { throw "No se encontró: $buildScript" }

# 1) Asegurar que instancias previas estén cerradas
try {
  # IIS Express
  Get-Process iisexpress -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
  # Watchers anteriores de este proyecto
  $procList = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -like "*Build-Run-MsCargaHoras.ps1*" -and $_.CommandLine -like "*-Watch*"
  }
  foreach ($p in $procList) { try { Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue } catch {} }
} catch {}

# 2) Compilar y (si compila) levantar IIS Express (abrir navegador si se solicita)
$args = @('-Configuration', $Configuration, '-Port', $Port.ToString(), '-KillExisting', '-AutoFix', '-MaxAttempts', '3')
if ($OpenBrowser) { $args += '-OpenBrowser' }

$buildSucceeded = $false
try {
  & $buildScript @args
  if ($LASTEXITCODE -eq 0 -or $?) { $buildSucceeded = $true }
} catch {
  Write-Host "Build fallido. No se iniciará IIS ni el watcher. Revisa el log en NuevoCodigo_MSCargaHoras\\scripts\\msbuild-last.log" -ForegroundColor Red
  exit 1
}

if (-not $buildSucceeded) {
  Write-Host "Build fallido. No se iniciará IIS ni el watcher. Revisa el log en NuevoCodigo_MSCargaHoras\\scripts\\msbuild-last.log" -ForegroundColor Red
  exit 1
}

# 3) Iniciar watcher en una nueva ventana de PowerShell reutilizando IIS (solo si el build fue exitoso)
$logPath = Join-Path $root 'NuevoCodigo_MSCargaHoras\scripts\msbuild-last.log'
$watchArgs = "-NoProfile -ExecutionPolicy Bypass -File `"$buildScript`" -Configuration `"$Configuration`" -Port $Port -ReuseIIS -Watch -AutoFix -MaxAttempts 3 -LogFile `"$logPath`""
Start-Process -FilePath powershell -ArgumentList $watchArgs

Write-Host "Watch iniciado en una nueva ventana. Puerto: http://localhost:$Port" -ForegroundColor Cyan

