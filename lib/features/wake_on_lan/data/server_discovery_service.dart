import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';

class ServerDiscoveryService {
  
  /// Tente de découvrir automatiquement le serveur
  Future<ServerDiscoveryResult> discoverServer() async {
    final result = ServerDiscoveryResult();
    
    // Test direct avec l'IP configurée (pas de scan réseau)
    print('🔍 Test de connexion au serveur ${AppConstants.serverName} (${AppConstants.serverIpAddress}:${AppConstants.serverApiPort})...');
    
    final directTest = await _testServer(
      AppConstants.serverIpAddress, 
      AppConstants.serverApiPort
    );
    
    if (directTest.isReachable) {
      result.foundServers.add(directTest);
      result.recommendedServer = directTest;
      print('✅ Serveur trouvé et accessible en ${directTest.responseTime}ms');
    } else {
      print('❌ Serveur non accessible - vérifiez que le service PowerShell est démarré');
    }
    
    return result;
  }
  
  /// Test un serveur spécifique
  Future<ServerInfo> _testServer(String ip, int port) async {
    final server = ServerInfo(
      name: ip == AppConstants.serverIpAddress ? AppConstants.serverName : 'Serveur',
      ipAddress: ip,
      port: port,
      isReachable: false,
      responseTime: null,
    );
    
    try {
      final stopwatch = Stopwatch()..start();
      
      final response = await http.get(
        Uri.parse('http://$ip:$port/api/status'),
      ).timeout(AppConstants.serverCheckTimeout);
      
      stopwatch.stop();
      
      if (response.statusCode == 200) {
        server.isReachable = true;
        server.responseTime = stopwatch.elapsedMilliseconds;
        
        // Essayer de décoder la réponse pour obtenir plus d'infos
        try {
          final data = jsonDecode(response.body);
          server.serverInfo = data;
        } catch (e) {
          // Ignore si on ne peut pas décoder le JSON
        }
      }
    } catch (e) {
      // Le serveur n'est pas accessible
      print('❌ Serveur $ip:$port non accessible: $e');
    }
    
    return server;
  }
  
  /// Test rapide de connectivité
  Future<bool> quickConnectivityTest(String ip, int port) async {
    try {
      final response = await http.get(
        Uri.parse('http://$ip:$port/api/status'),
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

class ServerDiscoveryResult {
  List<ServerInfo> foundServers = [];
  ServerInfo? recommendedServer;
  
  bool get hasServers => foundServers.isNotEmpty;
  int get serverCount => foundServers.length;
}

class ServerInfo {
  final String name;
  final String ipAddress;
  final int port;
  bool isReachable;
  int? responseTime;
  Map<String, dynamic>? serverInfo;
  
  ServerInfo({
    required this.name,
    required this.ipAddress,
    required this.port,
    required this.isReachable,
    this.responseTime,
    this.serverInfo,
  });
  
  String get displayName => name.isEmpty ? ipAddress : name;
  String get fullAddress => '$ipAddress:$port';
}