# Module PowerShell - Gestion Plex Media Server
# plex-control.ps1
# Fonctions pour contrôler Plex Media Server

$ErrorActionPreference = "Stop"

# Configuration Plex par défaut
$script:PlexInstallPath = "C:\Program Files\Plex\Plex Media Server\Plex Media Server.exe"
$script:PlexProcessName = "Plex Media Server"
$script:PlexMainPort = 32400

# Fonction pour obtenir le statut de Plex
function Get-PlexStatus {
    param(
        [string]$ServerName = $env:COMPUTERNAME
    )
    
    try {
        $plexProcess = Get-Process -Name $script:PlexProcessName -ErrorAction SilentlyContinue
        $plexUpdateService = Get-Service -Name "PlexUpdateService" -ErrorAction SilentlyContinue
        
        $plexStatus = @{
            timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            server = $ServerName
            plex_running = ($plexProcess -ne $null)
            port_32400_open = $false
            update_service_status = if ($plexUpdateService) { $plexUpdateService.Status.ToString() } else { "NotFound" }
            install_path = $script:PlexInstallPath
            install_path_exists = (Test-Path $script:PlexInstallPath)
        }
        
        if ($plexProcess) {
            $plexStatus.process_id = $plexProcess.Id
            $plexStatus.process_path = $plexProcess.Path
            $plexStatus.start_time = $plexProcess.StartTime.ToString("yyyy-MM-dd HH:mm:ss")
            $plexStatus.working_set_mb = [math]::Round($plexProcess.WorkingSet / 1MB, 1)
        }
        
        # Test du port 32400
        try {
            $connection = Test-NetConnection -ComputerName "localhost" -Port $script:PlexMainPort -InformationLevel Quiet -WarningAction SilentlyContinue
            $plexStatus.port_32400_open = $connection
        } catch {
            $plexStatus.port_32400_open = $false
        }
        
        return $plexStatus
    } catch {
        return @{
            timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            server = $ServerName
            plex_running = $false
            error = $_.Exception.Message
        }
    }
}

# Fonction pour démarrer Plex
function Start-Plex {
    param(
        [string]$ServerName = $env:COMPUTERNAME,
        [string]$ClientIP = "unknown"
    )
    
    Write-Host "  Tentative de démarrage de Plex..." -ForegroundColor Gray
    
    try {
        # Vérifier si Plex est déjà en cours
        $plexProcess = Get-Process -Name $script:PlexProcessName -ErrorAction SilentlyContinue
        
        if ($plexProcess) {
            Write-Host "  Plex déjà en cours (PID: $($plexProcess.Id))" -ForegroundColor Yellow
            return @{
                success = $true
                message = "Plex Media Server is already running"
                server = $ServerName
                current_pid = $plexProcess.Id
                action_taken = "none"
            }
        }
        
        # Vérifier que l'exécutable existe
        if (-not (Test-Path $script:PlexInstallPath)) {
            Write-Host "  Exécutable Plex introuvable: $script:PlexInstallPath" -ForegroundColor Red
            return @{
                success = $false
                message = "Plex Media Server executable not found"
                expected_path = $script:PlexInstallPath
                server = $ServerName
            }
        }
        
        # Démarrer Plex
        Write-Host "  Démarrage de Plex Media Server..." -ForegroundColor Green
        Write-Host "     Exécutable: $script:PlexInstallPath" -ForegroundColor Gray
        
        $startedProcess = Start-Process $script:PlexInstallPath -PassThru
        Start-Sleep -Seconds 3  # Laisser le temps au processus de démarrer
        
        # Vérifier que le processus est bien démarré
        $verifyProcess = Get-Process -Id $startedProcess.Id -ErrorAction SilentlyContinue
        if ($verifyProcess) {
            Write-Host "  Plex Media Server démarré (PID: $($startedProcess.Id))" -ForegroundColor Green
            return @{
                success = $true
                message = "Plex Media Server started successfully"
                server = $ServerName
                new_pid = $startedProcess.Id
                executable_path = $script:PlexInstallPath
                action_taken = "started"
            }
        } else {
            return @{
                success = $false
                message = "Plex process started but verification failed"
                server = $ServerName
            }
        }
        
    } catch {
        Write-Host "  Erreur lors du démarrage de Plex: $($_.Exception.Message)" -ForegroundColor Red
        return @{
            success = $false
            message = "Failed to start Plex Media Server"
            error = $_.Exception.Message
            server = $ServerName
        }
    }
}

