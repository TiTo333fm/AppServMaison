# Test local du service API sur SERVEUR333
# À exécuter DIRECTEMENT sur SERVEUR333 pendant que le service tourne

$serverUrl = "http://localhost:8080"

Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "Test LOCAL du service API" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan

# Test 1: Localhost
Write-Host "🔍 Test 1: Connexion localhost..." -ForegroundColor Yellow
try {
    $response1 = Invoke-RestMethod -Uri "$serverUrl/api/status" -Method GET -TimeoutSec 5
    Write-Host "✅ LOCALHOST OK - Serveur: $($response1.server)" -ForegroundColor Green
    Write-Host "   Status: $($response1.status)" -ForegroundColor White
    Write-Host "   Uptime: $($response1.uptime_hours)h" -ForegroundColor White
} catch {
    Write-Host "❌ LOCALHOST ÉCHEC: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 2: IP locale
Write-Host "🔍 Test 2: Connexion IP locale (192.168.1.175)..." -ForegroundColor Yellow
try {
    $response2 = Invoke-RestMethod -Uri "http://192.168.1.175:8080/api/status" -Method GET -TimeoutSec 5
    Write-Host "✅ IP LOCALE OK - Serveur: $($response2.server)" -ForegroundColor Green
} catch {
    Write-Host "❌ IP LOCALE ÉCHEC: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 3: Vérifier les ports en écoute
Write-Host "🔍 Test 3: Ports en écoute..." -ForegroundColor Yellow
try {
    $netstat = netstat -an | Select-String ":8080"
    if ($netstat) {
        Write-Host "✅ Port 8080 en écoute:" -ForegroundColor Green
        $netstat | ForEach-Object { Write-Host "   $_" -ForegroundColor White }
    } else {
        Write-Host "❌ Port 8080 NON trouvé dans netstat" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Erreur netstat: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 4: Vérifier les règles de pare-feu
Write-Host "🔍 Test 4: Règles pare-feu pour port 8080..." -ForegroundColor Yellow
try {
    $firewallRules = Get-NetFirewallRule | Where-Object { $_.DisplayName -like "*8080*" -or $_.DisplayName -like "*AppServ*" }
    if ($firewallRules) {
        Write-Host "✅ Règles pare-feu trouvées:" -ForegroundColor Green
        $firewallRules | ForEach-Object { Write-Host "   $($_.DisplayName) - $($_.Enabled)" -ForegroundColor White }
    } else {
        Write-Host "⚠️  Aucune règle pare-feu spécifique trouvée pour le port 8080" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Erreur vérification pare-feu: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "Diagnostic terminé" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan

Read-Host "Appuyez sur Entrée pour continuer..."