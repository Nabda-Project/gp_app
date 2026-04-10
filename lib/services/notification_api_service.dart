import 'dart:developer';
import '../core/api/dio_client.dart';
import '../core/api/api_endpoints.dart';

/// Model for a notification from the backend.
class NotificationItem {
  final int id;
  final int userId;
  final String type;
  final String title;
  final String body;
  final int? relatedId;
  final String? relatedName;
  final bool isRead;
  final DateTime? createdAt;

  NotificationItem({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.relatedId,
    this.relatedName,
    required this.isRead,
    this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as int,
      userId: json['userId'] as int,
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      relatedId: json['relatedId'] as int?,
      relatedName: json['relatedName'] as String?,
      isRead: json['read'] == true || json['isRead'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }
}

/// API service for notifications.
class NotificationApiService {
  NotificationApiService._();

  static Future<List<NotificationItem>> getNotifications(int userId, {int page = 0, int size = 20}) async {
    try {
      final response = await DioClient.instance.get(
        ApiEndpoints.notifications(userId, page: page, size: size),
      );
      if (response.data is Map && response.data['content'] is List) {
        return (response.data['content'] as List)
            .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (response.data is List) {
        return (response.data as List)
            .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      log('Failed to fetch notifications: $e', name: 'NotificationApiService');
      return [];
    }
  }

  static Future<int> getUnreadCount(int userId) async {
    try {
      final response = await DioClient.instance.get(
        ApiEndpoints.notificationsUnreadCount(userId),
      );
      return (response.data as Map<String, dynamic>)['count'] as int? ?? 0;
    } catch (e) {
      log('Failed to fetch unread count: $e', name: 'NotificationApiService');
      return 0;
    }
  }

  static Future<void> markAsRead(int notificationId, int userId) async {
    try {
      await DioClient.instance.put(
        ApiEndpoints.notificationMarkRead(notificationId, userId),
      );
    } catch (e) {
      log('Failed to mark notification as read: $e', name: 'NotificationApiService');
    }
  }

  static Future<void> markAllAsRead(int userId) async {
    try {
      await DioClient.instance.put(
        ApiEndpoints.notificationsMarkAllRead(userId),
      );
    } catch (e) {
      log('Failed to mark all as read: $e', name: 'NotificationApiService');
    }
  }

  static Future<void> markChatAsRead(int userId, int senderId) async {
    try {
      await DioClient.instance.put(
        ApiEndpoints.notificationsMarkChatRead(userId, senderId),
      );
    } catch (e) {
      log('Failed to mark chat notifications as read: $e', name: 'NotificationApiService');
    }
  }

  static Future<void> markAppointmentsAsRead(int userId) async {
    try {
      await DioClient.instance.put(
        ApiEndpoints.notificationsMarkAppointmentsRead(userId),
      );
    } catch (e) {
      log('Failed to mark appointment notifications as read: $e', name: 'NotificationApiService');
    }
  }

  /// Delete a single notification from the database.
  static Future<void> deleteNotification(int notificationId, int userId) async {
    try {
      await DioClient.instance.delete(
        ApiEndpoints.notificationDelete(notificationId, userId),
      );
    } catch (e) {
      log('Failed to delete notification: $e', name: 'NotificationApiService');
    }
  }

  /// Delete all CHAT notifications from a specific sender
  /// (called when opening a chat screen to auto-clear).
  static Future<void> deleteChatNotifications(int userId, int senderId) async {
    try {
      await DioClient.instance.delete(
        ApiEndpoints.notificationDeleteChatNotifications(userId, senderId),
      );
    } catch (e) {
      log('Failed to delete chat notifications: $e', name: 'NotificationApiService');
    }
  }

  /// Delete ALL notifications for a user.
  static Future<void> deleteAllNotifications(int userId) async {
    try {
      await DioClient.instance.delete(
        ApiEndpoints.notificationDeleteAll(userId),
      );
    } catch (e) {
      log('Failed to delete all notifications: $e', name: 'NotificationApiService');
    }
  }
}
