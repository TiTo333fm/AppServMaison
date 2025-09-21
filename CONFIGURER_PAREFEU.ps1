# Configuration du pare-feu Windows pour AppServMaison
# Exécuter sur SERVEUR333 en tant qu'administrateur

Write-Host "Configuration du pare-feu pour AppServMaison..." -ForegroundColor Cyan

try {
    # Créer une règle pour autoriser le port 8080 en entrée
    New-NetFirewallRule -DisplayName "AppServMaison API - Port 8080" `
                        -Direction Inbound `
                        -Protocol TCP `
                        -LocalPort 8080 `
                        -Action Allow `
                        -Profile Domain,Private,Public
    
    Write-Host "✅ Règle de pare-feu créée avec succès !" -ForegroundColor Green
    Write-Host "   Port 8080 TCP autorisé en entrée" -ForegroundColor Green
}
catch {
    Write-Host "❌ Erreur lors de la création de la règle :" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Alternative : Ouvrez manuellement le pare-feu Windows" -ForegroundColor Yellow
    Write-Host "Pare-feu Windows Defender → Paramètres avancés → Règles de trafic entrant → Nouvelle règle..." -ForegroundColor White
}

# Vérifier les règles existantes
Write-Host ""
Write-Host "Règles de pare-feu existantes pour le port 8080 :" -ForegroundColor Yellow
Get-NetFirewallRule | Where-Object { $_.DisplayName -like "*8080*" -or $_.DisplayName -like "*AppServMaison*" } | 
    Select-Object DisplayName, Direction, Action, Enabled

Read-Host "Appuyez sur Entrée pour continuer"