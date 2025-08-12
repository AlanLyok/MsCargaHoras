[CmdletBinding()] param(
  [string]$Configuration = "Debug",

  [int]$Port = 58755,

  [switch]$Rebuild,
  [switch]$OpenBrowser,
  [switch]$Wait,
  [switch]$KillExisting,

  # No iniciar IIS Express (sólo compilar)
  [switch]$NoRun,
  # Reutilizar IIS Express ya ejecutándose en -Port (no lanzar otra instancia)
  [switch]$ReuseIIS,
  # Vigilar cambios y recompilar automáticamente (estilo LiveServer)
  [switch]$Watch,
  # Tiempo de debounce para agrupar múltiples eventos de archivos (ms)
  [int]$DebounceMs = 600,
  # Extensiones a vigilar para recompilar
  [string[]]$WatchExtensions = @('.cs', '.csproj', '.resx', '.config'),

  # Intentar corregir errores comunes automáticamente
  [switch]$AutoFix,
  # Intentos máximos de compilar con auto-fix
  [int]$MaxAttempts = 3,
  # Ruta del log de compilación (se sobreescribe en cada intento)
  [string]$LogFile = ''
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

$Configuration = if ([string]::IsNullOrWhiteSpace($Configuration)) { 'Debug' } else { $Configuration.Trim() }
if ($Configuration -notin @('Debug','Release')) { $Configuration = 'Debug' }

function Resolve-MSBuildPath {
  $candidates = @(
    "C:\\Program Files\\Microsoft Visual Studio\\2022\\Community\\MSBuild\\Current\\Bin\\MSBuild.exe",
    "C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\Community\\MSBuild\\Current\\Bin\\MSBuild.exe",
    "C:\\Program Files\\Microsoft Visual Studio\\2019\\Community\\MSBuild\\Current\\Bin\\MSBuild.exe",
    "D:\\Program Files\\Microsoft Visual Studio\\2022\\Community\\MSBuild\\Current\\Bin\\MSBuild.exe",
    "C:\\Program Files (x86)\\Microsoft Visual Studio\\2022\\Community\\MSBuild\\Current\\Bin\\MSBuild.exe",
    "D:\\Program Files\\Microsoft Visual Studio\\2019\\Community\\MSBuild\\Current\\Bin\\MSBuild.exe",
    "D:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\Community\\MSBuild\\Current\\Bin\\MSBuild.exe"
  )

  foreach ($p in $candidates) {
    if (Test-Path -LiteralPath $p) { return $p }
  }

  $vswhere = "C:\\Program Files (x86)\\Microsoft Visual Studio\\Installer\\vswhere.exe"
  if (Test-Path -LiteralPath $vswhere) {
    $installPath = & $vswhere -latest -products * -requires Microsoft.Component.MSBuild -property installationPath -nologo 2>$null
    if ($LASTEXITCODE -eq 0 -and $installPath) {
      $msbuild = Join-Path $installPath 'MSBuild\\Current\\Bin\\MSBuild.exe'
      if (Test-Path -LiteralPath $msbuild) { return $msbuild }
      $msbuild15 = Join-Path $installPath 'MSBuild\\15.0\\Bin\\MSBuild.exe'
      if (Test-Path -LiteralPath $msbuild15) { return $msbuild15 }
    }
  }

  throw "No se encontró MSBuild. Instala Visual Studio Build Tools o actualiza las rutas en el script."
}

function Resolve-IISExpressPath {
  $candidates = @(
    "C:\\Program Files\\IIS Express\\iisexpress.exe",
    "C:\\Program Files (x86)\\IIS Express\\iisexpress.exe",
    "D:\\Program Files\\IIS Express\\iisexpress.exe"
  )
  foreach ($p in $candidates) {
    if (Test-Path -LiteralPath $p) { return $p }
  }
  throw "No se encontró IIS Express. Instala 'IIS Express' o usa IIS local."
}

function Resolve-ChromePath {
  $candidates = @(
    "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",
    "C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe",
    "D:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",
    "D:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe"
  )
  foreach ($p in $candidates) {
    if (Test-Path -LiteralPath $p) { return $p }
  }
  return $null
}

function Get-FreeTcpPort {
  param([int]$StartPort)
  $port = [Math]::Max($StartPort, 1024)
  while ($true) {
    $inUse = Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue
    if (-not $inUse) { return $port }
    $port++
    if ($port -gt 65535) { throw "No se encontró un puerto libre." }
  }
}

function Test-PortListening {
  param([int]$CheckPort)
  $conn = Get-NetTCPConnection -State Listen -LocalPort $CheckPort -ErrorAction SilentlyContinue
  return ($conn -ne $null)
}

function Invoke-Build {
  param(
    [string]$MsBuildPath,
    [string]$SolutionPath,
    [string]$Configuration,
    [switch]$Rebuild,
    [string]$LogFile
  )

  $targets = if ($Rebuild) { 'Rebuild' } else { 'Build' }
  # En modo no-watch hacemos Clean+Build para asegurar salida fresca
  if (-not $Watch -and -not $Rebuild) { $targets = 'Clean,Build' }

  Write-Host "Compilando $targets ($Configuration) ..." -ForegroundColor Yellow

  $args = @(
    $SolutionPath,
    "/t:$targets",
    "/p:Configuration=$Configuration",
    "/p:GenerateFullPaths=true",
    "/m",
    "/nologo",
    "/v:m"
  )
  if (-not [string]::IsNullOrWhiteSpace($LogFile)) {
    $logDir = Split-Path -Parent $LogFile
    if (-not [string]::IsNullOrWhiteSpace($logDir) -and -not (Test-Path -LiteralPath $logDir)) {
      New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    $args += "/flp:verbosity=normal;logfile=$LogFile"
  }
  & $MsBuildPath @args

  if ($LASTEXITCODE -ne 0) {
    throw "La compilación falló (código $LASTEXITCODE)."
  }
}

function Parse-BuildErrors {
  param([string]$LogPath)
  $errors = @()
  if (-not (Test-Path -LiteralPath $LogPath)) { return $errors }
  $content = Get-Content -LiteralPath $LogPath
  $regex = '^(?<file>.+?\.cs)\((?<line>\d+),(?<col>\d+)\):\s*error\s+(?<code>CS\d+):\s*(?<msg>.*)$'
  foreach ($line in $content) {
    if ($line -match $regex) {
      $errors += [pscustomobject]@{
        File = $matches['file']
        Line = [int]$matches['line']
        Col  = [int]$matches['col']
        Code = $matches['code']
        Msg  = $matches['msg']
      }
    }
  }
  return $errors
}

function Fix-CS0136-OutVarShadowing {
  param([string]$FilePath, [int]$Line, [string]$VarName)
  if (-not (Test-Path -LiteralPath $FilePath)) { return $false }
  $lines = Get-Content -LiteralPath $FilePath
  $idx = [Math]::Max([Math]::Min($Line - 1, $lines.Count - 1), 0)
  $start = [Math]::Max($idx - 3, 0)
  $end = [Math]::Min($idx + 3, $lines.Count - 1)
  $changed = $false
  for ($i = $start; $i -le $end; $i++) {
    if ($lines[$i] -match "TryParse" -and $lines[$i] -match ("out\\s+var\\s+" + [regex]::Escape($VarName) + "\\b")) {
      # Reemplazar 'out var name' -> 'out name'
      $indent = ($lines[$i] -match '^(\s*)')[1]
      $lines[$i] = [regex]::Replace($lines[$i], ("out\\s+var\\s+" + [regex]::Escape($VarName) + "\\b"), ("out " + $VarName))
      # Insertar declaración previa si no existe en el bloque cercano
      $hasDecl = $false
      for ($j = [Math]::Max($start - 10, 0); $j -lt $i; $j++) {
        if ($lines[$j] -match ("\\b(int|var|string|decimal|double|bool)\\s+" + [regex]::Escape($VarName) + "\\b") ) { $hasDecl = $true; break }
      }
      if (-not $hasDecl) {
        $decl = $indent + "int $VarName = 0;"
        $lines = $lines[0..($i-1)] + @($decl) + $lines[$i..($lines.Count-1)]
        $i++
      }
      $changed = $true
      break
    }
  }
  if ($changed) { Set-Content -LiteralPath $FilePath -Value $lines -Encoding UTF8 }
  return $changed
}

function Fix-CS0246-MissingTypeOrNamespace {
  param([string]$TargetFile, [string]$MissingType, [string]$SolutionRoot)
  # Buscar archivo que define la clase/interfaz/struct
  $pattern = "\b(class|interface|struct)\s+" + [regex]::Escape($MissingType) + "\b"
  $candidate = Get-ChildItem -LiteralPath $SolutionRoot -Recurse -Filter *.cs -ErrorAction SilentlyContinue | Select-String -Pattern $pattern -SimpleMatch -List | Select-Object -First 1
  if (-not $candidate) { return $false }
  $typeFile = $candidate.Path
  $nsLine = (Select-String -Path $typeFile -Pattern '^\s*namespace\s+([\w\.]+)' -List | Select-Object -First 1)
  if (-not $nsLine) { return $false }
  $ns = [regex]::Match($nsLine.Line, '^\s*namespace\s+([\w\.]+)').Groups[1].Value
  if ([string]::IsNullOrWhiteSpace($ns)) { return $false }
  $content = Get-Content -LiteralPath $TargetFile
  if ($content -match ("^using\\s+" + [regex]::Escape($ns) + ";")) { return $false }
  # Insertar using después del último using existente o al inicio
  $insertIdx = 0
  for ($i = 0; $i -lt $content.Count; $i++) {
    if ($content[$i] -match '^using\s+[\w\.]+' ) { $insertIdx = $i + 1 } else { if ($content[$i].Trim().Length -gt 0) { break } }
  }
  $usingLine = "using $ns;"
  $newContent = @()
  if ($insertIdx -le 0) {
    $newContent = @($usingLine, '') + $content
  } else {
    $newContent = $content[0..($insertIdx-1)] + @($usingLine) + $content[$insertIdx..($content.Count-1)]
  }
  Set-Content -LiteralPath $TargetFile -Value $newContent -Encoding UTF8
  return $true
}

function Try-AutoFix {
  param([object[]]$Errors, [string]$SolutionRoot)
  $applied = $false
  foreach ($e in $Errors) {
    switch ($e.Code) {
      'CS0136' {
        # extraer nombre entre comillas en el mensaje
        $m = [regex]::Match($e.Msg, "'([^']+)'")
        if ($m.Success) {
          $varName = $m.Groups[1].Value
          if (Fix-CS0136-OutVarShadowing -FilePath $e.File -Line $e.Line -VarName $varName) { Write-Host "AutoFix CS0136 aplicado en $($e.File)" -ForegroundColor Yellow; $applied = $true; break }
        }
      }
      'CS0246' {
        $m = [regex]::Match($e.Msg, "'([^']+)'")
        if ($m.Success) {
          $typeName = $m.Groups[1].Value
          if (Fix-CS0246-MissingTypeOrNamespace -TargetFile $e.File -MissingType $typeName -SolutionRoot $SolutionRoot) { Write-Host "AutoFix CS0246 aplicado en $($e.File) (using agregado)" -ForegroundColor Yellow; $applied = $true; break }
        }
      }
    }
  }
  return $applied
}

function Invoke-CompileWithAutoFix {
  param(
    [string]$MsBuildPath,
    [string]$SolutionPath,
    [string]$Configuration,
    [switch]$Rebuild,
    [switch]$EnableAutoFix,
    [int]$MaxAttempts,
    [string]$SolutionRoot,
    [string]$LogFile
  )
  $attempt = 0
  while ($true) {
    $attempt++
    if ([string]::IsNullOrWhiteSpace($LogFile)) {
      $log = Join-Path $PSScriptRoot "msbuild-last.log"
    } else {
      $log = $LogFile
    }
    if (Test-Path -LiteralPath $log) { Remove-Item -LiteralPath $log -Force -ErrorAction SilentlyContinue }
    try {
      Invoke-Build -MsBuildPath $MsBuildPath -SolutionPath $SolutionPath -Configuration $Configuration -Rebuild:$Rebuild -LogFile $log
      return $true
    } catch {
      Write-Host "Compilación fallida (intento $attempt). Analizando errores..." -ForegroundColor Red
      if (-not $EnableAutoFix -or $attempt -ge $MaxAttempts) { return $false }
      $errs = Parse-BuildErrors -LogPath $log
      if ($errs.Count -eq 0) { return $false }
      $fixed = Try-AutoFix -Errors $errs -SolutionRoot $SolutionRoot
      if (-not $fixed) { return $false }
      # continuar bucle e intentar recompilar
    }
  }
}

# Directorios/paths del proyecto
$solutionDir = Split-Path -Parent $PSScriptRoot            # ...\NuevoCodigo_MSCargaHoras
$webProjDir  = Join-Path $solutionDir 'MsCargaHoras'       # ...\NuevoCodigo_MSCargaHoras\MsCargaHoras
$solution    = Join-Path $webProjDir 'MsCargaHoras.sln'

if (-not (Test-Path -LiteralPath $solution)) {
  throw "No se encontró la solución en: $solution"
}

# Resolver herramientas
$msbuild = Resolve-MSBuildPath
Write-Host "Usando MSBuild:" $msbuild -ForegroundColor Cyan

# Compilar inicial (con auto-fix opcional)
$globalLog = if ([string]::IsNullOrWhiteSpace($LogFile)) { Join-Path $PSScriptRoot 'msbuild-last.log' } else { $LogFile }
$ok = Invoke-CompileWithAutoFix -MsBuildPath $msbuild -SolutionPath $solution -Configuration $Configuration -Rebuild:$Rebuild -EnableAutoFix:$AutoFix -MaxAttempts $MaxAttempts -SolutionRoot $solutionDir -LogFile $globalLog

# Validación adicional por log (por si MSBuild devolvió 0 pero hay líneas de error)
if ($ok) {
  $errs = Parse-BuildErrors -LogPath $globalLog
  if ($errs.Count -gt 0) { $ok = $false }
}

if (-not $ok) {
  Write-Host "Build fallido. NO se lanzará IIS ni Watcher. Log: $globalLog" -ForegroundColor Red
  exit 1
}

# Opcional: cerrar IIS Express previos
if ($KillExisting) {
  Get-Process iisexpress -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}

# Lanzar sitio con IIS Express (opcional)
$iisProc = $null
if (-not $NoRun) {
  $iis = Resolve-IISExpressPath
  $usePort = $Port
  $alreadyListening = $false

  if ($usePort -gt 0) {
    $alreadyListening = Test-PortListening -CheckPort $usePort
  }

  if ($ReuseIIS -and $alreadyListening) {
    Write-Host "Reutilizando IIS Express existente en http://localhost:$usePort" -ForegroundColor Green
  } else {
    if ($KillExisting) {
      Get-Process iisexpress -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    }

    if ($usePort -le 0 -or $alreadyListening) {
      $usePort = Get-FreeTcpPort -StartPort ([Math]::Max($Port,1024))
    }

    Write-Host "Levantando IIS Express en http://localhost:$usePort" -ForegroundColor Green

    $quotedPath = '"' + $webProjDir + '"'
    $arguments = "/path:$quotedPath /port:$usePort"

    $iisProc = Start-Process -FilePath $iis -ArgumentList $arguments -PassThru
    if ($OpenBrowser) {
      $url = "http://localhost:$usePort/"
      $chrome = Resolve-ChromePath
      if ($chrome) {
        Start-Process -FilePath $chrome -ArgumentList $url
      } else {
        Start-Process $url
      }
    }
  }
}

# Modo Watch: vigilar cambios y recompilar sin relanzar IIS
if ($Watch) {
  Write-Host "Modo vigilancia activo. Observando cambios en: $webProjDir" -ForegroundColor Cyan
  Write-Host "Extensiones: $($WatchExtensions -join ', ') | Debounce: ${DebounceMs}ms" -ForegroundColor DarkGray

  $fsw = New-Object System.IO.FileSystemWatcher
  $fsw.Path = $webProjDir
  $fsw.Filter = '*.*'
  $fsw.IncludeSubdirectories = $true
  $fsw.EnableRaisingEvents = $true

  $queueBuild = $false
  $lastEvent = Get-Date

  $handler = {
    param($sender, $eventArgs)
    $ext = [System.IO.Path]::GetExtension($eventArgs.FullPath)
    if ([string]::IsNullOrWhiteSpace($ext)) { return }
    if ($WatchExtensions -contains $ext.ToLower()) {
      Set-Variable -Name queueBuild -Scope Script -Value $true
      Set-Variable -Name lastEvent  -Scope Script -Value (Get-Date)
    }
  }

  $subs = @(
    [System.IO.FileSystemEventHandler]$handler,
    [System.IO.RenamedEventHandler]$handler
  )

  $createdSub = Register-ObjectEvent -InputObject $fsw -EventName Created -Action $handler
  $changedSub = Register-ObjectEvent -InputObject $fsw -EventName Changed -Action $handler
  $deletedSub = Register-ObjectEvent -InputObject $fsw -EventName Deleted -Action $handler
  $renamedSub = Register-ObjectEvent -InputObject $fsw -EventName Renamed -Action $handler

  Write-Host "Compilación incremental lista. Presiona Ctrl+C para salir." -ForegroundColor DarkGray

  try {
    while ($true) {
      Start-Sleep -Milliseconds 150
      if ($queueBuild -and ((Get-Date) - $lastEvent).TotalMilliseconds -ge $DebounceMs) {
        $queueBuild = $false
        try {
          $ok = Invoke-CompileWithAutoFix -MsBuildPath $msbuild -SolutionPath $solution -Configuration $Configuration -Rebuild:$Rebuild -EnableAutoFix:$AutoFix -MaxAttempts $MaxAttempts -SolutionRoot $solutionDir -LogFile $globalLog
          if ($ok) {
            # validación extra por log en modo watch
            $errs = Parse-BuildErrors -LogPath $globalLog
            if ($errs.Count -gt 0) {
              Write-Host "Errores detectados en log. Build NO aplicado." -ForegroundColor Red
            } else {
              Write-Host "Compilación OK a las $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Green
            }
          } else {
            Write-Host "Error de compilación. Revisa el log: $globalLog" -ForegroundColor Red
          }
        } catch {
          Write-Host "Error de compilación: $($_.Exception.Message)" -ForegroundColor Red
        }
      }
    }
  } finally {
    if ($createdSub) { Unregister-Event -SubscriptionId $createdSub.Id -ErrorAction SilentlyContinue }
    if ($changedSub) { Unregister-Event -SubscriptionId $changedSub.Id -ErrorAction SilentlyContinue }
    if ($deletedSub) { Unregister-Event -SubscriptionId $deletedSub.Id -ErrorAction SilentlyContinue }
    if ($renamedSub) { Unregister-Event -SubscriptionId $renamedSub.Id -ErrorAction SilentlyContinue }
    $fsw.EnableRaisingEvents = $false
    $fsw.Dispose()
  }
}

# Espera opcional si se lanzó IIS Express en esta ejecución
if ($Wait -and $iisProc -ne $null) {
  Write-Host "IIS Express ejecutándose (PID: $($iisProc.Id)). Presiona Ctrl+C para salir." -ForegroundColor DarkGray
  try {
    Wait-Process -Id $iisProc.Id
  } finally {
    if (-not ($iisProc.HasExited)) {
      Stop-Process -Id $iisProc.Id -Force -ErrorAction SilentlyContinue
    }
  }
}

Write-Host "Listo." -ForegroundColor Cyan
exit 0
