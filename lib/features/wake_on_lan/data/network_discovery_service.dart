import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class NetworkDiscoveryService {
  static const int _defaultPort = 8080;
  static const Duration _timeout = Duration(seconds: 2);
  
  /// Découvre automatiquement le serveur sur le réseau local
  Future<String?> discoverServer({int port = _defaultPort}) async {
    try {
      // Obtenir l'adresse IP locale de l'appareil
      final localIp = await _getLocalIpAddress();
      if (localIp == null) {
        print('Impossible de déterminer l\'IP locale');
        return null;
      }
      
      print('IP locale détectée: $localIp');
      
      // Extraire le sous-réseau (ex: 192.168.1.x)
      final subnet = _getSubnet(localIp);
      if (subnet == null) {
        print('Impossible de déterminer le sous-réseau');
        return null;
      }
      
      print('Scan du sous-réseau: $subnet.x');
      
      // Scanner le sous-réseau
      return await _scanSubnet(subnet, port);
      
    } catch (e) {
      print('Erreur lors de la découverte: $e');
      return null;
    }
  }
  
  /// Obtient l'adresse IP locale de l'appareil
  Future<String?> _getLocalIpAddress() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && 
              !addr.isLoopback && 
              !addr.isMulticast) {
            // Préférer les adresses du réseau privé
            if (_isPrivateNetwork(addr.address)) {
              return addr.address;
            }
          }
        }
      }
    } catch (e) {
      print('Erreur récupération IP locale: $e');
    }
    return null;
  }
  
  /// Vérifie si l'adresse IP est dans un réseau privé
  bool _isPrivateNetwork(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    
    final firstOctet = int.tryParse(parts[0]) ?? 0;
    final secondOctet = int.tryParse(parts[1]) ?? 0;
    
    // 192.168.x.x
    if (firstOctet == 192 && secondOctet == 168) return true;
    
    // 10.x.x.x
    if (firstOctet == 10) return true;
    
    // 172.16.x.x - 172.31.x.x
    if (firstOctet == 172 && secondOctet >= 16 && secondOctet <= 31) return true;
    
    return false;
  }
  
  /// Extrait le sous-réseau de l'adresse IP
  String? _getSubnet(String ip) {
    final parts = ip.split('.');
    if (parts.length >= 3) {
      return '${parts[0]}.${parts[1]}.${parts[2]}';
    }
    return null;
  }
  
  /// Scanne un sous-réseau à la recherche du service
  Future<String?> _scanSubnet(String subnet, int port) async {
    final List<Future<String?>> futures = [];
    
    // Scanner les adresses de 1 à 254
    for (int i = 1; i <= 254; i++) {
      final ip = '$subnet.$i';
      futures.add(_checkServer(ip, port));
    }
    
    // Attendre toutes les réponses
    final results = await Future.wait(futures);
    
    // Retourner la première IP qui répond
    for (final result in results) {
      if (result != null) {
        print('Serveur trouvé à l\'adresse: $result');
        return result;
      }
    }
    
    print('Aucun serveur trouvé sur le sous-réseau $subnet.x:$port');
    return null;
  }
  
  /// Vérifie si un serveur répond à une adresse IP donnée
  Future<String?> _checkServer(String ip, int port) async {
    try {
      final response = await http.get(
        Uri.parse('http://$ip:$port/api/status'),
        headers: {'User-Agent': 'AppServMaison-Discovery'},
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (data['status'] == 'online') {
            return ip;
          }
        } catch (e) {
          // La réponse n'est pas JSON valide, mais le serveur répond
          return ip;
        }
      }
    } catch (e) {
      // Serveur non accessible, continuer
    }
    return null;
  }
  
  /// Recherche par nom d'hôte Windows (NetBIOS)
  Future<String?> resolveWindowsHostname(String hostname) async {
    try {
      final addresses = await InternetAddress.lookup(hostname);
      for (final addr in addresses) {
        if (addr.type == InternetAddressType.IPv4) {
          final ip = addr.address;
          // Vérifier que le service répond sur cette IP
          final serverIp = await _checkServer(ip, _defaultPort);
          if (serverIp != null) {
            print('Serveur trouvé via hostname $hostname: $ip');
            return ip;
          }
        }
      }
    } catch (e) {
      print('Impossible de résoudre le hostname $hostname: $e');
    }
    return null;
  }
  
  /// Obtient des suggestions de noms d'hôte Windows courants
  List<String> getCommonWindowsHostnames() {
    return [
      'SERVER',
      'SERVEUR', 
      'HOMESERVER',
      'PC-SERVEUR',
      'MEDIASERVER',
      'PLEXSERVER',
      'DESKTOP',
      'ORDINATEUR',
    ];
  }
}