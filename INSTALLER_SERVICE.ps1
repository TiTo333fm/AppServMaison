# Installation d'AppServMaison comme service Windows
# Exécuter UNE SEULE FOIS en tant qu'administrateur

Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "   Installation Service AppServMaison" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan

# Vérifier les privilèges administrateur
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "❌ Ce script DOIT être exécuté en tant qu'administrateur" -ForegroundColor Red
    Read-Host "Appuyez sur Entrée pour fermer"
    exit
}

$serviceName = "AppServMaison"
$serviceDisplayName = "AppServMaison API Service"
$serviceDescription = "Service REST pour contrôler SERVEUR333 à distance via AppServMaison"

# Chemin vers le script (à adapter)
$scriptPath = "D:\DATA\serveur333-api.ps1"

# Vérifier que le script existe
if (-not (Test-Path $scriptPath)) {
    Write-Host "❌ Script non trouvé : $scriptPath" -ForegroundColor Red
    Write-Host "Veuillez modifier le chemin dans ce script d'installation" -ForegroundColor Yellow
    Read-Host "Appuyez sur Entrée pour fermer"
    exit
}

# Supprimer le service s'il existe déjà
try {
    $existingService = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if ($existingService) {
        Write-Host "🔄 Arrêt et suppression du service existant..." -ForegroundColor Yellow
        Stop-Service -Name $serviceName -Force
        sc.exe delete $serviceName
        Start-Sleep -Seconds 2
    }
}
catch {
    # Ignorer les erreurs
}

# Créer le wrapper pour le service
$wrapperPath = "D:\DATA\AppServMaison-Service.ps1"
$wrapperContent = @"
# Wrapper pour le service AppServMaison
`$scriptPath = "$scriptPath"

# Configurer les logs
`$logPath = "D:\DATA\AppServMaison.log"

function Write-Log(`$message) {
    `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "`$timestamp - `$message" | Add-Content -Path `$logPath
}

try {
    Write-Log "Démarrage du service AppServMaison"
    
    # Exécuter le script principal
    & `$scriptPath
}
catch {
    Write-Log "Erreur: `$(`$_.Exception.Message)"
}
"@

$wrapperContent | Out-File -FilePath $wrapperPath -Encoding UTF8

Write-Host "📝 Wrapper créé : $wrapperPath" -ForegroundColor Green

# Créer le service avec NSSM (si disponible) ou méthode native
$nssmPath = Get-Command "nssm" -ErrorAction SilentlyContinue

if ($nssmPath) {
    Write-Host "🔧 Installation avec NSSM..." -ForegroundColor Yellow
    
    # Installer le service avec NSSM
    & nssm install $serviceName powershell.exe
    & nssm set $serviceName Arguments "-ExecutionPolicy Bypass -File `"$wrapperPath`""
    & nssm set $serviceName DisplayName "$serviceDisplayName"
    & nssm set $serviceName Description "$serviceDescription"
    & nssm set $serviceName Start SERVICE_AUTO_START
    
    Write-Host "✅ Service installé avec NSSM" -ForegroundColor Green
}
else {
    Write-Host "⚠️ NSSM non trouvé. Installation manuelle recommandée." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Instructions pour installer NSSM :" -ForegroundColor Cyan
    Write-Host "1. Télécharger NSSM depuis https://nssm.cc/download" -ForegroundColor White
    Write-Host "2. Extraire nssm.exe dans C:\Windows\System32\" -ForegroundColor White
    Write-Host "3. Relancer ce script d'installation" -ForegroundColor White
    Write-Host ""
    Write-Host "Alternative : Tâche planifiée (voir solution 2)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📋 Commandes utiles :" -ForegroundColor Cyan
Write-Host "  Démarrer : Start-Service $serviceName" -ForegroundColor White
Write-Host "  Arrêter  : Stop-Service $serviceName" -ForegroundColor White
Write-Host "  Statut   : Get-Service $serviceName" -ForegroundColor White
Write-Host "  Logs     : Get-Content D:\DATA\AppServMaison.log -Tail 20" -ForegroundColor White

Read-Host "Appuyez sur Entrée pour fermer"