# Test de connectivité directe vers SERVEUR333
# À exécuter depuis votre machine de développement

$serverIp = "192.168.1.175"
$port = 8080

Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "Test de connectivité vers SERVEUR333" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan

# Test 1: Ping basique
Write-Host "🔍 Test 1: Ping vers le serveur..." -ForegroundColor Yellow
try {
    $ping = Test-Connection -ComputerName $serverIp -Count 2 -Quiet
    if ($ping) {
        Write-Host "✅ Ping OK - Serveur accessible" -ForegroundColor Green
    } else {
        Write-Host "❌ Ping ÉCHEC - Serveur inaccessible" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Erreur ping: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 2: Port 8080
Write-Host "🔍 Test 2: Connexion TCP sur port 8080..." -ForegroundColor Yellow
try {
    $tcpClient = New-Object System.Net.Sockets.TcpClient
    $connection = $tcpClient.BeginConnect($serverIp, $port, $null, $null)
    $wait = $connection.AsyncWaitHandle.WaitOne(3000, $false)
    
    if ($wait) {
        Write-Host "✅ Port 8080 OUVERT - Connexion TCP réussie" -ForegroundColor Green
        $tcpClient.Close()
    } else {
        Write-Host "❌ Port 8080 FERMÉ - Timeout connexion TCP" -ForegroundColor Red
        $tcpClient.Close()
    }
} catch {
    Write-Host "❌ Erreur connexion TCP: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 3: Requête HTTP simple
Write-Host "🔍 Test 3: Requête HTTP vers l'API..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://$serverIp`:$port/api/status" -TimeoutSec 10 -UseBasicParsing
    Write-Host "✅ HTTP OK - Status Code: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "📄 Contenu de la réponse:" -ForegroundColor White
    Write-Host $response.Content -ForegroundColor Gray
} catch {
    Write-Host "❌ Erreur HTTP: $($_.Exception.Message)" -ForegroundColor Red
    
    # Détail de l'erreur
    if ($_.Exception.InnerException) {
        Write-Host "   Détail: $($_.Exception.InnerException.Message)" -ForegroundColor Red
    }
}

Write-Host ""

# Test 4: Telnet simulation
Write-Host "🔍 Test 4: Test Telnet simulation..." -ForegroundColor Yellow
try {
    $socket = New-Object System.Net.Sockets.Socket([System.Net.Sockets.AddressFamily]::InterNetwork, [System.Net.Sockets.SocketType]::Stream, [System.Net.Sockets.ProtocolType]::Tcp)
    $socket.SetSocketOption([System.Net.Sockets.SocketOptionLevel]::Socket, [System.Net.Sockets.SocketOptionName]::SendTimeout, 3000)
    $socket.SetSocketOption([System.Net.Sockets.SocketOptionLevel]::Socket, [System.Net.Sockets.SocketOptionName]::ReceiveTimeout, 3000)
    
    $endpoint = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Parse($serverIp), $port)
    $socket.Connect($endpoint)
    
    if ($socket.Connected) {
        Write-Host "✅ Socket connexion RÉUSSIE" -ForegroundColor Green
        $socket.Close()
    } else {
        Write-Host "❌ Socket connexion ÉCHOUÉE" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Erreur socket: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "Diagnostic terminé" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan

Read-Host "Appuyez sur Entrée pour continuer..."