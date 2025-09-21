# AppServMaison API Service pour SERVEUR333
# Service REST pour contrôler le serveur à distance
# Exécuter en tant qu'administrateur

$serverName = "SERVEUR333"
$serverIp = "192.168.1.175"
$port = 8080

Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "    AppServMaison API Service" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "Serveur: $serverName" -ForegroundColor Green
Write-Host "Adresse IP: $serverIp" -ForegroundColor Green
Write-Host "Port: $port" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Cyan

# Vérifier les privilèges administrateur
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "⚠️  ATTENTION: Ce script doit être exécuté en tant qu'administrateur" -ForegroundColor Red
    Write-Host "   pour pouvoir arrêter/redémarrer le serveur." -ForegroundColor Red
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

# Écouter sur toutes les interfaces réseau
$listener.Prefixes.Add("http://*:$port/")

# Alternative si la première ne fonctionne pas :
# $listener.Prefixes.Add("http://0.0.0.0:$port/")
# $listener.Prefixes.Add("http://$serverIp`:$port/")

try {
    $listener.Start()
    Write-Host ""
    Write-Host "✅ Service API démarré avec succès !" -ForegroundColor Green
    Write-Host ""
    Write-Host "Endpoints disponibles:" -ForegroundColor Yellow
    Write-Host "  GET  http://$serverIp`:$port/api/status     - Vérifier le statut" -ForegroundColor White
    Write-Host "  POST http://$serverIp`:$port/api/shutdown   - Arrêt du serveur" -ForegroundColor White
    Write-Host "  POST http://$serverIp`:$port/api/restart    - Redémarrage du serveur" -ForegroundColor White
    Write-Host "  POST http://$serverIp`:$port/api/cancel     - Annuler un arrêt/redémarrage" -ForegroundColor White
    Write-Host "  GET  http://$serverIp`:$port/api/test       - Test des privilèges système" -ForegroundColor White
    Write-Host "" -ForegroundColor Yellow
    Write-Host "  Endpoints Plex Media Server:" -ForegroundColor Cyan
    Write-Host "  GET  http://$serverIp`:$port/api/plex/status - Statut de Plex" -ForegroundColor White
    Write-Host "  POST http://$serverIp`:$port/api/plex/start  - Démarrer Plex" -ForegroundColor White
    Write-Host "  POST http://$serverIp`:$port/api/plex/stop   - Arrêter Plex" -ForegroundColor White
    Write-Host ""
    Write-Host "Configuration de l'application mobile:" -ForegroundColor Yellow
    Write-Host "  IP Serveur: $serverIp" -ForegroundColor White
    Write-Host "  Port: $port" -ForegroundColor White
    Write-Host ""
    Write-Host "Appuyez sur Ctrl+C pour arrêter le service..." -ForegroundColor Cyan
    Write-Host ""

    while ($listener.IsListening -and -not $global:shouldStop) {
        try {
            # Vérifier si on peut récupérer le contexte avec un timeout
            $asyncContext = $listener.GetContextAsync()
            if ($asyncContext.Wait(1000)) {
                # Une requête est arrivée
                $context = $asyncContext.Result
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
        $response.Headers.Add("Server", "AppServMaison-API/1.0")
        
        $responseString = ""
        
        if ($method -eq "OPTIONS") {
            # Réponse aux requêtes preflight CORS
            $response.StatusCode = 200
            Write-Host "    → OPTIONS (CORS preflight) - 200 OK" -ForegroundColor DarkGray
        }
        elseif ($path -eq "/api/status" -and $method -eq "GET") {
            # Status du serveur
            $computerInfo = Get-ComputerInfo -Property TotalPhysicalMemory, CsProcessors, WindowsVersion -ErrorAction SilentlyContinue
            $uptime = (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
            
            $status = @{
                status = "online"
                server = $serverName
                ip = $serverIp
                timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                uptime_hours = [math]::Round($uptime.TotalHours, 1)
                os = "$($computerInfo.WindowsVersion)"
                memory_gb = [math]::Round($computerInfo.TotalPhysicalMemory / 1GB, 1)
            }
            
            $responseString = $status | ConvertTo-Json
            $response.StatusCode = 200
            Write-Host "    → Status check - 200 OK" -ForegroundColor Green
        }
        elseif ($path -eq "/api/shutdown" -and $method -eq "POST") {
            # Arrêt du serveur
            if ($isAdmin) {
                try {
                    # Méthode 1: Commande shutdown directe (plus fiable)
                    $shutdownCommand = "shutdown.exe /s /t 15 /c `"Arrêt demandé par AppServMaison depuis $clientIP`""
                    Write-Host "      Exécution: $shutdownCommand" -ForegroundColor Gray
                    
                    # Exécuter directement la commande
                    Invoke-Expression $shutdownCommand
                    
                    # Alternative: Utiliser cmd.exe pour plus de compatibilité
                    # Start-Process "cmd.exe" -ArgumentList "/c", $shutdownCommand -WindowStyle Hidden
                    
                    $responseString = @{
                        message = "Shutdown initiated successfully"
                        server = $serverName
                        success = $true
                        delay_seconds = 15
                        command_executed = $shutdownCommand
                    } | ConvertTo-Json
                    
                    $response.StatusCode = 200
                    Write-Host "    → Shutdown request - 200 OK" -ForegroundColor Red
                    Write-Host "      🚨 ARRÊT DU SERVEUR dans 15 secondes..." -ForegroundColor Red
                }
                catch {
                    Write-Host "      ❌ Erreur lors de l'exécution du shutdown: $($_.Exception.Message)" -ForegroundColor Red
                    
                    $responseString = @{
                        message = "Shutdown command failed"
                        error = $_.Exception.Message
                        success = $false
                    } | ConvertTo-Json
                    
                    $response.StatusCode = 500
                }
            } else {
                $responseString = @{
                    message = "Shutdown requires administrator privileges"
                    success = $false
                } | ConvertTo-Json
                
                $response.StatusCode = 403
                Write-Host "    → Shutdown request - 403 Forbidden (pas admin)" -ForegroundColor Red
            }
        }
        elseif ($path -eq "/api/restart" -and $method -eq "POST") {
            # Redémarrage du serveur
            if ($isAdmin) {
                try {
                    # Méthode 1: Commande shutdown directe (plus fiable)
                    $restartCommand = "shutdown.exe /r /t 15 /c `"Redémarrage demandé par AppServMaison depuis $clientIP`""
                    Write-Host "      Exécution: $restartCommand" -ForegroundColor Gray
                    
                    # Exécuter directement la commande
                    Invoke-Expression $restartCommand
                    
                    # Alternative: Utiliser cmd.exe pour plus de compatibilité
                    # Start-Process "cmd.exe" -ArgumentList "/c", $restartCommand -WindowStyle Hidden
                    
                    $responseString = @{
                        message = "Restart initiated successfully"
                        server = $serverName
                        success = $true
                        delay_seconds = 15
                        command_executed = $restartCommand
                    } | ConvertTo-Json
                    
                    $response.StatusCode = 200
                    Write-Host "    → Restart request - 200 OK" -ForegroundColor Yellow
                    Write-Host "      🔄 REDÉMARRAGE DU SERVEUR dans 15 secondes..." -ForegroundColor Yellow
                }
                catch {
                    Write-Host "      ❌ Erreur lors de l'exécution du restart: $($_.Exception.Message)" -ForegroundColor Red
                    
                    $responseString = @{
                        message = "Restart command failed"
                        error = $_.Exception.Message
                        success = $false
                    } | ConvertTo-Json
                    
                    $response.StatusCode = 500
                }
            } else {
                $responseString = @{
                    message = "Restart requires administrator privileges"
                    success = $false
                } | ConvertTo-Json
                
                $response.StatusCode = 403
                Write-Host "    → Restart request - 403 Forbidden (pas admin)" -ForegroundColor Red
            }
        }
        elseif ($path -eq "/api/cancel" -and $method -eq "POST") {
            # Annuler un arrêt/redémarrage en cours
            if ($isAdmin) {
                try {
                    $cancelCommand = "shutdown.exe /a"
                    Write-Host "      Exécution: $cancelCommand" -ForegroundColor Gray
                    
                    Invoke-Expression $cancelCommand
                    
                    $responseString = @{
                        message = "Shutdown/Restart cancelled successfully"
                        server = $serverName
                        success = $true
                        command_executed = $cancelCommand
                    } | ConvertTo-Json
                    
                    $response.StatusCode = 200
                    Write-Host "    → Cancel request - 200 OK" -ForegroundColor Green
                    Write-Host "      ✅ ANNULATION de l'arrêt/redémarrage" -ForegroundColor Green
                }
                catch {
                    Write-Host "      ❌ Erreur lors de l'annulation: $($_.Exception.Message)" -ForegroundColor Red
                    
                    $responseString = @{
                        message = "Cancel command failed (maybe no shutdown pending)"
                        error = $_.Exception.Message
                        success = $false
                    } | ConvertTo-Json
                    
                    $response.StatusCode = 500
                }
            } else {
                $responseString = @{
                    message = "Cancel requires administrator privileges"
                    success = $false
                } | ConvertTo-Json
                
                $response.StatusCode = 403
                Write-Host "    → Cancel request - 403 Forbidden (pas admin)" -ForegroundColor Red
            }
        }
        elseif ($path -eq "/api/test" -and $method -eq "GET") {
            # Test des privilèges et commandes système
            $testResults = @{
                server = $serverName
                timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                is_admin = $isAdmin
                current_user = $currentUser.Name
                shutdown_available = $false
                test_commands = @()
            }
            
            if ($isAdmin) {
                try {
                    # Test si la commande shutdown est accessible
                    $shutdownHelp = shutdown.exe /?
                    $testResults.shutdown_available = $true
                    $testResults.test_commands += "shutdown.exe /? - OK"
                }
                catch {
                    $testResults.test_commands += "shutdown.exe /? - FAILED: $($_.Exception.Message)"
                }
            }
            
            $responseString = $testResults | ConvertTo-Json
            $response.StatusCode = 200
            Write-Host "    → Test request - 200 OK" -ForegroundColor Cyan
        }
        elseif ($path -eq "/api/plex/status" -and $method -eq "GET") {
            # Statut de Plex Media Server
            $plexProcess = Get-Process -Name "Plex Media Server" -ErrorAction SilentlyContinue
            $plexUpdateService = Get-Service -Name "PlexUpdateService" -ErrorAction SilentlyContinue
            
            $plexStatus = @{
                timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                server = $serverName
                plex_running = ($plexProcess -ne $null)
                port_32400_open = $false
                update_service_status = if ($plexUpdateService) { $plexUpdateService.Status.ToString() } else { "NotFound" }
            }
            
            if ($plexProcess) {
                $plexStatus.process_id = $plexProcess.Id
                $plexStatus.process_path = $plexProcess.Path
                $plexStatus.start_time = $plexProcess.StartTime.ToString("yyyy-MM-dd HH:mm:ss")
            }
            
            # Test du port 32400
            try {
                $connection = Test-NetConnection -ComputerName "localhost" -Port 32400 -InformationLevel Quiet -WarningAction SilentlyContinue
                $plexStatus.port_32400_open = $connection
            } catch {
                $plexStatus.port_32400_open = $false
            }
            
            $responseString = $plexStatus | ConvertTo-Json
            $response.StatusCode = 200
            Write-Host "    → Plex Status check - 200 OK" -ForegroundColor Green
            Write-Host "      Plex en cours: $($plexStatus.plex_running)" -ForegroundColor White
        }
        elseif ($path -eq "/api/plex/stop" -and $method -eq "POST") {
            # Arrêter Plex Media Server
            if ($isAdmin) {
                try {
                    $plexProcess = Get-Process -Name "Plex Media Server" -ErrorAction SilentlyContinue
                    
                    if ($plexProcess) {
                        Write-Host "      Arrêt de Plex Media Server (PID: $($plexProcess.Id))..." -ForegroundColor Gray
                        $plexProcess.CloseMainWindow()
                        
                        # Attendre un peu pour l'arrêt propre
                        Start-Sleep -Seconds 2
                        
                        # Vérifier si le processus s'est arrêté
                        $stillRunning = Get-Process -Name "Plex Media Server" -ErrorAction SilentlyContinue
                        if ($stillRunning) {
                            Write-Host "      Forçage de l'arrêt..." -ForegroundColor Yellow
                            Stop-Process -Name "Plex Media Server" -Force
                        }
                        
                        $responseString = @{
                            message = "Plex Media Server stopped successfully"
                            server = $serverName
                            success = $true
                            previous_pid = $plexProcess.Id
                        } | ConvertTo-Json
                        
                        $response.StatusCode = 200
                        Write-Host "    → Plex Stop request - 200 OK" -ForegroundColor Red
                        Write-Host "      🛑 PLEX MEDIA SERVER ARRÊTÉ" -ForegroundColor Red
                    } else {
                        $responseString = @{
                            message = "Plex Media Server was not running"
                            success = $false
                            server = $serverName
                        } | ConvertTo-Json
                        
                        $response.StatusCode = 200
                        Write-Host "    → Plex Stop request - 200 OK (already stopped)" -ForegroundColor Yellow
                    }
                }
                catch {
                    Write-Host "      ❌ Erreur lors de l'arrêt de Plex: $($_.Exception.Message)" -ForegroundColor Red
                    
                    $responseString = @{
                        message = "Failed to stop Plex Media Server"
                        error = $_.Exception.Message
                        success = $false
                    } | ConvertTo-Json
                    
                    $response.StatusCode = 500
                }
            } else {
                $responseString = @{
                    message = "Plex stop requires administrator privileges"
                    success = $false
                } | ConvertTo-Json
                
                $response.StatusCode = 403
                Write-Host "    → Plex Stop request - 403 Forbidden (pas admin)" -ForegroundColor Red
            }
        }
        elseif ($path -eq "/api/plex/start" -and $method -eq "POST") {
            # Démarrer Plex Media Server
            if ($isAdmin) {
                try {
                    $plexProcess = Get-Process -Name "Plex Media Server" -ErrorAction SilentlyContinue
                    
                    if ($plexProcess) {
                        $responseString = @{
                            message = "Plex Media Server is already running"
                            server = $serverName
                            success = $true
                            current_pid = $plexProcess.Id
                        } | ConvertTo-Json
                        
                        $response.StatusCode = 200
                        Write-Host "    → Plex Start request - 200 OK (already running)" -ForegroundColor Yellow
                        Write-Host "      ℹ️  Plex déjà en cours (PID: $($plexProcess.Id))" -ForegroundColor Yellow
                    } else {
                        $plexPath = "C:\Program Files\Plex\Plex Media Server\Plex Media Server.exe"
                        
                        if (Test-Path $plexPath) {
                            Write-Host "      Démarrage de Plex Media Server..." -ForegroundColor Gray
                            Write-Host "      Exécutable: $plexPath" -ForegroundColor Gray
                            
                            $startedProcess = Start-Process $plexPath -PassThru
                            Start-Sleep -Seconds 3  # Laisser le temps au processus de démarrer
                            
                            $responseString = @{
                                message = "Plex Media Server started successfully"
                                server = $serverName
                                success = $true
                                new_pid = $startedProcess.Id
                                executable_path = $plexPath
                            } | ConvertTo-Json
                            
                            $response.StatusCode = 200
                            Write-Host "    → Plex Start request - 200 OK" -ForegroundColor Green
                            Write-Host "      ✅ PLEX MEDIA SERVER DÉMARRÉ (PID: $($startedProcess.Id))" -ForegroundColor Green
                        } else {
                            $responseString = @{
                                message = "Plex Media Server executable not found"
                                expected_path = $plexPath
                                success = $false
                            } | ConvertTo-Json
                            
                            $response.StatusCode = 404
                            Write-Host "    → Plex Start request - 404 Not Found (exe manquant)" -ForegroundColor Red
                        }
                    }
                }
                catch {
                    Write-Host "      ❌ Erreur lors du démarrage de Plex: $($_.Exception.Message)" -ForegroundColor Red
                    
                    $responseString = @{
                        message = "Failed to start Plex Media Server"
                        error = $_.Exception.Message
                        success = $false
                    } | ConvertTo-Json
                    
                    $response.StatusCode = 500
                }
            } else {
                $responseString = @{
                    message = "Plex start requires administrator privileges"
                    success = $false
                } | ConvertTo-Json
                
                $response.StatusCode = 403
                Write-Host "    → Plex Start request - 403 Forbidden (pas admin)" -ForegroundColor Red
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
                    "POST /api/plex/stop"
                )
            } | ConvertTo-Json
            
            $response.StatusCode = 404
            Write-Host "    → $path - 404 Not Found" -ForegroundColor DarkRed
        }
        
        if ($responseString) {
            $response.ContentType = "application/json; charset=utf-8"
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseString)
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        
        $response.Close()
            } else {
                # Pas de requête en attente, vérifier si on doit s'arrêter
                if ($global:shouldStop) {
                    Write-Host ""
                    Write-Host "🛑 Arrêt demandé par l'utilisateur" -ForegroundColor Yellow
                    break
                }
                
                Start-Sleep -Milliseconds 100  # Petite pause pour éviter la surcharge CPU
            }
        } catch [System.OperationCanceledException] {
            # Exception normale lors de l'arrêt
            Write-Host "🛑 Arrêt en cours..." -ForegroundColor Yellow
            break
        } catch {
            if (-not $global:shouldStop) {
                Write-Host "❌ Erreur dans la boucle principale: $($_.Exception.Message)" -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
    
    Write-Host "🏁 Fermeture du service..." -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host "❌ Erreur lors du démarrage du service:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    
    if ($_.Exception.Message -like "*access*denied*" -or $_.Exception.Message -like "*The requested address is not valid*") {
        Write-Host "💡 Solutions possibles:" -ForegroundColor Yellow
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
        Write-Host "✅ Service API arrêté proprement." -ForegroundColor Green
    } else {
        Write-Host "ℹ️  Service déjà arrêté." -ForegroundColor Yellow
    }
    
    # Nettoyer les gestionnaires d'événements
    try {
        Unregister-Event -SourceIdentifier PowerShell.Exiting -ErrorAction SilentlyContinue
    } catch {
        # Ignorer les erreurs de nettoyage
    }
    
    Write-Host "Au revoir ! 👋" -ForegroundColor Cyan
}