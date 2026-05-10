import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../core/api/api_endpoints.dart';
import '../core/api/dio_client.dart';
import '../core/config/api_config.dart';
import '../models/chat_contact_model.dart';
import '../models/chat_message_model.dart';
import 'presence_service.dart';
import 'token_service.dart';

/// Connection state of the underlying WebSocket / STOMP transport.
enum WebSocketState { connected, disconnected, reconnecting }

/// Global singleton that manages the STOMP WebSocket connection for real-time
/// chat, status updates, and system events (e.g. patient assignment).
///
/// **Lifecycle:**
/// - Call [ChatService.initialize] once after login (from the dashboard).
/// - Access the running instance via [ChatService.instance].
/// - Call [ChatService.shutdown] on logout to clean up.
///
/// The connection stays alive across screen transitions so messages arrive
/// in real time even when the user is on the dashboard.
class ChatService {
  // ──────────────────── Singleton ────────────────────
  ChatService._(this.currentUserId);

  static ChatService? _instance;

  /// The currently active singleton instance. Returns `null` if not initialized.
  static ChatService? get instance => _instance;

  /// Initialize the global ChatService and connect the WebSocket.
  /// Safe to call multiple times — only the first call takes effect.
  static Future<void> initialize(int userId) async {
    if (_instance != null && _instance!.currentUserId == userId) {
      // Already initialized for this user; just reconnect if needed
      if (!_instance!.isConnected) {
        await _instance!.connect();
      }
      return;
    }
    // New user or first init
    _instance?.dispose();
    _instance = ChatService._(userId);
    await _instance!.connect();
  }

  /// Tear down the singleton (call on logout).
  static void shutdown() {
    _instance?.dispose();
    _instance = null;
  }

  // ──────────────────── Instance ────────────────────
  final int currentUserId;

  StompClient? _stompClient;
  final _messageController = StreamController<ChatMessageModel>.broadcast();
  final _statusController = StreamController<Map<String, dynamic>>.broadcast();
  final _systemController = StreamController<Map<String, dynamic>>.broadcast();
  final _vitalsController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStateController = StreamController<WebSocketState>.broadcast();
  Completer<void>? _connectCompleter;

  /// Current WebSocket connection state.
  WebSocketState _wsState = WebSocketState.disconnected;
  WebSocketState get wsState => _wsState;

  /// Stream of incoming real-time messages.
  Stream<ChatMessageModel> get messages => _messageController.stream;

  /// Stream of incoming status updates (read/delivered).
  Stream<Map<String, dynamic>> get statuses => _statusController.stream;

  /// Stream of system events (e.g. patient assignment notifications).
  Stream<Map<String, dynamic>> get systemEvents => _systemController.stream;

  /// Stream of live vitals updates from patients (for doctor dashboard).
  Stream<Map<String, dynamic>> get vitalsUpdates => _vitalsController.stream;

  /// Stream of WebSocket connection state changes.
  Stream<WebSocketState> get connectionState => _connectionStateController.stream;

  /// Whether the STOMP client is currently connected.
  bool get isConnected => _stompClient?.connected ?? false;

  void _setWsState(WebSocketState state) {
    if (_wsState != state) {
      _wsState = state;
      if (!_connectionStateController.isClosed) {
        _connectionStateController.add(state);
      }
      log('ChatService: WebSocket state → $state', name: 'ChatService');
    }
  }

