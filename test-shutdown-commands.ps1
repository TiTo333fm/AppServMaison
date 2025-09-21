# Test des commandes d'arrêt/redémarrage
# Script de diagnostic pour AppServMaison

Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "    Test des commandes système" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan

# Vérifier les privilèges administrateur
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

Write-Host "Utilisateur actuel: $($currentUser.Name)" -ForegroundColor Green
Write-Host "Privilèges admin: $isAdmin" -ForegroundColor $(if ($isAdmin) {"Green"} else {"Red"})
Write-Host ""

if (-not $isAdmin) {
    Write-Host "⚠️  Ce script doit être exécuté en tant qu'administrateur pour tester les commandes d'arrêt" -ForegroundColor Red
    Write-Host ""
}

# Test 1: Vérifier si shutdown.exe est accessible
Write-Host "Test 1: Vérification de shutdown.exe" -ForegroundColor Yellow
try {
    $shutdownPath = where.exe shutdown
    Write-Host "  ✅ shutdown.exe trouvé: $shutdownPath" -ForegroundColor Green
    
    # Tester l'aide de shutdown
    $shutdownHelp = shutdown.exe /? 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ shutdown.exe répond correctement" -ForegroundColor Green
    } else {
        Write-Host "  ❌ shutdown.exe retourne une erreur (code: $LASTEXITCODE)" -ForegroundColor Red
    }
}
catch {
    Write-Host "  ❌ Erreur: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 2: Test des différentes méthodes d'exécution
Write-Host "Test 2: Méthodes d'exécution (TEST UNIQUEMENT - PAS D'ARRÊT RÉEL)" -ForegroundColor Yellow

if ($isAdmin) {
    Write-Host "  Test avec Invoke-Expression:" -ForegroundColor Cyan
    try {
        # Commande de test (liste les tâches en cours d'arrêt)
        $testCommand = "shutdown.exe /a"  # Annule les arrêts en cours (safe)
        Write-Host "    Commande: $testCommand" -ForegroundColor Gray
        Invoke-Expression $testCommand
        Write-Host "    ✅ Invoke-Expression fonctionne" -ForegroundColor Green
    }
    catch {
        Write-Host "    ❌ Invoke-Expression: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host "  Test avec Start-Process:" -ForegroundColor Cyan
    try {
        $process = Start-Process "shutdown.exe" -ArgumentList "/a" -PassThru -Wait
        Write-Host "    ✅ Start-Process fonctionne (code de sortie: $($process.ExitCode))" -ForegroundColor Green
    }
    catch {
        Write-Host "    ❌ Start-Process: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host "  Test avec cmd.exe:" -ForegroundColor Cyan
    try {
        $process = Start-Process "cmd.exe" -ArgumentList "/c", "shutdown.exe /a" -PassThru -Wait
        Write-Host "    ✅ cmd.exe fonctionne (code de sortie: $($process.ExitCode))" -ForegroundColor Green
    }
    catch {
        Write-Host "    ❌ cmd.exe: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "  ⚠️  Tests d'exécution ignorés (privilèges administrateur requis)" -ForegroundColor Yellow
}

Write-Host ""

# Test 3: Vérification des politiques de sécurité
Write-Host "Test 3: Politiques de sécurité" -ForegroundColor Yellow
try {
    $executionPolicy = Get-ExecutionPolicy
    Write-Host "  Politique d'exécution PowerShell: $executionPolicy" -ForegroundColor Green
    
    if ($executionPolicy -eq "Restricted") {
        Write-Host "  ⚠️  La politique Restricted peut bloquer certaines commandes" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "  ❌ Impossible de vérifier la politique: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 4: Variables d'environnement importantes
Write-Host "Test 4: Variables d'environnement" -ForegroundColor Yellow
$importantVars = @("PATH", "SYSTEMROOT", "WINDIR")
foreach ($var in $importantVars) {
    $value = [Environment]::GetEnvironmentVariable($var)
    if ($value) {
        Write-Host "  $var : $value" -ForegroundColor Green
    } else {
        Write-Host "  $var : NON DÉFINIE" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "Diagnostic terminé" -ForegroundColor Green

if (-not $isAdmin) {
    Write-Host ""
    Write-Host "💡 Pour tester complètement:" -ForegroundColor Yellow
    Write-Host "   1. Exécutez ce script en tant qu'administrateur" -ForegroundColor White
    Write-Host "   2. Vérifiez les logs du service API" -ForegroundColor White
    Write-Host "   3. Testez avec l'endpoint /api/test" -ForegroundColor White
}

Write-Host ""
Read-Host "Appuyez sur Entrée pour continuer"