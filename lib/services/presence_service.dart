import 'dart:async';
import 'dart:developer';

import '../core/api/api_endpoints.dart';
import '../core/api/dio_client.dart';
import 'storage_service.dart';

/// Service for tracking and querying user online/offline/last-seen status.
///
/// Usage:
/// ```dart
/// final presence = await PresenceService.fetchPresence(userId);
/// print(presence.online); // true/false
/// print(presence.lastSeen); // DateTime or null
/// ```
class PresenceService {
  PresenceService._();

  static Timer? _heartbeatTimer;

  /// Fetch the presence status for a given user.
  static Future<PresenceStatus> fetchPresence(int userId) async {
    try {
      final response = await DioClient.instance.get(
        ApiEndpoints.presence(userId),
      );

      final data = response.data as Map<String, dynamic>;
      return PresenceStatus(
        online: data['online'] as bool? ?? false,
        lastSeen: data['lastSeen'] != null
            ? DateTime.tryParse(data['lastSeen'] as String)
            : null,
      );
    } catch (e) {
      log('PresenceService: Failed to fetch presence for $userId: $e',
          name: 'PresenceService');
      return PresenceStatus(online: false, lastSeen: null);
    }
  }

  /// Send a single heartbeat for the current user.
  static Future<void> sendHeartbeat() async {
    final user = StorageService.getUser();
    if (user?.backendId == null) return;

    try {
      await DioClient.instance.put(
        ApiEndpoints.presenceHeartbeat(user!.backendId!),
      );
    } catch (e) {
      log('PresenceService: Heartbeat failed: $e', name: 'PresenceService');
    }
  }

  /// Start a periodic heartbeat every [interval] (default 30s).
  static void startHeartbeat({Duration interval = const Duration(seconds: 30)}) {
    stopHeartbeat();
    // Send immediately, then periodically
    sendHeartbeat();
    _heartbeatTimer = Timer.periodic(interval, (_) => sendHeartbeat());
  }

  /// Stop the periodic heartbeat.
  static void stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }
}

/// Lightweight data class for a user's online/offline status.
class PresenceStatus {
  final bool online;
  final DateTime? lastSeen;

  PresenceStatus({required this.online, this.lastSeen});
}
