class ApiConfig {
  // For Android emulator, use 10.0.2.2 to reach host machine's localhost.
  // For physical device, use your machine's LAN IP (e.g., 192.168.1.X).
  static const String host = '10.0.2.2';
  static const String port = '8080';
  static const String baseUrl = 'http://$host:$port/api';
}
