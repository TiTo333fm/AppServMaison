class AppConstants {
  // Server Configuration
  static const String serverMacAddress = 'C8-7F-54-53-1D-40';
  static const String serverName = 'SERVEUR333';
  static const String serverIpAddress = '192.168.1.175'; // IP corrigée !
  static const int wakeOnLanPort = 9;
  static const int serverApiPort = 8080;
  
  // App Information
  static const String appName = 'AppServMaison';
  static const String appVersion = '1.0.0';
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double buttonHeight = 56.0;
  static const double borderRadius = 12.0;
  
  // Network timeouts
  static const Duration connectionTimeout = Duration(seconds: 5);
  static const Duration serverCheckTimeout = Duration(seconds: 3);
}