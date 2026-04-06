class ApiConfig {
  static const String host = '10.0.2.2';
  static const String port = '8080';
  static const String baseUrl = 'http://$host:$port/api';

  /// WebSocket URL for STOMP connections.
  static const String wsUrl = 'ws://$host:$port/ws';
}
