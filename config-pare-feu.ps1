# Configuration pare-feu pour AppServMaison
# À exécuter en tant qu'administrateur sur SERVEUR333

Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "Configuration Pare-feu AppServMaison" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan

# Supprimer les anciennes règles si elles existent
try {
    Remove-NetFirewallRule -DisplayName "AppServMaison API" -ErrorAction SilentlyContinue
    Write-Host "✅ Anciennes règles supprimées" -ForegroundColor Green
} catch {
    Write-Host "ℹ️  Aucune ancienne règle à supprimer" -ForegroundColor Gray
}

# Créer une nouvelle règle entrante
try {
    New-NetFirewallRule -DisplayName "AppServMaison API" -Direction Inbound -Protocol TCP -LocalPort 8080 -Action Allow -Profile Any
    Write-Host "✅ Règle pare-feu créée: Port 8080 ouvert" -ForegroundColor Green
} catch {
    Write-Host "❌ Erreur création règle pare-feu: $($_.Exception.Message)" -ForegroundColor Red
}

# Vérifier la création
try {
    $rule = Get-NetFirewallRule -DisplayName "AppServMaison API"
    Write-Host "✅ Vérification règle:" -ForegroundColor Green
    Write-Host "   Nom: $($rule.DisplayName)" -ForegroundColor White
    Write-Host "   Direction: $($rule.Direction)" -ForegroundColor White
    Write-Host "   Action: $($rule.Action)" -ForegroundColor White
    Write-Host "   Activée: $($rule.Enabled)" -ForegroundColor White
} catch {
    Write-Host "❌ Erreur vérification règle: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "🔥 Configuration pare-feu terminée !" -ForegroundColor Green
Write-Host "Relancez maintenant le service PowerShell." -ForegroundColor Yellow

Read-Host "Appuyez sur Entrée pour continuer..."