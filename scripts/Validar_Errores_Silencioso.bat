@echo off
setlocal
set SCRIPT_DIR=%~dp0
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%Build-Run-MsCargaHoras.ps1" -Configuration Debug -NoRun -LogFile "%SCRIPT_DIR%msbuild-last.log"
endlocal