@echo off
REM Lanceur pour AppServMaison API Service
REM Ce fichier lance le script PowerShell en tant qu'administrateur

echo ==========================================
echo    AppServMaison - Lanceur Service API
echo ==========================================
echo.
echo Demarrage du service en tant qu'administrateur...
echo.

REM Changer vers le repertoire du script
cd /d "D:\DATA"

REM Executer PowerShell en tant qu'admin avec le script
powershell -ExecutionPolicy Bypass -Command "Start-Process PowerShell -ArgumentList '-ExecutionPolicy Bypass -File \"%~dp0serveur333-api.ps1\"' -Verb RunAs"

echo.
echo Service demarre ! Verifiez la fenetre PowerShell qui s'est ouverte.
pause