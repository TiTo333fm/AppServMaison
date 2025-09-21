import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../data/server_service.dart';
import '../data/server_discovery_service.dart';

enum ServerStatus {
  unknown,
  online,
  offline,
  connecting,
}

enum PlexStatus {
  unknown,
  running,
  stopped,
}

class ServerProvider extends ChangeNotifier {
  final ServerService _serverService = ServerService();
  final ServerDiscoveryService _discoveryService = ServerDiscoveryService();
  
  ServerStatus _status = ServerStatus.unknown;
  bool _isLoading = false;
  String? _errorMessage;
  bool _autoDiscovered = false;
  
  // État Plex
  PlexStatus _plexStatus = PlexStatus.unknown;
  bool _plexLoading = false;
  String? _plexErrorMessage;
  
  // Configuration serveur (vos valeurs exactes)
  String _serverIp = AppConstants.serverIpAddress;
  int _serverPort = AppConstants.serverApiPort;
  
  // Getters
  ServerStatus get status => _status;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get serverIp => _serverIp;
  int get serverPort => _serverPort;
  bool get autoDiscovered => _autoDiscovered;
  
  // Getters Plex
  PlexStatus get plexStatus => _plexStatus;
  bool get plexLoading => _plexLoading;
  String? get plexErrorMessage => _plexErrorMessage;
  
  // Setters pour la configuration
  void updateServerConfig(String ip, int port) {
    _serverIp = ip;
    _serverPort = port;
    notifyListeners();
  }
  
  /// Découverte automatique du serveur
  Future<void> discoverServer() async {
    _setLoading(true);
    _errorMessage = null;
    
    try {
      final result = await _discoveryService.discoverServer();
      
      if (result.hasServers && result.recommendedServer != null) {
        final server = result.recommendedServer!;
        _serverIp = server.ipAddress;
        _serverPort = server.port;
        _autoDiscovered = true;
        _status = ServerStatus.online;
        _errorMessage = null;
        
        print('✅ Serveur découvert: ${server.displayName} (${server.fullAddress})');
      } else {
        _autoDiscovered = false;
        _status = ServerStatus.offline;
        _errorMessage = 'Aucun serveur trouvé sur le réseau. '
            'Vérifiez que le service est démarré sur ${AppConstants.serverName} '
            '(${AppConstants.serverIpAddress}:${AppConstants.serverApiPort})';
      }
    } catch (e) {
      _autoDiscovered = false;
      _status = ServerStatus.offline;
      _errorMessage = 'Erreur lors de la découverte: $e';
    } finally {
      _setLoading(false);
    }
  }
  
  /// Vérification rapide de connectivité
  Future<void> quickConnectivityCheck() async {
    try {
      final isReachable = await _discoveryService.quickConnectivityTest(
        _serverIp,
        _serverPort,
      );
      
      _status = isReachable ? ServerStatus.online : ServerStatus.offline;
      notifyListeners();
    } catch (e) {
      _status = ServerStatus.offline;
      notifyListeners();
    }
  }
  Future<void> checkServerStatus() async {
    _setLoading(true);
    _errorMessage = null;
    
    try {
      final isOnline = await _serverService.pingServer(
        serverIp: _serverIp,
        port: _serverPort,
      );
      
      _status = isOnline ? ServerStatus.online : ServerStatus.offline;
    } catch (e) {
      _status = ServerStatus.offline;
      _errorMessage = 'Erreur de connexion: $e';
    } finally {
      _setLoading(false);
    }
  }
  
  /// Arrêter le serveur
  Future<bool> shutdownServer() async {
    _setLoading(true);
    _errorMessage = null;
    
    try {
      final success = await _serverService.shutdownServer(
        serverIp: _serverIp,
        port: _serverPort,
      );
      
      if (success) {
        _status = ServerStatus.offline;
        _errorMessage = null;
      } else {
        _errorMessage = 'Échec de l\'arrêt du serveur';
      }
      
      return success;
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'arrêt: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Redémarrer le serveur
  Future<bool> restartServer() async {
    _setLoading(true);
    _errorMessage = null;
    
    try {
      final success = await _serverService.restartServer(
        serverIp: _serverIp,
        port: _serverPort,
      );
      
      if (success) {
        _status = ServerStatus.connecting;
        _errorMessage = null;
        
        // Attendre quelques secondes puis vérifier le statut
        await Future.delayed(const Duration(seconds: 10));
        await checkServerStatus();
      } else {
        _errorMessage = 'Échec du redémarrage du serveur';
      }
      
      return success;
    } catch (e) {
      _errorMessage = 'Erreur lors du redémarrage: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Wake-on-LAN (pour plus tard)
  Future<bool> wakeServer(String macAddress) async {
    _setLoading(true);
    _errorMessage = null;
    
    try {
      final success = await _serverService.wakeOnLan(macAddress);
      
      if (success) {
        _status = ServerStatus.connecting;
        // Attendre puis vérifier le statut
        await Future.delayed(const Duration(seconds: 15));
        await checkServerStatus();
      } else {
        _errorMessage = 'Wake-on-LAN nécessite une connexion Ethernet';
      }
      
      return success;
    } catch (e) {
      _errorMessage = 'Erreur Wake-on-LAN: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setPlexLoading(bool loading) {
    _plexLoading = loading;
    notifyListeners();
  }
  
  /// Vérifier le statut de Plex Media Server
  Future<void> checkPlexStatus() async {
    _setPlexLoading(true);
    _plexErrorMessage = null;
    
    try {
      final plexRunning = await _serverService.getPlexStatus(
        serverIp: _serverIp,
        port: _serverPort,
      );
      
      _plexStatus = plexRunning ? PlexStatus.running : PlexStatus.stopped;
      _plexErrorMessage = null;
    } catch (e) {
      _plexStatus = PlexStatus.unknown;
      _plexErrorMessage = 'Erreur lors de la vérification de Plex: $e';
    } finally {
      _setPlexLoading(false);
    }
  }
  
  /// Démarrer Plex Media Server
  Future<bool> startPlex() async {
    _setPlexLoading(true);
    _plexErrorMessage = null;
    
    try {
      final success = await _serverService.startPlex(
        serverIp: _serverIp,
        port: _serverPort,
      );
      
      if (success) {
        _plexStatus = PlexStatus.running;
        _plexErrorMessage = null;
      } else {
        _plexErrorMessage = 'Échec du démarrage de Plex';
      }
      
      return success;
    } catch (e) {
      _plexErrorMessage = 'Erreur lors du démarrage de Plex: $e';
      return false;
    } finally {
      _setPlexLoading(false);
    }
  }
  
  /// Arrêter Plex Media Server  
  Future<bool> stopPlex() async {
    _setPlexLoading(true);
    _plexErrorMessage = null;
    
    try {
      final success = await _serverService.stopPlex(
        serverIp: _serverIp,
        port: _serverPort,
      );
      
      if (success) {
        _plexStatus = PlexStatus.stopped;
        _plexErrorMessage = null;
      } else {
        _plexErrorMessage = 'Échec de l\'arrêt de Plex';
      }
      
      return success;
    } catch (e) {
      _plexErrorMessage = 'Erreur lors de l\'arrêt de Plex: $e';
      return false;
    } finally {
      _setPlexLoading(false);
    }
  }
}