# Fonction pour arrêter Plex
function Stop-Plex {
    param(
        [string]$ServerName = $env:COMPUTERNAME,
        [string]$ClientIP = "unknown",
        [switch]$Force = $false
    )
    
    Write-Host "  Tentative d'arrêt de Plex..." -ForegroundColor Gray
    
    try {
        $plexProcess = Get-Process -Name $script:PlexProcessName -ErrorAction SilentlyContinue
        
        if ($null -eq $plexProcess) {
            Write-Host "  Plex n'était pas en cours d'exécution" -ForegroundColor Yellow
            return @{
                success = $true
                message = "Plex Media Server was not running"
                server = $ServerName
                action_taken = "none"
            }
        }
        
        $originalPid = $plexProcess.Id
        Write-Host "  Arrêt de Plex Media Server (PID: $originalPid)..." -ForegroundColor Red
        
        if ($Force) {
            # Arrêt forcé immédiat
            Write-Host "     Mode forcé activé" -ForegroundColor Yellow
            $null = Stop-Process -Name $script:PlexProcessName -Force -ErrorAction Stop
            Start-Sleep -Seconds 2
        } else {
            # Tentative d'arrêt propre
            $null = $plexProcess.CloseMainWindow()  # Capturer le résultat pour éviter la sortie
            Start-Sleep -Seconds 3
            
            # Vérifier si le processus s'est arrêté
            $stillRunning = Get-Process -Name $script:PlexProcessName -ErrorAction SilentlyContinue
            if ($null -ne $stillRunning) {
                Write-Host "     Arrêt propre échoué, forçage..." -ForegroundColor Yellow
                $null = Stop-Process -Name $script:PlexProcessName -Force -ErrorAction Stop
                Start-Sleep -Seconds 2
            }
        }
        
        # Vérification finale
        $finalCheck = Get-Process -Name $script:PlexProcessName -ErrorAction SilentlyContinue
        if ($null -eq $finalCheck) {
            Write-Host "  Plex Media Server arrêté avec succès" -ForegroundColor Green
            return @{
                success = $true
                message = "Plex Media Server stopped successfully"
                server = $ServerName
                previous_pid = $originalPid
                action_taken = if ($Force) { "force_stopped" } else { "graceful_stopped" }
            }
        } else {
            # Dernière tentative
            Write-Host "     Dernière tentative de force stop..." -ForegroundColor Yellow
            try {
                $null = Stop-Process -Id $finalCheck.Id -Force -ErrorAction Stop
                Start-Sleep -Seconds 2
                
                $lastCheck = Get-Process -Name $script:PlexProcessName -ErrorAction SilentlyContinue
                if ($null -eq $lastCheck) {
                    return @{
                        success = $true
                        message = "Plex Media Server stopped successfully (forced)"
                        server = $ServerName
                        previous_pid = $originalPid
                        action_taken = "force_stopped_final"
                    }
                } else {
                    return @{
                        success = $false
                        message = "Failed to stop Plex Media Server"
                        server = $ServerName
                        still_running = $true
                        current_pid = $lastCheck.Id
                    }
                }
            } catch {
                return @{
                    success = $false
                    message = "Failed to stop Plex Media Server"
                    server = $ServerName
                    still_running = $true
                    current_pid = $finalCheck.Id
                    error = $_.Exception.Message
                }
            }
        }
        
    } catch {
        Write-Host "  Erreur lors de l'arrêt de Plex: $($_.Exception.Message)" -ForegroundColor Red
        return @{
            success = $false
            message = "Failed to stop Plex Media Server"
            error = $_.Exception.Message
            server = $ServerName
        }
    }
}

# Fonction pour redémarrer Plex
function Restart-Plex {
    param(
        [string]$ServerName = $env:COMPUTERNAME,
        [string]$ClientIP = "unknown",
        [int]$RestartDelay = 2
    )
    
    Write-Host "  Redémarrage de Plex Media Server..." -ForegroundColor Cyan
    
    # Arrêter Plex
    $stopResult = Stop-Plex -ServerName $ServerName -ClientIP $ClientIP
    
    if (-not $stopResult.success -and $stopResult.action_taken -ne "none") {
        return @{
            success = $false
            message = "Failed to stop Plex for restart"
            stop_error = $stopResult.message
            server = $ServerName
        }
    }
    
    # Attendre avant de redémarrer
    if ($RestartDelay -gt 0) {
        Write-Host "  Attente $RestartDelay secondes avant redémarrage..." -ForegroundColor Gray
        Start-Sleep -Seconds $RestartDelay
    }
    
    # Démarrer Plex
    $startResult = Start-Plex -ServerName $ServerName -ClientIP $ClientIP
    
    return @{
        success = $startResult.success
        message = if ($startResult.success) { "Plex Media Server restarted successfully" } else { "Failed to restart Plex Media Server" }
        server = $ServerName
        stop_result = $stopResult
        start_result = $startResult
        action_taken = "restarted"
    }
}

# Fonction pour configurer le chemin d'installation Plex
function Set-PlexInstallPath {
    param(
        [string]$InstallPath
    )
    
    if (Test-Path $InstallPath) {
        $script:PlexInstallPath = $InstallPath
        Write-Host "Chemin Plex mis à jour: $InstallPath" -ForegroundColor Green
        return $true
    } else {
        Write-Host "Chemin inexistant: $InstallPath" -ForegroundColor Red
        return $false
    }
}

# Fonction pour obtenir la configuration Plex actuelle
function Get-PlexConfiguration {
    return @{
        install_path = $script:PlexInstallPath
        process_name = $script:PlexProcessName
        main_port = $script:PlexMainPort
        install_path_exists = (Test-Path $script:PlexInstallPath)
    }
}

        Write-Host "Module Plex-Control chargé" -ForegroundColor Green