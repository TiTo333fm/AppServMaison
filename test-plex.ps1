# Script de test pour les endpoints Plex
# Test rapide des fonctionnalités Plex

$serverUrl = "http://192.168.1.175:8080"

Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "    Test des endpoints Plex" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "Serveur: $serverUrl" -ForegroundColor Green
Write-Host ""

# Fonction pour afficher le résultat
function Show-Result($title, $response) {
    Write-Host "$title :" -ForegroundColor Yellow
    if ($response) {
        $response | ConvertTo-Json -Depth 3 | Write-Host -ForegroundColor White
    } else {
        Write-Host "  Pas de réponse" -ForegroundColor Red
    }
    Write-Host ""
}

try {
    # 1. Vérifier le statut de Plex
    Write-Host "1️⃣  Vérification du statut Plex..." -ForegroundColor Cyan
    $status = Invoke-RestMethod -Uri "$serverUrl/api/plex/status" -Method GET -ErrorAction Stop
    Show-Result "Statut Plex" $status
    
    # 2. Test d'arrêt de Plex (si en cours)
    if ($status.plex_running -eq $true) {
        Write-Host "2️⃣  Plex est en cours - Test d'arrêt..." -ForegroundColor Cyan
        $stopResult = Invoke-RestMethod -Uri "$serverUrl/api/plex/stop" -Method POST -ErrorAction Stop
        Show-Result "Arrêt Plex" $stopResult
        
        # Attendre un peu et vérifier le statut
        Write-Host "⏳ Attente 3 secondes..." -ForegroundColor Gray
        Start-Sleep -Seconds 3
        
        $statusAfterStop = Invoke-RestMethod -Uri "$serverUrl/api/plex/status" -Method GET -ErrorAction Stop
        Show-Result "Statut après arrêt" $statusAfterStop
        
        # 3. Test de redémarrage de Plex
        Write-Host "3️⃣  Test de redémarrage..." -ForegroundColor Cyan
        $startResult = Invoke-RestMethod -Uri "$serverUrl/api/plex/start" -Method POST -ErrorAction Stop
        Show-Result "Démarrage Plex" $startResult
        
        # Vérifier le statut final
        Write-Host "⏳ Attente 5 secondes pour démarrage..." -ForegroundColor Gray
        Start-Sleep -Seconds 5
        
        $statusAfterStart = Invoke-RestMethod -Uri "$serverUrl/api/plex/status" -Method GET -ErrorAction Stop
        Show-Result "Statut final" $statusAfterStart
        
    } else {
        Write-Host "2️⃣  Plex n'est pas en cours - Test de démarrage..." -ForegroundColor Cyan
        $startResult = Invoke-RestMethod -Uri "$serverUrl/api/plex/start" -Method POST -ErrorAction Stop
        Show-Result "Démarrage Plex" $startResult
    }
    
} catch {
    Write-Host "❌ Erreur lors du test:" -ForegroundColor Red
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Vérifiez que le service API est en cours sur $serverUrl" -ForegroundColor Yellow
}

Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "Test terminé" -ForegroundColor Green
Write-Host ""
Read-Host "Appuyez sur Entrée pour fermer"