@echo off
REM Lanceur silencieux pour AppServMaison
REM Ce fichier peut être placé dans le dossier de démarrage

echo Démarrage silencieux d'AppServMaison...

REM Attendre 30 secondes après le boot pour laisser le réseau se stabiliser
timeout /t 30 /nobreak > nul

REM Lancer le service PowerShell en mode caché
powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File "D:\DATA\serveur333-api.ps1"