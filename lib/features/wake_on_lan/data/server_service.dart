import 'dart:convert';
import 'package:http/http.dart' as http;

class ServerService {
  static const String _defaultServerIp = '192.168.1.100'; // À modifier selon votre réseau
  static const int _defaultPort = 8080;
  
  /// Arrêt du serveur via HTTP
  Future<bool> shutdownServer({
    String? serverIp,
    int? port,
  }) async {
    final ip = serverIp ?? _defaultServerIp;
    final serverPort = port ?? _defaultPort;
    
    try {
      // Tentative d'arrêt via une API REST personnalisée
      final response = await http.post(
        Uri.parse('http://$ip:$serverPort/api/shutdown'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'shutdown',
          'confirm': true,
        }),
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      print('Erreur arrêt serveur via API: $e');
      
      // Fallback : tentative via PowerShell Remoting (si disponible)
      return await _tryPowerShellShutdown(ip);
    }
  }
  
  /// Redémarrage du serveur
  Future<bool> restartServer({
    String? serverIp,
    int? port,
  }) async {
    final ip = serverIp ?? _defaultServerIp;
    final serverPort = port ?? _defaultPort;
    
    try {
      final response = await http.post(
        Uri.parse('http://$ip:$serverPort/api/restart'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'restart',
          'confirm': true,
        }),
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      print('Erreur redémarrage serveur: $e');
      return false;
    }
  }
  
  /// Vérification du statut du serveur
  Future<bool> pingServer({String? serverIp, int? port}) async {
    final ip = serverIp ?? _defaultServerIp;
    final serverPort = port ?? _defaultPort;
    
    try {
      final response = await http.get(
        Uri.parse('http://$ip:$serverPort/api/status'),
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      print('Serveur non accessible: $e');
      return false;
    }
  }
  
  /// Tentative d'arrêt via PowerShell (fallback)
  Future<bool> _tryPowerShellShutdown(String ip) async {
    try {
      // Cette méthode nécessiterait une implémentation native
      // ou un service intermédiaire sur le serveur
      print('Tentative PowerShell shutdown pour $ip (non implémenté)');
      return false;
    } catch (e) {
      print('Erreur PowerShell shutdown: $e');
      return false;
    }
  }
  
  /// Wake-on-LAN (pour plus tard quand ethernet sera disponible)
  Future<bool> wakeOnLan(String macAddress) async {
    try {
      // TODO: Implémenter Wake-on-LAN quand ethernet sera disponible
      print('Wake-on-LAN pour $macAddress (nécessite ethernet)');
      return false;
    } catch (e) {
      print('Erreur Wake-on-LAN: $e');
      return false;
    }
  }
  
  /// Obtenir le statut de Plex Media Server
  Future<bool> getPlexStatus({
    String? serverIp,
    int? port,
  }) async {
    final ip = serverIp ?? _defaultServerIp;
    final serverPort = port ?? _defaultPort;
    
    try {
      final response = await http.get(
        Uri.parse('http://$ip:$serverPort/api/plex/status'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['plex_running'] == true;
      }
      return false;
    } catch (e) {
      print('Erreur statut Plex: $e');
      return false;
    }
  }
  
  /// Démarrer Plex Media Server
  Future<bool> startPlex({
    String? serverIp,
    int? port,
  }) async {
    final ip = serverIp ?? _defaultServerIp;
    final serverPort = port ?? _defaultPort;
    
    try {
      final response = await http.post(
        Uri.parse('http://$ip:$serverPort/api/plex/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'start_plex',
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['success'] == true;
      }
      return false;
    } catch (e) {
      print('Erreur démarrage Plex: $e');
      return false;
    }
  }
  
  /// Arrêter Plex Media Server
  Future<bool> stopPlex({
    String? serverIp,
    int? port,
  }) async {
    final ip = serverIp ?? _defaultServerIp;
    final serverPort = port ?? _defaultPort;
    
    try {
      final response = await http.post(
        Uri.parse('http://$ip:$serverPort/api/plex/stop'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'stop_plex',
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['success'] == true;
      }
      return false;
    } catch (e) {
      print('Erreur arrêt Plex: $e');
      return false;
    }
  }
}