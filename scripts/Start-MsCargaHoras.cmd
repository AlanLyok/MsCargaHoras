@echo off
setlocal
set SCRIPT_DIR=%~dp0
set BUILD_PS1=%SCRIPT_DIR%NuevoCodigo_MSCargaHoras\scripts\Build-Run-MsCargaHoras.ps1

REM Paso 1: Compilar con AutoFix, cerrar IIS previo, levantar y abrir navegador (Chrome si está)
powershell -NoProfile -ExecutionPolicy Bypass -File "%BUILD_PS1%" -Configuration Debug -Port 58755 -KillExisting -OpenBrowser -AutoFix -MaxAttempts 3

REM Paso 2: Iniciar watcher en una nueva ventana reutilizando IIS y con AutoFix
start "Watch MsCargaHoras" powershell -NoProfile -ExecutionPolicy Bypass -File "%BUILD_PS1%" -Configuration Debug -Port 58755 -ReuseIIS -Watch -AutoFix -MaxAttempts 3 -LogFile "%SCRIPT_DIR%NuevoCodigo_MSCargaHoras\scripts\msbuild-last.log"

endlocal

