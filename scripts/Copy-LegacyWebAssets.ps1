<#
Copiado de activos y páginas WebForms desde el proyecto legado a MsCargaHoras (.NET Framework 4.8)

Uso:
  1) Abrir PowerShell en la carpeta NuevoCodigo_MSCargaHoras
  2) Ejecutar:  ./scripts/Copy-LegacyWebAssets.ps1
     (o indicar rutas) ./scripts/Copy-LegacyWebAssets.ps1 -SourceRoot "C:\Sitios\FaltanteCargaHs" -TargetWeb "C:\Sitios\FaltanteCargaHs\NuevoCodigo_MSCargaHoras\MsCargaHoras"

Notas:
- Realiza respaldo previo de cada elemento destino en BKP_Migration_<timestamp> dentro del proyecto de destino.
- No modifica Web.config del destino; guarda el Web.config legado como referencia en la carpeta de backup.
#>

[CmdletBinding()]
param(
  [string]$SolutionRoot,
  [string]$SourceRoot,
  [string]$TargetWeb
)

if (-not $SolutionRoot) {
  $SolutionRoot = (Get-Item (Join-Path $PSScriptRoot '..')).FullName
}
if (-not $SourceRoot) {
  # Raíz legado: una carpeta por encima de la solución
  $SourceRoot = (Get-Item (Join-Path $SolutionRoot '..')).FullName
}
if (-not $TargetWeb) {
  $TargetWeb = (Join-Path $SolutionRoot 'MsCargaHoras')
}

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function New-BackupFolder {
  param([string]$BasePath)
  $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
  $bkp = Join-Path $BasePath ("BKP_Migration_" + $stamp)
  New-Item -Path $bkp -ItemType Directory -Force | Out-Null
  return $bkp
}

function Backup-IfExists {
  param(
    [string]$Path,
    [string]$BackupRoot
  )
  if (Test-Path $Path) {
    $name = Split-Path $Path -Leaf
    $dest = Join-Path $BackupRoot $name
    Write-Host "Respaldo: $Path -> $dest" -ForegroundColor Yellow
    Copy-Item $Path -Destination $dest -Recurse -Force
  }
}

function Copy-Dir {
  param(
    [string]$From,
    [string]$To,
    [string]$BackupRoot
  )
  if (Test-Path $From) {
    Backup-IfExists -Path $To -BackupRoot $BackupRoot
    Write-Host "Copiando carpeta: $From -> $To" -ForegroundColor Cyan
    Copy-Item $From -Destination $To -Recurse -Force
  } else {
    Write-Host "No existe origen: $From" -ForegroundColor DarkYellow
  }
}

function Copy-File {
  param(
    [string]$From,
    [string]$To,
    [string]$BackupRoot
  )
  if (Test-Path $From) {
    if (Test-Path $To) { Backup-IfExists -Path $To -BackupRoot $BackupRoot }
    Write-Host "Copiando archivo: $From -> $To" -ForegroundColor Cyan
    New-Item -ItemType Directory -Path (Split-Path $To -Parent) -Force | Out-Null
    Copy-Item $From -Destination $To -Force
  } else {
    Write-Host "No existe origen: $From" -ForegroundColor DarkYellow
  }
}

# Rutas de interés en el proyecto legado
$legacyContent = Join-Path $SourceRoot 'Content'
$legacyScripts = Join-Path $SourceRoot 'Scripts'
$legacyFonts   = Join-Path $SourceRoot 'fonts'
$legacyIcons   = Join-Path $SourceRoot 'iconos'
$legacyViews   = @(
  'Default.aspx','About.aspx','Contact.aspx',
  'Site.Master','Site.Mobile.Master','ViewSwitcher.ascx',
  'Bundle.config','favicon.ico','ApplicationInsights.config'
)

# Confirmación de carpetas
Write-Host "Origen (legado): $SourceRoot" -ForegroundColor Green
Write-Host "Destino (nuevo web): $TargetWeb" -ForegroundColor Green

if (!(Test-Path $TargetWeb)) { throw "No existe el proyecto destino: $TargetWeb" }

$backup = New-BackupFolder -BasePath $TargetWeb
Write-Host "Carpeta de respaldo: $backup" -ForegroundColor Green

# Copia de carpetas
Copy-Dir -From $legacyContent -To (Join-Path $TargetWeb 'Content') -BackupRoot $backup
Copy-Dir -From $legacyScripts -To (Join-Path $TargetWeb 'Scripts') -BackupRoot $backup
Copy-Dir -From $legacyFonts   -To (Join-Path $TargetWeb 'fonts')   -BackupRoot $backup
Copy-Dir -From $legacyIcons   -To (Join-Path $TargetWeb 'iconos')  -BackupRoot $backup

# Copia de vistas/archivos sueltos
foreach ($file in $legacyViews) {
  $from = Join-Path $SourceRoot $file
  $to   = Join-Path $TargetWeb  $file
  Copy-File -From $from -To $to -BackupRoot $backup
}

# Web.config legado como referencia (no se sobreescribe)
$legacyWebConfig = Join-Path $SourceRoot 'Web.config'
if (Test-Path $legacyWebConfig) {
  $refCopy = Join-Path $backup 'Web.config.legacy'
  Write-Host "Guardando Web.config legado en: $refCopy" -ForegroundColor Yellow
  Copy-Item $legacyWebConfig -Destination $refCopy -Force
}

Write-Host "Copiado finalizado. Revise diferencias visuales y ejecute el sitio." -ForegroundColor Green
Write-Host "Siguientes pasos sugeridos:" -ForegroundColor Green
Write-Host " - Verificar que Bundle.config contiene el bundle de estilos esperado."
Write-Host " - Si falta Application Insights, revisar el archivo copiado en la carpeta raíz del proyecto."
Write-Host " - Alinear referencias de scripts en Site.Master si fuera necesario."


