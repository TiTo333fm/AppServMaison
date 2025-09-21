enum ServerAction { 
  shutdown,
  restart,
  wakeOnLan,
}

class ServerCommand {
  final String name;
  final String description;
  final ServerAction action;
  final String? ipAddress;
  final String? username;
  final String? password;

  const ServerCommand({
    required this.name,
    required this.description,
    required this.action,
    this.ipAddress,
    this.username,
    this.password,
  });
}