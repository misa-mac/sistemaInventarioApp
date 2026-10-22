@echo off
title Sistema de Inventario ITBM
echo ========================================================
echo   Iniciando Backend y Frontend de Sistema de Inventario
echo ========================================================
echo.
echo 1. Levantando Backend en http://localhost:3000...
start "Backend API (Puerto 3000)" cmd /k "cd /d %~dp0backend && npm run dev"

echo 2. Levantando Frontend Web en http://localhost:5173...
start "Frontend Web (Puerto 5173)" cmd /k "cd /d %~dp0frontend-web && npm run dev"

if exist "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" (
    echo 3. Configurando puente USB para celular Android (adb reverse tcp:3000)...
    "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" reverse tcp:3000 tcp:3000 >nul 2>&1
)

echo.
echo Servidores iniciados y puente movil configurado.
echo.
pause
