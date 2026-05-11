//for real device wifi or emulator

// for real device via Tailscale
class ApiConfig {
  static const String host = '100.76.88.106';
  static const String port = '8080';

  static const String baseUrl = 'http://$host:$port/api';
  static const String wsUrl = 'ws://$host:$port/ws';
}
