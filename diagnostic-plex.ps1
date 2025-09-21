# Diagnostic Plex Media Server
# Script pour identifier l'installation Plex existante

Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "    Diagnostic Plex Media Server" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan

# 1. Recherche des services Plex
Write-Host "1. Services Plex disponibles:" -ForegroundColor Yellow
$plexServices = Get-Service -Name "*plex*" -ErrorAction SilentlyContinue
if ($plexServices) {
    foreach ($service in $plexServices) {
        Write-Host "  ✅ Service trouvé: $($service.Name)" -ForegroundColor Green
        Write-Host "     Statut: $($service.Status)" -ForegroundColor White
        Write-Host "     Nom complet: $($service.DisplayName)" -ForegroundColor White
        Write-Host "     Mode démarrage: $($service.StartType)" -ForegroundColor White
        Write-Host ""
    }
} else {
    Write-Host "  ❌ Aucun service Plex trouvé" -ForegroundColor Red
}

# 2. Recherche des processus Plex en cours
Write-Host "2. Processus Plex en cours d'exécution:" -ForegroundColor Yellow
$plexProcesses = Get-Process -Name "*plex*" -ErrorAction SilentlyContinue
if ($plexProcesses) {
    foreach ($process in $plexProcesses) {
        Write-Host "  ✅ Processus: $($process.ProcessName) (PID: $($process.Id))" -ForegroundColor Green
        if ($process.Path) {
            Write-Host "     Chemin: $($process.Path)" -ForegroundColor White
        }
    }
    Write-Host ""
} else {
    Write-Host "  ❌ Aucun processus Plex en cours" -ForegroundColor Red
    Write-Host ""
}

# 3. Recherche des chemins d'installation typiques
Write-Host "3. Chemins d'installation Plex:" -ForegroundColor Yellow
$commonPaths = @(
    "C:\Program Files\Plex\Plex Media Server",
    "C:\Program Files (x86)\Plex\Plex Media Server", 
    "${env:LOCALAPPDATA}\Plex Media Server",
    "${env:PROGRAMFILES}\Plex\Plex Media Server",
    "${env:PROGRAMFILES(X86)}\Plex\Plex Media Server"
)

foreach ($path in $commonPaths) {
    if (Test-Path $path) {
        Write-Host "  ✅ Installation trouvée: $path" -ForegroundColor Green
        
        # Rechercher les exécutables
        $exeFiles = Get-ChildItem "$path\*.exe" -ErrorAction SilentlyContinue
        if ($exeFiles) {
            foreach ($exe in $exeFiles) {
                Write-Host "     Exécutable: $($exe.Name)" -ForegroundColor White
            }
        }
        Write-Host ""
    }
}

# 4. Recherche dans le registre Windows
Write-Host "4. Informations du registre:" -ForegroundColor Yellow
try {
    $regPaths = @(
        "HKLM:\SOFTWARE\Plex, Inc.\Plex Media Server",
        "HKLM:\SOFTWARE\WOW6432Node\Plex, Inc.\Plex Media Server",
        "HKCU:\SOFTWARE\Plex, Inc.\Plex Media Server"
    )
    
    foreach ($regPath in $regPaths) {
        if (Test-Path $regPath) {
            Write-Host "  ✅ Clé registre trouvée: $regPath" -ForegroundColor Green
            $regValues = Get-ItemProperty $regPath -ErrorAction SilentlyContinue
            if ($regValues.InstallDir) {
                Write-Host "     Répertoire d'installation: $($regValues.InstallDir)" -ForegroundColor White
            }
            if ($regValues.Version) {
                Write-Host "     Version: $($regValues.Version)" -ForegroundColor White
            }
            Write-Host ""
        }
    }
} catch {
    Write-Host "  ⚠️ Impossible de lire le registre: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 5. Test des ports Plex typiques
Write-Host "5. Test des ports Plex:" -ForegroundColor Yellow
$plexPorts = @(32400, 32469, 1900, 3005, 5353, 8324, 32410, 32412, 32413, 32414)
foreach ($port in $plexPorts) {
    try {
        $connection = Test-NetConnection -ComputerName "localhost" -Port $port -InformationLevel Quiet -WarningAction SilentlyContinue
        if ($connection) {
            Write-Host "  ✅ Port $port ouvert (probablement Plex)" -ForegroundColor Green
        }
    } catch {
        # Port fermé, normal
    }
}

# 6. URL d'accès Plex local
Write-Host ""
Write-Host "6. URLs d'accès Plex typiques:" -ForegroundColor Yellow
Write-Host "  Local: http://localhost:32400/web" -ForegroundColor White
Write-Host "  Réseau: http://192.168.1.175:32400/web" -ForegroundColor White

Write-Host ""
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "Diagnostic terminé" -ForegroundColor Green
Write-Host ""
Write-Host "💡 Informations nécessaires pour l'intégration:" -ForegroundColor Yellow
Write-Host "   - Nom exact du service Plex" -ForegroundColor White
Write-Host "   - Chemin de l'exécutable principal" -ForegroundColor White
Write-Host "   - Méthode préférée (service ou processus)" -ForegroundColor White

Read-Host "Appuyez sur Entrée pour continuer"