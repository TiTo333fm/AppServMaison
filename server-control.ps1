# Module PowerShell - Gestion du serveur
# server-control.ps1
# Fonctions pour contrôler le serveur (arrêt/redémarrage)

$ErrorActionPreference = "Stop"

# Fonction pour vérifier les privilèges administrateur
function Test-IsAdmin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Fonction pour obtenir le statut du serveur
function Get-ServerStatus {
    param(
        [string]$ServerName = $env:COMPUTERNAME
    )
    
    try {
        $computerInfo = Get-ComputerInfo -Property TotalPhysicalMemory, CsProcessors, WindowsVersion -ErrorAction SilentlyContinue
        $uptime = (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
        
        $status = @{
            status = "online"
            server = $ServerName
            ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -ne "Loopback Pseudo-Interface 1" } | Select-Object -First 1).IPAddress
            timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            uptime_hours = [math]::Round($uptime.TotalHours, 1)
            os = "$($computerInfo.WindowsVersion)"
            memory_gb = [math]::Round($computerInfo.TotalPhysicalMemory / 1GB, 1)
            is_admin = (Test-IsAdmin)
        }
        
        return $status
    } catch {
        return @{
            status = "error"
            server = $ServerName
            error = $_.Exception.Message
            timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        }
    }
}

# Fonction pour arrêter le serveur
function Stop-Server {
    param(
        [string]$ServerName = $env:COMPUTERNAME,
        [string]$ClientIP = "unknown",
        [int]$DelaySeconds = 15
    )
    
    if (-not (Test-IsAdmin)) {
        return @{
            success = $false
            message = "Administrator privileges required for server shutdown"
            error = "Insufficient privileges"
        }
    }
    
    try {
        $shutdownCommand = "shutdown.exe /s /t $DelaySeconds /c `"Arrêt demandé par AppServMaison depuis $ClientIP`""
        Write-Host "  Exécution: $shutdownCommand" -ForegroundColor Gray
        
        Invoke-Expression $shutdownCommand
        
        return @{
            success = $true
            message = "Server shutdown initiated successfully"
            server = $ServerName
            delay_seconds = $DelaySeconds
            command_executed = $shutdownCommand
        }
    } catch {
        return @{
            success = $false
            message = "Shutdown command failed"
            error = $_.Exception.Message
        }
    }
}

# Fonction pour redémarrer le serveur
function Restart-Server {
    param(
        [string]$ServerName = $env:COMPUTERNAME,
        [string]$ClientIP = "unknown",
        [int]$DelaySeconds = 15
    )
    
    if (-not (Test-IsAdmin)) {
        return @{
            success = $false
            message = "Administrator privileges required for server restart"
            error = "Insufficient privileges"
        }
    }
    
    try {
        $restartCommand = "shutdown.exe /r /t $DelaySeconds /c `"Redémarrage demandé par AppServMaison depuis $ClientIP`""
        Write-Host "  Exécution: $restartCommand" -ForegroundColor Gray
        
        Invoke-Expression $restartCommand
        
        return @{
            success = $true
            message = "Server restart initiated successfully"
            server = $ServerName
            delay_seconds = $DelaySeconds
            command_executed = $restartCommand
        }
    } catch {
        return @{
            success = $false
            message = "Restart command failed"
            error = $_.Exception.Message
        }
    }
}

# Fonction pour annuler un arrêt/redémarrage
function Stop-ServerShutdown {
    param(
        [string]$ServerName = $env:COMPUTERNAME
    )
    
    if (-not (Test-IsAdmin)) {
        return @{
            success = $false
            message = "Administrator privileges required to cancel shutdown"
            error = "Insufficient privileges"
        }
    }
    
    try {
        $cancelCommand = "shutdown.exe /a"
        Write-Host "  Exécution: $cancelCommand" -ForegroundColor Gray
        
        Invoke-Expression $cancelCommand
        
        return @{
            success = $true
            message = "Server shutdown/restart cancelled successfully"
            server = $ServerName
            command_executed = $cancelCommand
        }
    } catch {
        return @{
            success = $false
            message = "Cancel command failed (maybe no shutdown pending)"
            error = $_.Exception.Message
        }
    }
}

# Fonction de test des privilèges système
function Test-ServerPrivileges {
    param(
        [string]$ServerName = $env:COMPUTERNAME
    )
    
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $isAdmin = Test-IsAdmin
    
    $testResults = @{
        server = $ServerName
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
        } catch {
            $testResults.test_commands += "shutdown.exe /? - FAILED: $($_.Exception.Message)"
        }
    }
    
    return $testResults
}

Write-Host "Module Server-Control chargé" -ForegroundColor Green