# AppServMaison API Service pour SERVEUR333 - Version modulaire
# Service REST pour contrôler le serveur à distance
# Exécuter en tant qu'administrateur

$serverName = "SERVEUR333"
$serverIp = "192.168.1.175"
$port = 8080

Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "    AppServMaison API Service v2.0" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "Serveur: $serverName" -ForegroundColor Green
Write-Host "Adresse IP: $serverIp" -ForegroundColor Green
Write-Host "Port: $port" -ForegroundColor Green
Write-Host "Architecture: Modulaire" -ForegroundColor Magenta
Write-Host "===========================================" -ForegroundColor Cyan

# Charger les modules
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "Chargement des modules..." -ForegroundColor Yellow
try {
    . "$scriptPath\server-control.ps1"
    . "$scriptPath\plex-control.ps1"
    Write-Host "Tous les modules chargés avec succès" -ForegroundColor Green
} catch {
    Write-Host "Erreur lors du chargement des modules: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Vérifiez que les fichiers server-control.ps1 et plex-control.ps1 sont présents" -ForegroundColor Yellow
    Read-Host "Appuyez sur Entrée pour fermer"
    exit 1
}

# Vérifier les privilèges administrateur
$isAdmin = Test-IsAdmin

if (-not $isAdmin) {
    Write-Host "ATTENTION: Ce script doit etre execute en tant qu'administrateur" -ForegroundColor Red
    Write-Host "   pour pouvoir arrêter/redémarrer le serveur et contrôler Plex." -ForegroundColor Red
    Write-Host ""
    Read-Host "Appuyez sur Entrée pour continuer quand même (fonctionnalités limitées)"
}

# Variable globale pour contrôler l'arrêt propre
$global:shouldStop = $false

# Simple gestionnaire pour Ctrl+C (plus compatible)
$null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    $global:shouldStop = $true
}

$listener = New-Object System.Net.HttpListener

# Configuration d'écoute
try {
    # Méthode 1: Écoute sur toutes les interfaces
    $listener.Prefixes.Add("http://+:$port/")
} catch {
    try {
        # Méthode 2: Écoute sur IP spécifique
        $listener.Prefixes.Add("http://$serverIp`:$port/")
    } catch {
        # Méthode 3: Écoute en local seulement
        $listener.Prefixes.Add("http://localhost:$port/")
        Write-Host "Ecoute en local uniquement (localhost:$port)" -ForegroundColor Yellow
    }
}

