# Test direct des commandes Plex sur le serveur local
# À exécuter directement sur SERVEUR333

Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "    Test DIRECT des commandes Plex" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan

# 1. Vérifier l'état actuel de Plex
Write-Host "1️⃣  Vérification de l'état actuel..." -ForegroundColor Yellow

$plexProcess = Get-Process -Name "Plex Media Server" -ErrorAction SilentlyContinue
if ($plexProcess) {
    Write-Host "✅ Plex Media Server est EN COURS" -ForegroundColor Green
    Write-Host "   PID: $($plexProcess.Id)" -ForegroundColor White
    Write-Host "   Chemin: $($plexProcess.Path)" -ForegroundColor White
    Write-Host "   Démarré: $($plexProcess.StartTime)" -ForegroundColor White
    
    # 2. Tenter l'arrêt
    Write-Host ""
    Write-Host "2️⃣  Tentative d'arrêt de Plex..." -ForegroundColor Yellow
    
    try {
        Write-Host "   Méthode 1: CloseMainWindow()..." -ForegroundColor Gray
        $result = $plexProcess.CloseMainWindow()
        Write-Host "   Résultat CloseMainWindow: $result" -ForegroundColor White
        
        Start-Sleep -Seconds 3
        
        # Vérifier si toujours en cours
        $stillRunning = Get-Process -Name "Plex Media Server" -ErrorAction SilentlyContinue
        if ($stillRunning) {
            Write-Host "   ⚠️  Toujours en cours, tentative Kill..." -ForegroundColor Yellow
            Stop-Process -Name "Plex Media Server" -Force
            Write-Host "   ✅ Kill forcé exécuté" -ForegroundColor Green
        } else {
            Write-Host "   ✅ Arrêt propre réussi" -ForegroundColor Green
        }
        
    } catch {
        Write-Host "   ❌ Erreur: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # 3. Vérifier l'arrêt
    Start-Sleep -Seconds 2
    $finalCheck = Get-Process -Name "Plex Media Server" -ErrorAction SilentlyContinue
    if ($finalCheck) {
        Write-Host ""
        Write-Host "❌ ÉCHEC: Plex est toujours en cours !" -ForegroundColor Red
        Write-Host "   Processus restant: PID $($finalCheck.Id)" -ForegroundColor Red
    } else {
        Write-Host ""
        Write-Host "✅ SUCCÈS: Plex est maintenant arrêté !" -ForegroundColor Green
        
        # 4. Tenter le redémarrage
        Write-Host ""
        Write-Host "3️⃣  Tentative de redémarrage..." -ForegroundColor Yellow
        
        $plexPath = "C:\Program Files\Plex\Plex Media Server\Plex Media Server.exe"
        if (Test-Path $plexPath) {
            try {
                $newProcess = Start-Process $plexPath -PassThru
                Write-Host "   ✅ Redémarrage lancé (PID: $($newProcess.Id))" -ForegroundColor Green
                
                Start-Sleep -Seconds 5
                $restartCheck = Get-Process -Name "Plex Media Server" -ErrorAction SilentlyContinue
                if ($restartCheck) {
                    Write-Host "   ✅ Plex redémarré avec succès !" -ForegroundColor Green
                } else {
                    Write-Host "   ⚠️  Plex ne semble pas avoir redémarré" -ForegroundColor Yellow
                }
            } catch {
                Write-Host "   ❌ Erreur de redémarrage: $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Write-Host "   ❌ Exécutable Plex non trouvé: $plexPath" -ForegroundColor Red
        }
    }
    
} else {
    Write-Host "❌ Plex Media Server n'est PAS en cours" -ForegroundColor Red
    Write-Host "   Tentative de démarrage..." -ForegroundColor Yellow
    
    $plexPath = "C:\Program Files\Plex\Plex Media Server\Plex Media Server.exe"
    if (Test-Path $plexPath) {
        try {
            $newProcess = Start-Process $plexPath -PassThru
            Write-Host "   ✅ Démarrage lancé (PID: $($newProcess.Id))" -ForegroundColor Green
        } catch {
            Write-Host "   ❌ Erreur de démarrage: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "   ❌ Exécutable Plex non trouvé: $plexPath" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "Test terminé" -ForegroundColor Green
Write-Host ""
Read-Host "Appuyez sur Entrée pour fermer"