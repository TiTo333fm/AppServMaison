# Test des endpoints Plex - Version simple
# À exécuter depuis votre machine de développement

$serverUrl = "http://192.168.1.175:8080"

Write-Output "=== Test API Plex SERVEUR333 ==="
Write-Output ""

# Test 1: Status de Plex
Write-Output "1. Test du statut Plex..."
try {
    $statusResponse = Invoke-RestMethod -Uri "$serverUrl/api/plex/status" -Method GET -TimeoutSec 5
    Write-Output "   Plex Status: SUCCESS"
    Write-Output "   Plex Running: $($statusResponse.plex_running)"
    Write-Output "   Port 32400 Open: $($statusResponse.port_32400_open)"
    if ($statusResponse.process_id) {
        Write-Output "   Process ID: $($statusResponse.process_id)"
    }
} catch {
    Write-Output "   Plex Status: FAILED - $($_.Exception.Message)"
}
Write-Output ""

# Test 2: Arrêt de Plex (si en cours)
Write-Output "2. Test arrêt Plex..."
try {
    $stopResponse = Invoke-RestMethod -Uri "$serverUrl/api/plex/stop" -Method POST -TimeoutSec 10
    Write-Output "   Plex Stop: SUCCESS"
    Write-Output "   Message: $($stopResponse.message)"
    Write-Output "   Success: $($stopResponse.success)"
} catch {
    Write-Output "   Plex Stop: FAILED - $($_.Exception.Message)"
}
Write-Output ""

# Attendre 3 secondes
Write-Output "3. Attente 3 secondes..."
Start-Sleep -Seconds 3
Write-Output ""

# Test 3: Démarrage de Plex
Write-Output "4. Test démarrage Plex..."
try {
    $startResponse = Invoke-RestMethod -Uri "$serverUrl/api/plex/start" -Method POST -TimeoutSec 10
    Write-Output "   Plex Start: SUCCESS"
    Write-Output "   Message: $($startResponse.message)"
    Write-Output "   Success: $($startResponse.success)"
    if ($startResponse.new_pid) {
        Write-Output "   New Process ID: $($startResponse.new_pid)"
    }
} catch {
    Write-Output "   Plex Start: FAILED - $($_.Exception.Message)"
}
Write-Output ""

# Test 4: Vérification finale du status
Write-Output "5. Vérification finale..."
try {
    $finalResponse = Invoke-RestMethod -Uri "$serverUrl/api/plex/status" -Method GET -TimeoutSec 5
    Write-Output "   Final Status: SUCCESS"
    Write-Output "   Plex Running: $($finalResponse.plex_running)"
    Write-Output "   Port 32400 Open: $($finalResponse.port_32400_open)"
} catch {
    Write-Output "   Final Status: FAILED - $($_.Exception.Message)"
}

Write-Output ""
Write-Output "=== Test terminé ==="