try {
    $listener.Start()
    Write-Host ""
    Write-Host "Service API demarre avec succes !" -ForegroundColor Green
    Write-Host ""
    
    # Afficher les préfixes d'écoute réels
    Write-Host "URLs d'ecoute actives:" -ForegroundColor Magenta
    foreach ($prefix in $listener.Prefixes) {
        Write-Host "   $prefix" -ForegroundColor White
    }
    Write-Host ""
    
    Write-Host "Endpoints disponibles:" -ForegroundColor Yellow
    Write-Host "  Serveur:" -ForegroundColor Cyan
    Write-Host "    GET  /api/status         - Vérifier le statut" -ForegroundColor White
    Write-Host "    POST /api/shutdown       - Arrêt du serveur" -ForegroundColor White
    Write-Host "    POST /api/restart        - Redémarrage du serveur" -ForegroundColor White
    Write-Host "    POST /api/cancel         - Annuler un arrêt/redémarrage" -ForegroundColor White
    Write-Host "    GET  /api/test           - Test des privilèges système" -ForegroundColor White
    Write-Host ""
    Write-Host "  Plex Media Server:" -ForegroundColor Cyan
    Write-Host "    GET  /api/plex/status    - Statut de Plex" -ForegroundColor White
    Write-Host "    POST /api/plex/start     - Démarrer Plex" -ForegroundColor White
    Write-Host "    POST /api/plex/stop      - Arrêter Plex" -ForegroundColor White
    Write-Host "    POST /api/plex/restart   - Redémarrer Plex" -ForegroundColor White
    Write-Host ""
    Write-Host "Configuration de l'application mobile:" -ForegroundColor Yellow
    Write-Host "  IP Serveur: $serverIp" -ForegroundColor White
    Write-Host "  Port: $port" -ForegroundColor White
    Write-Host ""
    Write-Host "Appuyez sur Ctrl+C pour arrêter le service..." -ForegroundColor Cyan
    Write-Host ""

    while ($listener.IsListening -and -not $global:shouldStop) {
        try {
            # Approche synchrone plus fiable
            $context = $listener.GetContext()
            $request = $context.Request
            $response = $context.Response
            
            $path = $request.Url.AbsolutePath
            $method = $request.HttpMethod
            $clientIP = $request.RemoteEndPoint.Address.ToString()
            
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Write-Host "[$timestamp] $clientIP - $method $path" -ForegroundColor Gray
            
            # Headers CORS pour permettre les requêtes cross-origin
            $response.Headers.Add("Access-Control-Allow-Origin", "*")
            $response.Headers.Add("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
            $response.Headers.Add("Access-Control-Allow-Headers", "Content-Type")
            $response.Headers.Add("Server", "AppServMaison-API/2.0")
            
            $responseString = ""
            
            # Routage des requêtes
            if ($method -eq "OPTIONS") {
                # Réponse aux requêtes preflight CORS
                $response.StatusCode = 200
                Write-Host "    → OPTIONS (CORS preflight) - 200 OK" -ForegroundColor DarkGray
            }
            elseif ($path -eq "/api/status" -and $method -eq "GET") {
                # Status du serveur
                $serverStatus = Get-ServerStatus -ServerName $serverName
                $responseString = $serverStatus | ConvertTo-Json
                $response.StatusCode = 200
                Write-Host "    → Server Status - 200 OK" -ForegroundColor Green
            }
            elseif ($path -eq "/api/shutdown" -and $method -eq "POST") {
                # Arrêt du serveur
                $shutdownResult = Stop-Server -ServerName $serverName -ClientIP $clientIP
                $responseString = $shutdownResult | ConvertTo-Json
                $response.StatusCode = if ($shutdownResult.success) { 200 } else { if ($shutdownResult.error -eq "Insufficient privileges") { 403 } else { 500 } }
                
                if ($shutdownResult.success) {
                    Write-Host "    → Server Shutdown - 200 OK" -ForegroundColor Red
                    Write-Host "      ARRET DU SERVEUR dans 15 secondes..." -ForegroundColor Red
                } else {
                    Write-Host "    → Server Shutdown - $($response.StatusCode) Error" -ForegroundColor Red
                }
            }
            elseif ($path -eq "/api/restart" -and $method -eq "POST") {
                # Redémarrage du serveur
                $restartResult = Restart-Server -ServerName $serverName -ClientIP $clientIP
                $responseString = $restartResult | ConvertTo-Json
                $response.StatusCode = if ($restartResult.success) { 200 } else { if ($restartResult.error -eq "Insufficient privileges") { 403 } else { 500 } }
                
                if ($restartResult.success) {
                    Write-Host "    → Server Restart - 200 OK" -ForegroundColor Yellow
                    Write-Host "      REDEMARRAGE DU SERVEUR dans 15 secondes..." -ForegroundColor Yellow
                } else {
                    Write-Host "    → Server Restart - $($response.StatusCode) Error" -ForegroundColor Red
                }
            }
            elseif ($path -eq "/api/cancel" -and $method -eq "POST") {
                # Annuler un arrêt/redémarrage
                $cancelResult = Stop-ServerShutdown -ServerName $serverName
                $responseString = $cancelResult | ConvertTo-Json
                $response.StatusCode = if ($cancelResult.success) { 200 } else { if ($cancelResult.error -eq "Insufficient privileges") { 403 } else { 500 } }
                
                if ($cancelResult.success) {
                    Write-Host "    → Cancel Shutdown - 200 OK" -ForegroundColor Green
                    Write-Host "      ANNULATION de l'arret/redemarrage" -ForegroundColor Green
                } else {
                    Write-Host "    → Cancel Shutdown - $($response.StatusCode) Error" -ForegroundColor Red
                }
            }
            elseif ($path -eq "/api/test" -and $method -eq "GET") {
                # Test des privilèges système
                $testResult = Test-ServerPrivileges -ServerName $serverName
                $responseString = $testResult | ConvertTo-Json
                $response.StatusCode = 200
                Write-Host "    → System Test - 200 OK" -ForegroundColor Cyan
            }
            elseif ($path -eq "/api/plex/status" -and $method -eq "GET") {
                # Statut de Plex Media Server
                $plexStatus = Get-PlexStatus -ServerName $serverName
                $responseString = $plexStatus | ConvertTo-Json
                $response.StatusCode = 200
                Write-Host "    → Plex Status - 200 OK" -ForegroundColor Green
                Write-Host "      Plex en cours: $($plexStatus.plex_running)" -ForegroundColor White
            }
            elseif ($path -eq "/api/plex/start" -and $method -eq "POST") {
                # Démarrer Plex Media Server
                if ($isAdmin) {
                    $startResult = Start-Plex -ServerName $serverName -ClientIP $clientIP
                    $responseString = $startResult | ConvertTo-Json
                    $response.StatusCode = if ($startResult.success) { 200 } else { 500 }
                    
                    if ($startResult.success) {
                        Write-Host "    → Plex Start - 200 OK" -ForegroundColor Green
                        if ($startResult.action_taken -eq "started") {
                            Write-Host "      PLEX MEDIA SERVER DEMARRE" -ForegroundColor Green
                        } else {
                            Write-Host "      Plex etait deja en cours" -ForegroundColor Yellow
                        }
                    } else {
                        Write-Host "    → Plex Start - 500 Error" -ForegroundColor Red
                    }
                } else {
                    $responseString = @{
                        success = $false
                        message = "Administrator privileges required to start Plex"
                    } | ConvertTo-Json
                    $response.StatusCode = 403
                    Write-Host "    → Plex Start - 403 Forbidden" -ForegroundColor Red
                }
            }
            elseif ($path -eq "/api/plex/stop" -and $method -eq "POST") {
                # Arrêter Plex Media Server
                if ($isAdmin) {
                    $stopResult = Stop-Plex -ServerName $serverName -ClientIP $clientIP
                    $responseString = $stopResult | ConvertTo-Json
                    $response.StatusCode = if ($stopResult.success) { 200 } else { 500 }
                    
                    if ($stopResult.success) {
                        Write-Host "    → Plex Stop - 200 OK" -ForegroundColor Red
                        if ($stopResult.action_taken -ne "none") {
                            Write-Host "      PLEX MEDIA SERVER ARRETE" -ForegroundColor Red
                        } else {
                            Write-Host "      Plex n'etait pas en cours" -ForegroundColor Yellow
                        }
                    } else {
                        Write-Host "    → Plex Stop - 500 Error" -ForegroundColor Red
                    }
                } else {
                    $responseString = @{
                        success = $false
                        message = "Administrator privileges required to stop Plex"
                    } | ConvertTo-Json
                    $response.StatusCode = 403
                    Write-Host "    → Plex Stop - 403 Forbidden" -ForegroundColor Red
                }
            }
            elseif ($path -eq "/api/plex/restart" -and $method -eq "POST") {
                # Redémarrer Plex Media Server
                if ($isAdmin) {
                    $restartResult = Restart-Plex -ServerName $serverName -ClientIP $clientIP
                    $responseString = $restartResult | ConvertTo-Json
                    $response.StatusCode = if ($restartResult.success) { 200 } else { 500 }
                    
                    if ($restartResult.success) {
                        Write-Host "    → Plex Restart - 200 OK" -ForegroundColor Cyan
                        Write-Host "      PLEX MEDIA SERVER REDEMARRE" -ForegroundColor Cyan
                    } else {
                        Write-Host "    → Plex Restart - 500 Error" -ForegroundColor Red
                    }
                } else {
                    $responseString = @{
                        success = $false
                        message = "Administrator privileges required to restart Plex"
                    } | ConvertTo-Json
                    $response.StatusCode = 403
                    Write-Host "    → Plex Restart - 403 Forbidden" -ForegroundColor Red
                }
            }
            else {
                # Endpoint non trouvé
                $responseString = @{
                    error = "Endpoint not found"
                    available_endpoints = @(
                        "GET /api/status",
                        "POST /api/shutdown", 
                        "POST /api/restart",
                        "POST /api/cancel",
                        "GET /api/test",
                        "GET /api/plex/status",
                        "POST /api/plex/start",
                        "POST /api/plex/stop",
                        "POST /api/plex/restart"
                    )
                } | ConvertTo-Json
                
                $response.StatusCode = 404
                Write-Host "    → $path - 404 Not Found" -ForegroundColor DarkRed
            }
            
            # Envoyer la réponse
            if ($responseString) {
                $response.ContentType = "application/json; charset=utf-8"
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseString)
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
            }
            
            $response.Close()
        } catch [System.OperationCanceledException] {
            # Exception normale lors de l'arrêt
            Write-Host "Arret en cours..." -ForegroundColor Yellow
            break
        } catch {
            if (-not $global:shouldStop) {
                Write-Host "Erreur dans la boucle principale: $($_.Exception.Message)" -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
    
    Write-Host "Fermeture du service..." -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host "Erreur lors du demarrage du service:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    
    if ($_.Exception.Message -like "*access*denied*" -or $_.Exception.Message -like "*The requested address is not valid*") {
        Write-Host "Solutions possibles:" -ForegroundColor Yellow
        Write-Host "   1. Exécuter ce script en tant qu'administrateur" -ForegroundColor White
        Write-Host "   2. Configurer le pare-feu Windows pour autoriser le port $port" -ForegroundColor White
        Write-Host "   3. Exécuter: netsh http add urlacl url=http://+:$port/ user=Everyone" -ForegroundColor White
    }
    
    Read-Host "Appuyez sur Entrée pour fermer"
}
finally {
    Write-Host ""
    if ($listener -and $listener.IsListening) {
        $listener.Stop()
        Write-Host "Service API arrete proprement." -ForegroundColor Green
    } else {
        Write-Host "Service deja arrete." -ForegroundColor Yellow
    }
    
    # Nettoyer les gestionnaires d'evenements
    try {
        Unregister-Event -SourceIdentifier PowerShell.Exiting -ErrorAction SilentlyContinue
    } catch {
        # Ignorer les erreurs de nettoyage
    }
    
    Write-Host "Au revoir !" -ForegroundColor Cyan
    
    # Fermeture automatique dans 2 secondes
    Write-Host "Fermeture automatique dans 2 secondes..." -ForegroundColor Gray
    Start-Sleep -Seconds 2
    exit
}