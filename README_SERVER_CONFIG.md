# Configuration du Serveur - AppServMaison

## Vue d'ensemble

L'application AppServMaison permet de contrôler votre serveur domestique à distance. Pour que les fonctionnalités d'arrêt et de redémarrage fonctionnent, vous devez configurer un petit service sur votre serveur Windows.

## Fonctionnalités actuelles

✅ **Interface utilisateur complète**
- Vérification du statut du serveur
- Arrêt à distance du serveur
- Redémarrage à distance du serveur
- Configuration de l'adresse IP du serveur

⚠️ **Wake-on-LAN**
- Préparé mais nécessite une connexion Ethernet (pas WiFi)
- Sera fonctionnel une fois que votre serveur aura une connexion Ethernet

## Configuration requise sur le serveur

Pour que l'application puisse communiquer avec votre serveur, vous devez installer un petit service REST sur votre serveur Windows.

### Option 1: Service PowerShell simple (Recommandé pour débuter)

Créez un script PowerShell `server-api.ps1` sur votre serveur :

```powershell
# server-api.ps1
# Service REST simple pour AppServMaison

$port = 8080
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://+:$port/")

try {
    $listener.Start()
    Write-Host "Serveur API démarré sur le port $port"
    Write-Host "Endpoints disponibles:"
    Write-Host "  GET  /api/status    - Vérifier le statut"
    Write-Host "  POST /api/shutdown  - Arrêt du serveur"
    Write-Host "  POST /api/restart   - Redémarrage du serveur"
    Write-Host ""
    Write-Host "Appuyez sur Ctrl+C pour arrêter..."

    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        $path = $request.Url.AbsolutePath
        $method = $request.HttpMethod
        
        Write-Host "$(Get-Date) - $method $path"
        
        # Headers CORS
        $response.Headers.Add("Access-Control-Allow-Origin", "*")
        $response.Headers.Add("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        $response.Headers.Add("Access-Control-Allow-Headers", "Content-Type")
        
        if ($method -eq "OPTIONS") {
            $response.StatusCode = 200
        }
        elseif ($path -eq "/api/status" -and $method -eq "GET") {
            $responseString = '{"status":"online","timestamp":"' + (Get-Date).ToString() + '"}'
            $response.StatusCode = 200
        }
        elseif ($path -eq "/api/shutdown" -and $method -eq "POST") {
            $responseString = '{"message":"Shutdown initiated","success":true}'
            $response.StatusCode = 200
            # Lancer l'arrêt avec un délai de 10 secondes
            Start-Process "shutdown" -ArgumentList "/s", "/t", "10", "/c", "Arrêt demandé par AppServMaison"
        }
        elseif ($path -eq "/api/restart" -and $method -eq "POST") {
            $responseString = '{"message":"Restart initiated","success":true}'
            $response.StatusCode = 200
            # Lancer le redémarrage avec un délai de 10 secondes
            Start-Process "shutdown" -ArgumentList "/r", "/t", "10", "/c", "Redémarrage demandé par AppServMaison"
        }
        else {
            $responseString = '{"error":"Endpoint not found"}'
            $response.StatusCode = 404
        }
        
        if ($responseString) {
            $response.ContentType = "application/json"
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseString)
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        
        $response.Close()
    }
}
catch {
    Write-Error "Erreur: $_"
}
finally {
    $listener.Stop()
}
```

### Option 2: Service Windows avec Node.js

Si vous préférez Node.js, créez `server-api.js` :

```javascript
const http = require('http');
const { exec } = require('child_process');
const url = require('url');

const PORT = 8080;

const server = http.createServer((req, res) => {
    const parsedUrl = url.parse(req.url, true);
    const path = parsedUrl.pathname;
    const method = req.method;

    // CORS headers
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

    console.log(`${new Date().toISOString()} - ${method} ${path}`);

    if (method === 'OPTIONS') {
        res.writeHead(200);
        res.end();
        return;
    }

    if (path === '/api/status' && method === 'GET') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
            status: 'online',
            timestamp: new Date().toISOString()
        }));
    }
    else if (path === '/api/shutdown' && method === 'POST') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
            message: 'Shutdown initiated',
            success: true
        }));
        
        // Arrêt avec délai de 10 secondes
        exec('shutdown /s /t 10 /c "Arrêt demandé par AppServMaison"');
    }
    else if (path === '/api/restart' && method === 'POST') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
            message: 'Restart initiated',
            success: true
        }));
        
        // Redémarrage avec délai de 10 secondes
        exec('shutdown /r /t 10 /c "Redémarrage demandé par AppServMaison"');
    }
    else {
        res.writeHead(404, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Endpoint not found' }));
    }
});

server.listen(PORT, () => {
    console.log(`Serveur API démarré sur le port ${PORT}`);
    console.log('Endpoints disponibles:');
    console.log('  GET  /api/status    - Vérifier le statut');
    console.log('  POST /api/shutdown  - Arrêt du serveur');
    console.log('  POST /api/restart   - Redémarrage du serveur');
});
```

## Instructions de déploiement

### Pour PowerShell (Option 1)

1. Copiez le script `server-api.ps1` sur votre serveur
2. Ouvrez PowerShell en tant qu'administrateur
3. Exécutez : `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
4. Lancez le script : `.\server-api.ps1`
5. Configurez le pare-feu Windows pour autoriser le port 8080

### Pour Node.js (Option 2)

1. Installez Node.js sur votre serveur si ce n'est pas fait
2. Copiez le fichier `server-api.js` sur votre serveur
3. Ouvrez une invite de commande en tant qu'administrateur
4. Exécutez : `node server-api.js`
5. Configurez le pare-feu Windows pour autoriser le port 8080

### Configuration du pare-feu Windows

```powershell
# Autoriser le port 8080 en entrée
New-NetFirewallRule -DisplayName "AppServMaison API" -Direction Inbound -Protocol TCP -LocalPort 8080 -Action Allow
```

## Configuration de l'application

1. Dans l'application, appuyez sur "Configurer l'adresse IP"
2. Entrez l'adresse IP locale de votre serveur (ex: 192.168.1.100)
3. Vérifiez que le port est 8080
4. Testez la connexion avec "Vérifier le statut"

## Sécurité

⚠️ **Important** : Cette configuration est pour un usage domestique sur un réseau local privé. Pour un usage en production ou accessible depuis Internet, ajoutez :

- Authentification (tokens, mots de passe)
- HTTPS avec certificats SSL
- Limitation des adresses IP autorisées
- Logs d'audit

## Prochaines étapes

- [ ] Tester la configuration sur votre serveur
- [ ] Configurer le Wake-on-LAN quand l'Ethernet sera disponible
- [ ] Ajouter d'autres fonctionnalités (monitoring, gestion des services, etc.)