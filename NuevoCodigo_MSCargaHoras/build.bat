@echo off
setlocal

REM Compila la solución MsCargaHoras (web + tests) en Debug y ejecuta pruebas MSTest si existen

set MSBUILD_EXE="C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe"
set SOLUTION_DIR=%~dp0MsCargaHoras
set SLN=%SOLUTION_DIR%\MsCargaHoras.sln

if not exist %MSBUILD_EXE% (
  echo No se encontró MSBuild en la ruta predeterminada. Edita build.bat para ajustar la ruta.
  exit /b 1
)

echo Compilando solucion: %SLN%
%MSBUILD_EXE% "%SLN%" /t:Clean,Build /p:Configuration=Debug /m
if errorlevel 1 (
  echo Error de compilacion.
  exit /b 1
)

REM Ejecutar pruebas si hay ensamblado de tests
set TEST_DLL=%SOLUTION_DIR%\MsCargaHoras.Tests\bin\Debug\MsCargaHoras.Tests.dll
if exist "%TEST_DLL%" (
  echo Ejecutando pruebas con VSTest.console...
  set VSTEST="C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\TestWindow\vstest.console.exe"
  if exist %VSTEST% (
    %VSTEST% "%TEST_DLL%"
  ) else (
    echo No se encontro vstest.console.exe. Saltando pruebas.
  )
)

echo Listo.
endlocal


