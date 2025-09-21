import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../wake_on_lan/presentation/server_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  bool _isInitializing = true;
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Test rapide de connectivité au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final serverProvider = context.read<ServerProvider>();
      _initializeConnection(serverProvider);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _initializeConnection(ServerProvider serverProvider) async {
    setState(() {
      _isInitializing = true;
    });
    
    // Test direct avec retry automatique et délais progressifs
    for (int attempt = 1; attempt <= 5; attempt++) {
      print('🔄 Tentative $attempt/5 de connexion au serveur...');
      
      await serverProvider.quickConnectivityCheck();
      
      if (serverProvider.status == ServerStatus.online) {
        print('✅ Serveur détecté automatiquement à la tentative $attempt');
        await serverProvider.checkPlexStatus();
        setState(() {
          _isInitializing = false;
        });
        return;
      }
      
      // Attendre un délai progressif avant le prochain essai
      if (attempt < 5) {
        final delay = Duration(milliseconds: 500 + (attempt * 500)); // 1s, 1.5s, 2s, 2.5s
        print('⏱️ Attente de ${delay.inMilliseconds}ms avant la prochaine tentative...');
        await Future.delayed(delay);
      }
    }
    
    print('❌ Connexion automatique échouée après 5 tentatives');
    print('📡 Adresse cible: 192.168.1.175:8080');
    print('💡 Vérifiez que le serveur PowerShell est démarré');
    
    setState(() {
      _isInitializing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isInitializing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Connexion au serveur en cours...',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tentatives multiples avec délais progressifs', 
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Consumer<ServerProvider>(
              builder: (context, serverProvider, child) {
                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // Statut global du serveur
                    _GlobalStatusCard(serverProvider: serverProvider),
                    const SizedBox(height: 16),
                    
                    // Liste des fonctionnalités déroulantes
                    _ServerControlSection(serverProvider: serverProvider),
                    const SizedBox(height: 8),
                    _PlexControlSection(serverProvider: serverProvider),
                    const SizedBox(height: 8),
                    _SystemInfoSection(serverProvider: serverProvider),
                  ],
                );
              },
            ),
    );
  }
}

// Carte de statut global compact
class _GlobalStatusCard extends StatelessWidget {
  final ServerProvider serverProvider;
  
