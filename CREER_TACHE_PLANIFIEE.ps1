# Créer une tâche planifiée pour AppServMaison
# Exécuter en tant qu'administrateur

Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "   Tâche Planifiée AppServMaison" -ForegroundColor Cyan
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

$taskName = "AppServMaison-AutoStart"
$scriptPath = "D:\DATA\serveur333-api.ps1"  # Adapter le chemin

# Vérifier que le script existe
if (-not (Test-Path $scriptPath)) {
    Write-Host "❌ Script non trouvé : $scriptPath" -ForegroundColor Red
    Write-Host "Veuillez modifier le chemin dans ce script" -ForegroundColor Yellow
    Read-Host "Appuyez sur Entrée pour fermer"
    exit
}

try {
    # Supprimer la tâche existante si elle existe
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-Host "🔄 Suppression de la tâche existante..." -ForegroundColor Yellow
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }

    # Créer l'action (ce qui sera exécuté)
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""
    
    # Créer le déclencheur (au démarrage du système)
    $trigger = New-ScheduledTaskTrigger -AtStartup
    
    # Créer les paramètres
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable
    
    # Créer le principal (utilisateur système)
    $principal = New-ScheduledTaskPrincipal -UserID "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    # Enregistrer la tâche
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Démarrage automatique d'AppServMaison API au boot système"
    
    Write-Host "✅ Tâche planifiée créée avec succès !" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Détails de la tâche :" -ForegroundColor Cyan
    Write-Host "  Nom : $taskName" -ForegroundColor White
    Write-Host "  Déclencheur : Au démarrage du système" -ForegroundColor White
    Write-Host "  Script : $scriptPath" -ForegroundColor White
    Write-Host ""
    Write-Host "🎯 Au prochain redémarrage, le service se lancera automatiquement !" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Commandes utiles :" -ForegroundColor Cyan
    Write-Host "  Lancer maintenant : Start-ScheduledTask -TaskName $taskName" -ForegroundColor White
    Write-Host "  Voir l'état       : Get-ScheduledTask -TaskName $taskName" -ForegroundColor White
    Write-Host "  Supprimer         : Unregister-ScheduledTask -TaskName $taskName" -ForegroundColor White

}
catch {
    Write-Host "❌ Erreur lors de la création de la tâche :" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

Read-Host "Appuyez sur Entrée pour fermer"