  /// Connect to the WebSocket and subscribe to the user's queues.
  Future<void> connect() async {
    if (isConnected) return;

    final token = await TokenService.getToken();
    if (token == null || token.isEmpty) {
      log('ChatService: No JWT token available, cannot connect.',
          name: 'ChatService');
      _setWsState(WebSocketState.disconnected);
      return;
    }

    _connectCompleter = Completer<void>();
    _setWsState(WebSocketState.reconnecting);

    _stompClient = StompClient(
      config: StompConfig.sockJS(
        url: 'http://${ApiConfig.host}:${ApiConfig.port}/ws',
        stompConnectHeaders: {
          'Authorization': 'Bearer $token',
        },
        webSocketConnectHeaders: {
          'Authorization': 'Bearer $token',
        },
        onConnect: _onConnect,
        onDisconnect: _onDisconnect,
        onWebSocketError: (error) {
          log('WebSocket error: $error', name: 'ChatService');
          _setWsState(WebSocketState.disconnected);
          if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
            _connectCompleter!.complete();
          }
        },
        onStompError: (frame) {
          log('STOMP error: ${frame.body}', name: 'ChatService');
          _setWsState(WebSocketState.disconnected);
          if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
            _connectCompleter!.complete();
          }
        },
        // Reconnect every 5 s on disconnect
        reconnectDelay: const Duration(seconds: 5),
      ),
    );

    _stompClient!.activate();
    log('ChatService: Activating STOMP client for user $currentUserId…', name: 'ChatService');

    // Wait for actual connection (with timeout)
    try {
      await _connectCompleter!.future.timeout(const Duration(seconds: 10));
    } catch (e) {
      log('ChatService: Connection timeout or error: $e', name: 'ChatService');
    }
  }

  void _onConnect(StompFrame frame) {
    log('ChatService: Connected to WebSocket!', name: 'ChatService');
    _setWsState(WebSocketState.connected);

    // Start presence heartbeat so this user is shown as online globally
    PresenceService.startHeartbeat();

    // Subscribe to the user's personal message queue
    const dest = '/user/queue/messages';
    log('ChatService: Subscribing to $dest', name: 'ChatService');
    _stompClient!.subscribe(
      destination: dest,
      callback: (StompFrame frame) {
        if (frame.body != null) {
          try {
            final json = jsonDecode(frame.body!) as Map<String, dynamic>;
            final message = ChatMessageModel.fromJson(json);
            _messageController.add(message);
            // If the message is received by ME, and I'm active, immediately mark it as delivered.
            if (message.receiverId == currentUserId && message.senderId != currentUserId) {
              markAsDelivered(message.senderId);
            }
            log('ChatService: Received message from ${message.senderId}',
                name: 'ChatService');
          } catch (e) {
            log('ChatService: Failed to parse message: $e',
                name: 'ChatService');
          }
        }
      },
    );

    // Subscribe to the user's personal status queue
    const statusDest = '/user/queue/chat-status';
    log('ChatService: Subscribing to $statusDest', name: 'ChatService');
    _stompClient!.subscribe(
      destination: statusDest,
      callback: (StompFrame frame) {
        if (frame.body != null) {
          try {
            final json = jsonDecode(frame.body!) as Map<String, dynamic>;
            _statusController.add(json);
            log('ChatService: Received status ${json["status"]} for receiver ${json["receiverId"]}',
                name: 'ChatService');
          } catch (e) {
            log('ChatService: Failed to parse status update: $e',
                name: 'ChatService');
          }
        }
      },
    );

    // Subscribe to system events (e.g. patient assignment)
    const systemDest = '/user/queue/system';
    log('ChatService: Subscribing to $systemDest', name: 'ChatService');
    _stompClient!.subscribe(
      destination: systemDest,
      callback: (StompFrame frame) {
        if (frame.body != null) {
          try {
            final json = jsonDecode(frame.body!) as Map<String, dynamic>;
            _systemController.add(json);
            log('ChatService: Received system event: ${json["type"]}',
                name: 'ChatService');
          } catch (e) {
            log('ChatService: Failed to parse system event: $e',
                name: 'ChatService');
          }
        }
      },
    );

    // Subscribe to live vitals updates (doctor sees patient readings in real-time)
    final vitalsDest = '/topic/vitals/$currentUserId';
    log('ChatService: Subscribing to $vitalsDest', name: 'ChatService');
    _stompClient!.subscribe(
      destination: vitalsDest,
      callback: (StompFrame frame) {
        if (frame.body != null) {
          try {
            final json = jsonDecode(frame.body!) as Map<String, dynamic>;
            _vitalsController.add(json);
            log('ChatService: Received vitals update for patient ${json["patientId"]}',
                name: 'ChatService');
          } catch (e) {
            log('ChatService: Failed to parse vitals update: $e',
                name: 'ChatService');
          }
        }
      },
    );

    // Complete the connect future
    if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
      _connectCompleter!.complete();
    }
  }

  void _onDisconnect(StompFrame frame) {
    log('ChatService: Disconnected from WebSocket.', name: 'ChatService');
    _setWsState(WebSocketState.disconnected);
    PresenceService.stopHeartbeat();
    // The STOMP client's built-in reconnectDelay will fire automatically.
    // When it starts reconnecting, we'll transition to reconnecting
    // via the next connect attempt.
    Future.delayed(const Duration(seconds: 3), () {
      if (_wsState == WebSocketState.disconnected && _stompClient != null) {
        _setWsState(WebSocketState.reconnecting);
      }
    });
  }

  /// Send a chat message to the specified receiver.
  /// If not yet connected, waits up to 5s for the connection.
  Future<void> sendMessage({required int receiverId, required String content}) async {
    // Wait for connection if still pending
    if (!isConnected && _connectCompleter != null) {
      log('ChatService: Waiting for connection before sending...', name: 'ChatService');
      try {
        await _connectCompleter!.future.timeout(const Duration(seconds: 5));
      } catch (_) {}
    }

    if (!isConnected) {
      log('ChatService: Not connected, cannot send message.',
          name: 'ChatService');
      return;
    }

    final message = ChatMessageModel(
      senderId: currentUserId,
      receiverId: receiverId,
      content: content,
    );

    log('ChatService: Sending message to $receiverId: "$content"', name: 'ChatService');
    _stompClient!.send(
      destination: '/app/chat.send',
      body: jsonEncode(message.toJson()),
    );
    log('ChatService: Message sent successfully', name: 'ChatService');
  }

  /// Load chat history between the current user and another user via REST.
  Future<List<ChatMessageModel>> fetchHistory(int otherUserId) async {
    try {
      final response = await DioClient.instance.get(
        ApiEndpoints.chatHistory(currentUserId, otherUserId),
      );

      if (response.data is List) {
        List<ChatMessageModel> history = (response.data as List)
            .map((e) =>
                ChatMessageModel.fromJson(e as Map<String, dynamic>))
            .toList();
            
        // Since we fetched history, anything sent to US is now delivered to this device.
        bool hasUndeliveredFromOther = history.any((msg) =>
            msg.senderId == otherUserId &&
            msg.receiverId == currentUserId &&
            !msg.isDelivered && !msg.isRead);

        if (hasUndeliveredFromOther) {
          markAsDelivered(otherUserId);
        }

        return history;
      }
      return [];
    } catch (e) {
      log('ChatService: Failed to fetch history: $e', name: 'ChatService');
      return [];
    }
  }

  /// Load conversations overview — only partners with existing messages.
  /// Returns a list of [ChatContactModel] with last message, timestamp, unread count.
  /// Sorted by most recent message first.
  Future<List<ChatContactModel>> fetchConversations() async {
    try {
      final response = await DioClient.instance.get(
        ApiEndpoints.chatConversations(currentUserId),
      );

      if (response.data is List) {
        final contacts = (response.data as List)
            .map((e) =>
                ChatContactModel.fromJson(e as Map<String, dynamic>))
            .toList();

        // Sort by last message timestamp descending (most recent first)
        contacts.sort((a, b) {
          final tsA = a.lastMessageTimestamp;
          final tsB = b.lastMessageTimestamp;
          if (tsA == null && tsB == null) return 0;
          if (tsA == null) return 1;
          if (tsB == null) return -1;
          return tsB.compareTo(tsA);
        });

        return contacts;
      }
      return [];
    } catch (e) {
      log('ChatService: Failed to fetch conversations: $e',
          name: 'ChatService');
      return [];
    }
  }

  /// Mark all messages from [otherUserId] to the current user as read.
  Future<void> markAsRead(int otherUserId) async {
    try {
      await DioClient.instance.put(
        ApiEndpoints.chatMarkRead(otherUserId, currentUserId),
      );
    } catch (e) {
      log('ChatService: Failed to mark as read: $e', name: 'ChatService');
    }
  }

  /// Mark all messages from [otherUserId] to the current user as delivered.
  Future<void> markAsDelivered(int otherUserId) async {
    try {
      await DioClient.instance.put(
        ApiEndpoints.chatMarkDelivered(otherUserId, currentUserId),
      );
    } catch (e) {
      log('ChatService: Failed to mark as delivered: $e', name: 'ChatService');
    }
  }

  /// Disconnect the STOMP client and clean up resources.
  void disconnect() {
    _stompClient?.deactivate();
    _stompClient = null;
    _setWsState(WebSocketState.disconnected);
    log('ChatService: Deactivated.', name: 'ChatService');
  }

  /// Dispose the service completely.
  void dispose() {
    disconnect();
    _messageController.close();
    _statusController.close();
    _systemController.close();
    _vitalsController.close();
    _connectionStateController.close();
  }
}