  const _GlobalStatusCard({required this.serverProvider});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (serverProvider.status) {
      case ServerStatus.online:
        statusColor = Colors.green;
        statusText = 'En ligne';
        statusIcon = Icons.check_circle;
        break;
      case ServerStatus.offline:
        statusColor = Colors.red;
        statusText = 'Hors ligne';
        statusIcon = Icons.cancel;
        break;
      case ServerStatus.connecting:
        statusColor = Colors.orange;
        statusText = 'Connexion...';
        statusIcon = Icons.sync;
        break;
      case ServerStatus.unknown:
        statusColor = Colors.grey;
        statusText = 'Inconnu';
        statusIcon = Icons.help;
        break;
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.computer, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SERVEUR333',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '192.168.1.175:8080',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(statusIcon, color: statusColor, size: 24),
                const SizedBox(height: 4),
                Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Section Contrôle Serveur (déroulante)
class _ServerControlSection extends StatelessWidget {
  final ServerProvider serverProvider;
  
  const _ServerControlSection({required this.serverProvider});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: ExpansionTile(
        leading: const Icon(Icons.computer, color: Colors.blue),
        title: const Text('Contrôle Serveur'),
        subtitle: Text(
          serverProvider.status == ServerStatus.online ? 'Serveur opérationnel' : 'Serveur hors ligne',
          style: TextStyle(
            color: serverProvider.status == ServerStatus.online ? Colors.green : Colors.red,
            fontSize: 12,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                _CompactActionButton(
                  icon: Icons.refresh,
                  label: 'Vérifier l\'état',
                  color: Colors.blue,
                  isEnabled: !serverProvider.isLoading,
                  onPressed: () async {
                    await serverProvider.checkServerStatus();
                    if (serverProvider.status == ServerStatus.online) {
                      await serverProvider.checkPlexStatus();
                    }
                  },
                ),
                if (serverProvider.status == ServerStatus.online) ...[
                  const SizedBox(height: 8),
                  _CompactActionButton(
                    icon: Icons.power_settings_new,
                    label: 'Éteindre le serveur',
                    color: Colors.red,
                    isEnabled: !serverProvider.isLoading,
                    onPressed: () async {
                      bool? confirmed = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirmer l\'arrêt'),
                            content: const Text('Voulez-vous vraiment éteindre le serveur ?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Annuler'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Confirmer'),
                              ),
                            ],
                          );
                        },
                      );
                      
                      if (confirmed == true) {
                        final success = await serverProvider.shutdownServer();
                        if (!success && serverProvider.errorMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(serverProvider.errorMessage!)),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  _CompactActionButton(
                    icon: Icons.restart_alt,
                    label: 'Redémarrer le serveur',
                    color: Colors.orange,
                    isEnabled: !serverProvider.isLoading,
                    onPressed: () async {
                      bool? confirmed = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirmer le redémarrage'),
                            content: const Text('Voulez-vous vraiment redémarrer le serveur ?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Annuler'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Confirmer'),
                              ),
                            ],
                          );
                        },
                      );
                      
                      if (confirmed == true) {
                        final success = await serverProvider.restartServer();
                        if (!success && serverProvider.errorMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(serverProvider.errorMessage!)),
                          );
                        }
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Section Contrôle Plex (déroulante)
class _PlexControlSection extends StatelessWidget {
  final ServerProvider serverProvider;
  
  const _PlexControlSection({required this.serverProvider});

  @override
  Widget build(BuildContext context) {
    final isPlexRunning = serverProvider.plexStatus == PlexStatus.running;
    final canControlPlex = serverProvider.status == ServerStatus.online;
    
    return Card(
      elevation: 1,
      child: ExpansionTile(
        leading: Icon(Icons.play_circle, 
          color: isPlexRunning ? Colors.green : Colors.grey),
        title: const Text('Plex Media Server'),
        subtitle: Text(
          canControlPlex 
            ? (isPlexRunning ? 'En cours d\'exécution' : 'Arrêté') 
            : 'Serveur hors ligne',
          style: TextStyle(
            color: canControlPlex 
              ? (isPlexRunning ? Colors.green : Colors.red)
              : Colors.grey,
            fontSize: 12,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                _CompactActionButton(
                  icon: Icons.refresh,
                  label: 'Vérifier l\'état Plex',
                  color: Colors.blue,
                  isEnabled: canControlPlex && !serverProvider.isLoading,
                  onPressed: () async {
                    await serverProvider.checkPlexStatus();
                  },
                ),
                if (canControlPlex) ...[
                  const SizedBox(height: 8),
                  _CompactActionButton(
                    icon: Icons.play_arrow,
                    label: 'Démarrer Plex',
                    color: Colors.green,
                    isEnabled: !isPlexRunning && !serverProvider.isLoading,
                    onPressed: () async {
                      final success = await serverProvider.startPlex();
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Plex Media Server démarré')),
                        );
                      } else if (serverProvider.errorMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(serverProvider.errorMessage!)),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  _CompactActionButton(
                    icon: Icons.stop,
                    label: 'Arrêter Plex',
                    color: Colors.red,
                    isEnabled: isPlexRunning && !serverProvider.isLoading,
                    onPressed: () async {
                      bool? confirmed = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Arrêter Plex'),
                            content: const Text('Voulez-vous vraiment arrêter Plex Media Server ?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Annuler'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Confirmer'),
                              ),
                            ],
                          );
                        },
                      );
                      
                      if (confirmed == true) {
                        final success = await serverProvider.stopPlex();
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Plex Media Server arrêté')),
                          );
                        } else if (serverProvider.errorMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(serverProvider.errorMessage!)),
                          );
                        }
                      }
                    },
                  ),
                  if (isPlexRunning) ...[
                    const SizedBox(height: 8),
                    _CompactActionButton(
                      icon: Icons.restart_alt,
                      label: 'Redémarrer Plex',
                      color: Colors.orange,
                      isEnabled: !serverProvider.isLoading,
                      onPressed: () async {
                        bool? confirmed = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Redémarrer Plex'),
                              content: const Text('Voulez-vous vraiment redémarrer Plex Media Server ?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Annuler'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('Confirmer'),
                                ),
                              ],
                            );
                          },
                        );
                        
                        if (confirmed == true) {
                          final stopSuccess = await serverProvider.stopPlex();
                          if (stopSuccess) {
                            await Future.delayed(const Duration(seconds: 2));
                            final startSuccess = await serverProvider.startPlex();
                            if (startSuccess) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Plex Media Server redémarré')),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Section Informations Système (déroulante)
class _SystemInfoSection extends StatelessWidget {
  final ServerProvider serverProvider;
  
  const _SystemInfoSection({required this.serverProvider});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: ExpansionTile(
        leading: const Icon(Icons.info_outline, color: Colors.cyan),
        title: const Text('Informations Système'),
        subtitle: const Text('État et diagnostics', style: TextStyle(fontSize: 12)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                _InfoRow('Serveur', 'SERVEUR333'),
                _InfoRow('Adresse IP', '192.168.1.175'),
                _InfoRow('Port API', '8080'),
                _InfoRow('Version API', '2.0'),
                if (serverProvider.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            serverProvider.errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Widget de bouton compact pour les actions
class _CompactActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isEnabled;
  final VoidCallback? onPressed;

  const _CompactActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isEnabled,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isEnabled ? onPressed : null,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? color : Colors.grey.shade300,
          foregroundColor: isEnabled ? Colors.white : Colors.grey,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

// Widget pour afficher les informations système
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}