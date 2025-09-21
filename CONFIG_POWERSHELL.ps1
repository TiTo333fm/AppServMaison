# Configuration PowerShell pour AppServMaison
# Exécuter ce script une seule fois pour configurer PowerShell

Write-Host "Configuration de PowerShell pour AppServMaison..." -ForegroundColor Cyan

# Vérifier la politique d'exécution actuelle
$currentPolicy = Get-ExecutionPolicy
Write-Host "Politique actuelle: $currentPolicy" -ForegroundColor Yellow

if ($currentPolicy -eq "Restricted") {
    Write-Host ""
    Write-Host "⚠️ Politique d'exécution trop restrictive" -ForegroundColor Red
    Write-Host "Changement vers RemoteSigned..." -ForegroundColor Yellow
    
    try {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Write-Host "✅ Politique changée vers RemoteSigned" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Erreur: $_" -ForegroundColor Red
        Write-Host "Essayez d'exécuter ce script en tant qu'administrateur" -ForegroundColor Yellow
    }
} else {
    Write-Host "✅ Politique d'exécution OK: $currentPolicy" -ForegroundColor Green
}

Write-Host ""
Write-Host "Configuration terminée !" -ForegroundColor Green
Write-Host "Vous pouvez maintenant exécuter serveur333-api.ps1" -ForegroundColor Green

Read-Host "Appuyez sur Entrée pour fermer"